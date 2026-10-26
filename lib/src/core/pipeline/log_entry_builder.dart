import 'dart:convert';

import '../../domain/entities/api_log_entity.dart';
import '../utils/uuid_generator.dart';

/// Converts raw request/response data from any HTTP client into an
/// [ApiLogEntity]. Internal.
class LogEntryBuilder {
  LogEntryBuilder._();

  static const Map<String, HttpMethod> _methodMap = {
    'GET': HttpMethod.get,
    'POST': HttpMethod.post,
    'PUT': HttpMethod.put,
    'PATCH': HttpMethod.patch,
    'DELETE': HttpMethod.delete,
    'HEAD': HttpMethod.head,
    'OPTIONS': HttpMethod.options,
  };

  static HttpMethod parseMethod(String method) =>
      _methodMap[method.toUpperCase().trim()] ?? HttpMethod.get;

  static LogStatus statusFor({
    int? statusCode,
    String? errorMessage,
    bool cancelled = false,
  }) {
    if (cancelled) return LogStatus.cancelled;
    if (statusCode != null && statusCode >= 200 && statusCode < 400) {
      return LogStatus.success;
    }
    if (statusCode != null && statusCode > 0) return LogStatus.error;
    return errorMessage != null ? LogStatus.error : LogStatus.success;
  }

  /// Encodes an arbitrary body into a string suitable for storage.
  ///
  /// Binary payloads are replaced with a short placeholder so raw bytes are
  /// never persisted.
  static String? encodeBody(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is List<int>) return '[binary data: ${data.length} bytes]';
    try {
      return jsonEncode(data);
    } catch (_) {
      return data.toString();
    }
  }

  static int? sizeOf(dynamic data, String? encoded) {
    if (data is List<int>) return data.length;
    return encoded == null ? null : utf8.encode(encoded).length;
  }

  /// Normalizes a header / query / form map so it only contains values that
  /// can be persisted safely (strings, numbers, booleans and string lists).
  static Map<String, dynamic> normalizeMap(Map<dynamic, dynamic>? map) {
    if (map == null || map.isEmpty) return <String, dynamic>{};
    return {
      for (final e in map.entries) e.key.toString(): _normalizeValue(e.value),
    };
  }

  static dynamic _normalizeValue(dynamic v) {
    if (v == null || v is String || v is num || v is bool) return v;
    if (v is Iterable) return v.map((e) => e?.toString() ?? '').toList();
    return v.toString();
  }

  static ApiLogEntity build({
    required String url,
    required String method,
    int? statusCode,
    int? durationMs,
    Map<dynamic, dynamic>? requestHeaders,
    Map<dynamic, dynamic>? queryParameters,
    dynamic requestBody,
    Map<dynamic, dynamic>? responseHeaders,
    dynamic responseBody,
    Map<dynamic, dynamic>? formData,
    bool isMultipart = false,
    bool cancelled = false,
    String? errorMessage,
    Object? stackTrace,
    DateTime? timestamp,
    int? requestSizeBytes,
    int? responseSizeBytes,
    String? id,
  }) {
    final reqBody = encodeBody(requestBody);
    final resBody = encodeBody(responseBody);
    return ApiLogEntity(
      id: id ?? const UuidGenerator().v4(),
      url: url,
      method: parseMethod(method),
      requestHeaders: normalizeMap(requestHeaders),
      queryParams: normalizeMap(queryParameters),
      requestBody: reqBody,
      formData: formData == null ? null : normalizeMap(formData),
      isMultipart: isMultipart || (formData != null && formData.isNotEmpty),
      timestamp: timestamp ?? DateTime.now(),
      durationMs: durationMs,
      statusCode: statusCode,
      responseBody: resBody,
      responseHeaders: normalizeMap(responseHeaders),
      requestSizeBytes: requestSizeBytes ?? sizeOf(requestBody, reqBody),
      responseSizeBytes: responseSizeBytes ?? sizeOf(responseBody, resBody),
      errorMessage: errorMessage,
      stackTrace: stackTrace?.toString(),
      status: statusFor(
        statusCode: statusCode,
        errorMessage: errorMessage,
        cancelled: cancelled,
      ),
    );
  }
}
