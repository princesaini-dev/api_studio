import 'dart:async';

import 'package:api_studio/api_studio.dart' show ApiStudio;
import 'package:dio/dio.dart';

/// Decides whether a request should be captured. Return `false` to skip it.
typedef ApiStudioDioFilter = bool Function(RequestOptions options);

/// A Dio [Interceptor] that captures every request into API Studio.
///
/// ```dart
/// dio.interceptors.add(ApiStudioDioInterceptor());
/// ```
///
/// For each request it records the URL, method, request headers, query
/// parameters, body (including multipart [FormData] fields and file
/// descriptors), status code, response headers, response body, duration,
/// and — on failure — the error and stack trace. Cancelled requests are
/// recorded with the `cancelled` status; timeouts are labelled as such.
///
/// Everything flows through the same pipeline as `ApiStudio.log`, so
/// redaction (`RedactionConfig`), body truncation (`maxBodyBytes`), local
/// storage and optional cloud upload all apply.
///
/// The interceptor is passive: it never modifies, delays or fails a
/// request, and it does nothing when API Studio is disabled (e.g. release
/// builds, see `ApiStudio.initialize(enabled: ...)`).
///
/// Add it **last** so the captured headers include those added by earlier
/// interceptors (e.g. auth). Captured headers are read from the final
/// request options either way.
class ApiStudioDioInterceptor extends Interceptor {
  /// Whether request bodies are captured. Defaults to `true`.
  final bool captureRequestBody;

  /// Whether response bodies are captured. Defaults to `true`.
  final bool captureResponseBody;

  /// Optional filter; return `false` to skip capturing a request.
  final ApiStudioDioFilter? filter;

  /// Creates the interceptor.
  ApiStudioDioInterceptor({
    this.captureRequestBody = true,
    this.captureResponseBody = true,
    this.filter,
  });

  static const String _stopwatchKey = '_api_studio_stopwatch';
  static const String _timestampKey = '_api_studio_timestamp';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      if (ApiStudio.isEnabled && (filter?.call(options) ?? true)) {
        options.extra[_stopwatchKey] = Stopwatch()..start();
        options.extra[_timestampKey] = DateTime.now();
      }
    } catch (_) {}
    handler.next(options);
  }

  @override
  void onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) {
    _capture(response.requestOptions, response: response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _capture(err.requestOptions, response: err.response, error: err);
    handler.next(err);
  }

  void _capture(
    RequestOptions options, {
    Response<dynamic>? response,
    DioException? error,
  }) {
    try {
      final stopwatch = options.extra.remove(_stopwatchKey);
      final timestamp = options.extra.remove(_timestampKey);
      if (stopwatch is! Stopwatch || !ApiStudio.isEnabled) return;
      stopwatch.stop();

      final data = options.data;
      final formData = data is FormData ? _describeFormData(data) : null;

      unawaited(ApiStudio.log(
        url: options.uri.toString(),
        method: options.method,
        statusCode: response?.statusCode,
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: timestamp is DateTime ? timestamp : null,
        requestHeaders: Map<String, dynamic>.from(options.headers),
        queryParameters: Map<String, dynamic>.from(options.queryParameters),
        requestBody: captureRequestBody && formData == null
            ? _describeRequestBody(data)
            : null,
        formData: captureRequestBody ? formData : null,
        isMultipart: data is FormData,
        responseHeaders: _flattenHeaders(response?.headers),
        responseBody:
            captureResponseBody ? _describeResponseBody(response?.data) : null,
        errorMessage: error == null ? null : _describeError(error),
        stackTrace: error?.stackTrace,
        cancelled: error?.type == DioExceptionType.cancel,
      ));
    } catch (_) {
      // Capturing must never affect the host app's request.
    }
  }

  static dynamic _describeRequestBody(dynamic data) {
    if (data == null) return null;
    if (data is Stream) return '[stream body]';
    return data;
  }

  static dynamic _describeResponseBody(dynamic data) {
    if (data is ResponseBody) return '[stream response]';
    return data;
  }

  static Map<String, dynamic> _describeFormData(FormData formData) {
    final out = <String, dynamic>{};
    void add(String key, String value) {
      final existing = out[key];
      if (existing == null) {
        out[key] = value;
      } else if (existing is List<String>) {
        existing.add(value);
      } else {
        out[key] = <String>[existing as String, value];
      }
    }

    for (final field in formData.fields) {
      add(field.key, field.value);
    }
    for (final file in formData.files) {
      final f = file.value;
      add(
        file.key,
        '[file: ${f.filename ?? 'unnamed'}, ${f.length} bytes'
        '${f.contentType == null ? '' : ', ${f.contentType}'}]',
      );
    }
    return out;
  }

  static Map<String, dynamic> _flattenHeaders(Headers? headers) {
    if (headers == null) return const {};
    return {
      for (final e in headers.map.entries)
        e.key: e.value.length == 1 ? e.value.first : e.value,
    };
  }

  static String _describeError(DioException e) {
    final detail = e.message ?? e.error?.toString() ?? '';
    switch (e.type) {
      case DioExceptionType.cancel:
        return 'Request cancelled${detail.isEmpty ? '' : ': $detail'}';
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Timeout (${e.type.name})${detail.isEmpty ? '' : ': $detail'}';
      case DioExceptionType.badResponse:
        return 'HTTP ${e.response?.statusCode ?? 'error'}';
      default:
        return detail.isEmpty ? e.type.name : detail;
    }
  }
}
