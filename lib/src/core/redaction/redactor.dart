import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../domain/entities/api_log_entity.dart';
import 'redaction_config.dart';

/// Applies a [RedactionConfig] to captured API logs.
///
/// Internal — use [RedactionConfig] to configure behaviour.
class Redactor {
  final RedactionConfig config;
  final Set<String> _headers;
  final Set<String> _bodyKeys;

  Redactor(this.config)
      : _headers = config.effectiveHeaders,
        _bodyKeys = config.effectiveBodyKeys;

  static const String _placeholder = RedactionConfig.placeholder;

  /// Returns a copy of [log] with every sensitive value masked.
  ///
  /// Never throws: if the custom [RedactionConfig.redactor] fails, the
  /// built-in redaction result is returned.
  ApiLogEntity redact(ApiLogEntity log) {
    final builtIn = log.copyWith(
      url: redactUrl(log.url),
      requestHeaders: redactHeaders(log.requestHeaders),
      responseHeaders: redactHeaders(log.responseHeaders),
      queryParams: _redactMap(log.queryParams),
      formData: log.formData == null ? null : _redactMap(log.formData!),
      requestBody: redactBody(log.requestBody),
      responseBody: redactBody(log.responseBody),
    );
    final hook = config.redactor;
    if (hook == null) return builtIn;
    try {
      return hook(builtIn);
    } catch (e) {
      debugPrint('[ApiStudio] Custom redactor threw ($e); '
          'falling back to built-in redaction.');
      return builtIn;
    }
  }

  bool isSensitiveHeader(String name) => _headers.contains(name.toLowerCase());

  bool isSensitiveKey(String key) =>
      _bodyKeys.contains(RedactionConfig.normalizeKey(key));

  Map<String, dynamic> redactHeaders(Map<String, dynamic> headers) {
    if (headers.isEmpty) return headers;
    return {
      for (final e in headers.entries)
        e.key: isSensitiveHeader(e.key) ? _placeholder : e.value,
    };
  }

  /// Redacts sensitive query parameters embedded in [url], preserving the
  /// original encoding of every other part.
  String redactUrl(String url) {
    final qIndex = url.indexOf('?');
    if (qIndex < 0) return url;
    final hashIndex = url.indexOf('#', qIndex);
    final query = url.substring(qIndex + 1, hashIndex < 0 ? null : hashIndex);
    final redacted = _redactFormEncoded(query);
    if (redacted == null) return url;
    return '${url.substring(0, qIndex + 1)}$redacted'
        '${hashIndex < 0 ? '' : url.substring(hashIndex)}';
  }

  /// Redacts a request/response body string. Supports JSON (recursively),
  /// `application/x-www-form-urlencoded`, and falls back to a pattern-based
  /// scrub for JSON-like text that cannot be parsed (e.g. truncated bodies).
  String? redactBody(String? body) {
    if (body == null || body.isEmpty || _bodyKeys.isEmpty) return body;
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        final decoded = jsonDecode(body);
        final result = _redactValue(decoded);
        return result.changed ? jsonEncode(result.value) : body;
      } catch (_) {
        return _scrubJsonLike(body);
      }
    }
    if (!body.contains(' ') && body.contains('=')) {
      return _redactFormEncoded(body) ?? body;
    }
    return body;
  }

  Map<String, dynamic> _redactMap(Map<String, dynamic> map) {
    final result = _redactValue(map);
    return result.changed
        ? Map<String, dynamic>.from(result.value as Map)
        : map;
  }

  ({Object? value, bool changed}) _redactValue(Object? value) {
    if (value is Map) {
      var changed = false;
      final out = <String, dynamic>{};
      value.forEach((k, v) {
        final key = k.toString();
        if (isSensitiveKey(key)) {
          out[key] = _placeholder;
          changed = true;
        } else {
          final r = _redactValue(v);
          out[key] = r.value;
          changed |= r.changed;
        }
      });
      return (value: changed ? out : value, changed: changed);
    }
    if (value is List) {
      var changed = false;
      final out = value.map((e) {
        final r = _redactValue(e);
        changed |= r.changed;
        return r.value;
      }).toList();
      return (value: changed ? out : value, changed: changed);
    }
    return (value: value, changed: false);
  }

  /// Returns the redacted form-encoded string, or `null` if nothing changed.
  String? _redactFormEncoded(String encoded) {
    if (encoded.isEmpty) return null;
    var changed = false;
    final parts = encoded.split('&').map((part) {
      final eq = part.indexOf('=');
      final rawKey = eq < 0 ? part : part.substring(0, eq);
      String key;
      try {
        key = Uri.decodeQueryComponent(rawKey);
      } catch (_) {
        key = rawKey;
      }
      if (!isSensitiveKey(key)) return part;
      changed = true;
      return '$rawKey=$_placeholder';
    }).toList();
    return changed ? parts.join('&') : null;
  }

  String _scrubJsonLike(String body) {
    final pattern = RegExp(
      r'"([^"\\]+)"\s*:\s*("(?:[^"\\]|\\.)*"?|[^,}\]\s]+)',
    );
    return body.replaceAllMapped(pattern, (m) {
      final key = m.group(1)!;
      if (!isSensitiveKey(key)) return m.group(0)!;
      return '"$key":"$_placeholder"';
    });
  }
}
