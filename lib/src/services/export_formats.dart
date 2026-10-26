import 'dart:convert';

import '../core/constants/app_constants.dart';
import '../core/runtime/api_studio_runtime.dart';
import '../core/utils/url_utils.dart';
import '../domain/entities/api_log_entity.dart';

/// Pure converters from captured logs to export formats. Every converter
/// re-applies the active redaction rules, so exports never contain secrets
/// even for logs stored by older versions. Internal.
class ExportFormats {
  ExportFormats._();

  static List<ApiLogEntity> _redact(List<ApiLogEntity> logs) =>
      logs.map(ApiStudioRuntime.redactor.redact).toList();

  /// API Studio's native JSON export.
  static String toJson(List<ApiLogEntity> logs) {
    final list = _redact(logs).map((log) => {
          'id': log.id,
          'url': log.url,
          'method': log.methodLabel,
          'timestamp': log.timestamp.toIso8601String(),
          'durationMs': log.durationMs,
          'statusCode': log.statusCode,
          'status': log.status.name,
          'requestHeaders': log.requestHeaders,
          'queryParams': log.queryParams,
          'requestBody': log.requestBody,
          if (log.formData != null) 'formData': log.formData,
          'responseHeaders': log.responseHeaders,
          'responseBody': log.responseBody,
          'errorMessage': log.errorMessage,
          'isEdited': log.isEdited,
          'parentId': log.parentId,
          'isTruncated': log.isTruncated,
        });
    return const JsonEncoder.withIndent('  ').convert(list.toList());
  }

  /// Human-readable plain-text export.
  static String toTxt(List<ApiLogEntity> logs, {DateTime? generatedAt}) {
    final safe = _redact(logs);
    final buffer = StringBuffer()
      ..writeln('API Studio — Export')
      ..writeln('Generated: ${generatedAt ?? DateTime.now()}')
      ..writeln('Total: ${safe.length} requests\n')
      ..writeln('=' * 60);
    for (final log in safe) {
      buffer
        ..writeln('\n[${log.timestamp}] ${log.methodLabel} ${log.url}')
        ..writeln('Status: ${log.statusCode ?? 'N/A'} | '
            'Duration: ${log.durationMs ?? '?'}ms');
      if (log.requestBody != null) buffer.writeln('Body: ${log.requestBody}');
      if (log.errorMessage != null) {
        buffer.writeln('Error: ${log.errorMessage}');
      }
      buffer.writeln('-' * 60);
    }
    return buffer.toString();
  }

  /// HTTP Archive (HAR 1.2) — importable into Chrome DevTools, Charles,
  /// Proxyman, Insomnia, etc.
  static String toHar(List<ApiLogEntity> logs) {
    final entries = _redact(logs).map((log) {
      final duration = (log.durationMs ?? 0).clamp(0, 1 << 31);
      final uri = UrlUtils.mergeQuery(log.url, log.queryParams);
      final reqType = _mimeType(log.requestHeaders, log.requestBody);
      final resType = _mimeType(log.responseHeaders, log.responseBody);
      return {
        'startedDateTime': log.timestamp.toUtc().toIso8601String(),
        'time': duration,
        'request': {
          'method': log.methodLabel,
          'url': uri?.toString() ?? log.url,
          'httpVersion': 'HTTP/1.1',
          'cookies': const <Object>[],
          'headers': _nameValues(log.requestHeaders),
          'queryString': [
            for (final e in (uri?.queryParametersAll ?? const {}).entries)
              for (final v in e.value) {'name': e.key, 'value': v},
          ],
          if (log.formData != null && log.formData!.isNotEmpty)
            'postData': {
              'mimeType': 'multipart/form-data',
              'params': _nameValues(log.formData!),
            }
          else if (log.requestBody != null)
            'postData': {'mimeType': reqType, 'text': log.requestBody},
          'headersSize': -1,
          'bodySize': log.requestSizeBytes ?? -1,
        },
        'response': {
          'status': log.statusCode ?? 0,
          'statusText': log.errorMessage ?? '',
          'httpVersion': 'HTTP/1.1',
          'cookies': const <Object>[],
          'headers': _nameValues(log.responseHeaders),
          'content': {
            'size': log.responseSizeBytes ?? 0,
            'mimeType': resType,
            if (log.responseBody != null) 'text': log.responseBody,
          },
          'redirectURL': '',
          'headersSize': -1,
          'bodySize': log.responseSizeBytes ?? -1,
        },
        'cache': const <String, Object>{},
        'timings': {'send': 0, 'wait': duration, 'receive': 0},
        if (log.errorMessage != null) 'comment': log.errorMessage,
      };
    }).toList();

    return const JsonEncoder.withIndent('  ').convert({
      'log': {
        'version': '1.2',
        'creator': {
          'name': 'API Studio',
          'version': AppConstants.packageVersion,
        },
        'entries': entries,
      },
    });
  }

  /// Postman Collection v2.1 — one request per captured log.
  static String toPostman(List<ApiLogEntity> logs, {DateTime? generatedAt}) {
    final items = _redact(logs).map((log) {
      final uri = UrlUtils.mergeQuery(log.url, log.queryParams);
      final headers = [
        for (final e in log.requestHeaders.entries)
          {'key': e.key, 'value': UrlUtils.headerValue(e.value)},
      ];
      Map<String, Object?>? body;
      if (log.formData != null && log.formData!.isNotEmpty) {
        body = {
          'mode': 'formdata',
          'formdata': [
            for (final e in log.formData!.entries)
              {
                'key': e.key,
                'value': UrlUtils.headerValue(e.value),
                'type': 'text'
              },
          ],
        };
      } else if (log.requestBody != null && log.requestBody!.isNotEmpty) {
        final isJson =
            _mimeType(log.requestHeaders, log.requestBody).contains('json');
        body = {
          'mode': 'raw',
          'raw': log.requestBody,
          if (isJson)
            'options': {
              'raw': {'language': 'json'},
            },
        };
      }
      return {
        'name':
            '${log.methodLabel} ${uri?.path.isNotEmpty == true ? uri!.path : log.url}',
        'request': {
          'method': log.methodLabel,
          'header': headers,
          'url': uri == null
              ? log.url
              : {
                  'raw': uri.toString(),
                  'protocol': uri.scheme,
                  'host': uri.host.split('.'),
                  if (uri.hasPort) 'port': '${uri.port}',
                  'path': uri.pathSegments,
                  if (uri.query.isNotEmpty)
                    'query': [
                      for (final e in uri.queryParametersAll.entries)
                        for (final v in e.value) {'key': e.key, 'value': v},
                    ],
                },
          if (body != null) 'body': body,
        },
        'response': const <Object>[],
      };
    }).toList();

    return const JsonEncoder.withIndent('  ').convert({
      'info': {
        'name':
            'API Studio export ${(generatedAt ?? DateTime.now()).toIso8601String()}',
        'schema':
            'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',
      },
      'item': items,
    });
  }

  static List<Map<String, String>> _nameValues(Map<String, dynamic> map) => [
        for (final e in map.entries)
          {'name': e.key, 'value': UrlUtils.headerValue(e.value)},
      ];

  static String _mimeType(Map<String, dynamic> headers, String? body) {
    for (final e in headers.entries) {
      if (e.key.toLowerCase() == 'content-type') {
        return UrlUtils.headerValue(e.value);
      }
    }
    if (body == null) return 'text/plain';
    final t = body.trimLeft();
    return t.startsWith('{') || t.startsWith('[')
        ? 'application/json'
        : 'text/plain';
  }
}
