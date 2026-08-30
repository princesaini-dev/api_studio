import 'dart:convert';

import '../../domain/entities/api_log_entity.dart';
import '../../domain/repositories/api_log_repository.dart';
import '../../notification/services/notification_service.dart';
import '../exceptions/api_exceptions.dart';
import '../models/api_response.dart';
import '../request/api_request_options.dart';

/// Bridges [ApiStudioClient] calls into the existing [ApiLogRepository] so
/// all requests appear in the API Inspector, cURL generator, export, etc.
///
/// This is an internal service and should NOT be part of the public API.
class InspectorLogger {
  final ApiLogRepository repository;
  final int maxStoredLogs;
  final NotificationService? notificationService;

  static const int _maxRetainedBodyCharacters = 64 * 1024;

  const InspectorLogger({
    required this.repository,
    required this.maxStoredLogs,
    this.notificationService,
  });

  /// Log a completed successful / error response.
  Future<void> logResponse({
    required String id,
    required ApiRequestOptions options,
    required ApiResponse<dynamic> response,
    required DateTime startTime,
  }) async {
    final durationMs = DateTime.now().millisecondsSinceEpoch -
        startTime.millisecondsSinceEpoch;
    final statusCode = response.statusCode;
    final requestBody = _encodeBody(options.data);
    final responseBody = _encodeBody(response.data);

    final log = ApiLogEntity(
      id: id,
      url: options.uri.toString(),
      method: _toHttpMethod(options.method.value),
      requestHeaders: Map<String, dynamic>.from(options.headers),
      queryParams: Map<String, dynamic>.from(options.queryParameters),
      requestBody: _truncateBody(requestBody),
      isMultipart: false,
      timestamp: startTime,
      durationMs: durationMs,
      statusCode: statusCode,
      responseBody: _truncateBody(responseBody),
      responseHeaders: Map<String, dynamic>.from(response.headers),
      requestSizeBytes:
          requestBody == null ? null : utf8.encode(requestBody).length,
      responseSizeBytes:
          responseBody == null ? null : utf8.encode(responseBody).length,
      status: statusCode >= 200 && statusCode < 400
          ? LogStatus.success
          : LogStatus.error,
    );

    await _saveWithLimit(log);
    if (log.status == LogStatus.error) {
      await _triggerNotification(log);
    }
  }

  /// Log a failed request (exception).
  Future<void> logError({
    required String id,
    required ApiRequestOptions options,
    required ApiStudioException error,
    required DateTime startTime,
  }) async {
    final durationMs = DateTime.now().millisecondsSinceEpoch -
        startTime.millisecondsSinceEpoch;
    final requestBody = _encodeBody(options.data);
    final responseBody =
        error.response == null ? null : _encodeBody(error.response);

    final log = ApiLogEntity(
      id: id,
      url: options.uri.toString(),
      method: _toHttpMethod(options.method.value),
      requestHeaders: Map<String, dynamic>.from(options.headers),
      queryParams: Map<String, dynamic>.from(options.queryParameters),
      requestBody: _truncateBody(requestBody),
      isMultipart: false,
      timestamp: startTime,
      durationMs: durationMs,
      statusCode: error.statusCode,
      responseBody: _truncateBody(responseBody),
      responseHeaders: Map<String, dynamic>.from(error.responseHeaders),
      requestSizeBytes:
          requestBody == null ? null : utf8.encode(requestBody).length,
      errorMessage: error.message,
      stackTrace: StackTrace.current.toString(),
      status: LogStatus.error,
    );

    await _saveWithLimit(log);
    await _triggerNotification(log);
  }

  Future<void> _saveWithLimit(ApiLogEntity log) async {
    await repository.saveLog(log);
    final total = await repository.getTotalCount();
    if (total > maxStoredLogs) {
      final oldest = await repository.getLogs(
        GetLogsParams(
          pageSize: total - maxStoredLogs,
          sortOrder: SortOrder.oldest,
        ),
      );
      for (final old in oldest) {
        await repository.deleteLog(old.id);
      }
    }
  }

  Future<void> _triggerNotification(ApiLogEntity log) async {
    if (notificationService == null) return;
    if (!notificationService!.hasProviders) return;
    unawaited(notificationService!.notifyApiFailed(log));
  }

  static const Map<String, HttpMethod> _methodMap = {
    'GET': HttpMethod.get,
    'POST': HttpMethod.post,
    'PUT': HttpMethod.put,
    'PATCH': HttpMethod.patch,
    'DELETE': HttpMethod.delete,
    'HEAD': HttpMethod.head,
    'OPTIONS': HttpMethod.options,
  };

  HttpMethod _toHttpMethod(String method) =>
      _methodMap[method.toUpperCase()] ?? HttpMethod.get;

  String? _encodeBody(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is List<int>) return '[bytes: ${data.length}]';
    try {
      return jsonEncode(data);
    } catch (_) {
      return data.toString();
    }
  }

  String? _truncateBody(String? body) {
    if (body == null || body.length <= _maxRetainedBodyCharacters) return body;
    return '${body.substring(0, _maxRetainedBodyCharacters)}…';
  }
}

// Silence lint: unawaited_futures
void unawaited(Future<void> future) {}
