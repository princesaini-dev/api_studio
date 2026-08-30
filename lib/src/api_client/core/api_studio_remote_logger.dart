import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'simple_http_client.dart';

import '../../core/constants/app_constants.dart';
import '../exceptions/api_exceptions.dart';
import '../models/api_response.dart';
import '../request/api_request_options.dart';

/// Sends fire-and-forget API execution logs to the dedicated API Studio
/// backend.
///
/// This is completely isolated from [ApiStudioClient]'s own configuration:
/// it never reuses the user's base URL, headers, authentication, cookies,
/// interceptors or retry logic. It builds its own [HttpClient] request with
/// its own headers, authenticated using the API Studio API key only.
///
/// All failures are swallowed silently — logging must never affect, delay or
/// throw for the user's request.
class ApiStudioRemoteLogger {
  ApiStudioRemoteLogger._();

  static String? _apiKey;
  static SimpleHttpClient? _client;
  static Timer? _uploadTimer;
  static final List<String> _pendingPayloads = [];
  static bool _isUploading = false;

  static const Duration _timeout = Duration(seconds: 10);
  static const Duration uploadInterval = Duration(minutes: 5);
  static const int _maxPendingPayloads = 100;
  static const int _maxBodyCharacters = 64 * 1024;

  static const List<String> _sensitiveHeaders = [
    'authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'proxy-authorization',
  ];

  /// Configures (or disables) automatic remote logging.
  ///
  /// Passing `null` or an empty string completely disables logging with no
  /// side effects on the rest of the package.
  static void configure(String? apiKey) {
    _apiKey = (apiKey != null && apiKey.trim().isNotEmpty) ? apiKey : null;
    _uploadTimer?.cancel();
    _uploadTimer = null;
    if (!isEnabled) return;
    _uploadTimer = Timer.periodic(
      uploadInterval,
      (_) => unawaited(_uploadPending()),
    );
  }

  /// Whether an API key has been configured and logging is active.
  static bool get isEnabled => _apiKey != null;

  /// Fire-and-forget logging of a completed (successful or HTTP-error)
  /// response.
  static void logSuccess({
    required ApiRequestOptions options,
    required ApiResponse<dynamic> response,
    required DateTime startTime,
  }) {
    _dispatch(
      options: options,
      startTime: startTime,
      statusCode: response.statusCode,
      responseHeaders: response.headers,
      responseBody: response.data,
      error: null,
    );
  }

  /// Fire-and-forget logging of a failed request (exception / network error).
  static void logError({
    required ApiRequestOptions options,
    required ApiStudioException error,
    required DateTime startTime,
  }) {
    _dispatch(
      options: options,
      startTime: startTime,
      statusCode: error.statusCode,
      responseHeaders: error.responseHeaders,
      responseBody: error.response,
      error: error.message,
    );
  }

  static void _dispatch({
    required ApiRequestOptions options,
    required DateTime startTime,
    int? statusCode,
    Map<String, dynamic>? responseHeaders,
    dynamic responseBody,
    String? error,
  }) {
    if (!isEnabled) return;

    final String url;
    try {
      url = options.uri.toString();
    } catch (_) {
      return;
    }

    // Prevent infinite loop: never log requests made to the logging backend.
    if (_isApiStudioRequest(url)) return;

    // True fire-and-forget: never awaited, never throws.
    unawaited(
      _send(
        url: url,
        method: options.method.value,
        requestHeaders: options.headers,
        requestBody: options.data,
        statusCode: statusCode,
        responseHeaders: responseHeaders,
        responseBody: responseBody,
        error: error,
        startTime: startTime,
      ).catchError((_) {}),
    );
  }

  static bool _isApiStudioRequest(String url) {
    return url.startsWith(AppConstants.apiStudioBaseUrl) ||
        url.contains(AppConstants.apiStudioLogsPath);
  }

  static Future<void> _send({
    required String url,
    required String method,
    required Map<String, dynamic> requestHeaders,
    dynamic requestBody,
    int? statusCode,
    Map<String, dynamic>? responseHeaders,
    dynamic responseBody,
    String? error,
    required DateTime startTime,
  }) async {
    final apiKey = _apiKey;
    if (apiKey == null) return;

    try {
      final durationMs = DateTime.now().difference(startTime).inMilliseconds;

      final payload = jsonEncode({
        'method': method.toUpperCase(),
        'url': url,
        'status_code': statusCode,
        'duration_ms': durationMs,
        'request': {
          'headers': _sanitizeHeaders(requestHeaders),
          'body': _safeBody(requestBody),
        },
        'response': {
          'headers': _sanitizeHeaders(responseHeaders ?? const {}),
          'body': _safeBody(responseBody),
        },
        'error': error,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      _pendingPayloads.add(payload);
      if (_pendingPayloads.length > _maxPendingPayloads) {
        _pendingPayloads.removeAt(0);
      }
    } catch (_) {}
  }

  static Future<void> _uploadPending() async {
    if (!isEnabled || _isUploading || _pendingPayloads.isEmpty) return;
    final apiKey = _apiKey;
    if (apiKey == null) return;

    _isUploading = true;
    try {
      final client = _client ??= SimpleHttpClient();
      while (_pendingPayloads.isNotEmpty) {
        final response = await client.post(
          Uri.parse(AppConstants.apiStudioLogsUrl),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: _pendingPayloads.first,
          timeout: _timeout,
        );
        if (response.statusCode < 200 || response.statusCode >= 300) return;
        _pendingPayloads.removeAt(0);
        debugPrint('API Studio: API logs uploaded successfully.');
      }
    } catch (_) {
      return;
    } finally {
      _isUploading = false;
    }
  }

  static Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = <String, dynamic>{};
    headers.forEach((key, value) {
      if (_sensitiveHeaders.contains(key.toLowerCase())) return;
      sanitized[key] = value;
    });
    return sanitized;
  }

  static dynamic _safeBody(dynamic body) {
    if (body == null) return null;
    if (body is List<int>) return '[bytes: ${body.length}]';

    final String encoded;
    try {
      encoded = body is String ? body : jsonEncode(body);
    } catch (_) {
      return _truncate(body.toString());
    }
    if (encoded.length > _maxBodyCharacters) return _truncate(encoded);
    if (body is! String) return body;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  static String _truncate(String value) {
    if (value.length <= _maxBodyCharacters) return value;
    return '${value.substring(0, _maxBodyCharacters)}…';
  }
}

// Silence unawaited_futures lint for fire-and-forget logging.
void unawaited(Future<void> future) {}
