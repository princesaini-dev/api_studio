import 'dart:async';

import '../../core/pipeline/log_entry_builder.dart';
import '../../core/pipeline/log_pipeline.dart';
import '../../domain/entities/api_log_entity.dart';
import '../../domain/repositories/api_log_repository.dart';
import '../../notification/services/notification_service.dart';
import '../exceptions/api_exceptions.dart';
import '../models/api_response.dart';
import '../request/api_request_options.dart';

/// Bridges [ApiStudioClient] calls into the shared logging pipeline so all
/// requests appear in the API Inspector, cURL generator, export, etc.
///
/// This is an internal service and should NOT be part of the public API.
class InspectorLogger {
  final ApiLogRepository repository;
  final int maxStoredLogs;
  final NotificationService? notificationService;

  const InspectorLogger({
    required this.repository,
    required this.maxStoredLogs,
    this.notificationService,
  });

  /// Log a completed successful / error response (local storage only).
  Future<void> logResponse({
    required String id,
    required ApiRequestOptions options,
    required ApiResponse<dynamic> response,
    required DateTime startTime,
  }) async {
    await LogPipeline.record(
      buildResponseEntity(
        id: id,
        options: options,
        response: response,
        startTime: startTime,
      ),
      upload: false,
      repository: repository,
      notificationService: notificationService,
    );
  }

  /// Log a failed request (local storage only).
  Future<void> logError({
    required String id,
    required ApiRequestOptions options,
    required ApiStudioException error,
    required DateTime startTime,
  }) async {
    await LogPipeline.record(
      buildErrorEntity(
        id: id,
        options: options,
        error: error,
        startTime: startTime,
      ),
      upload: false,
      repository: repository,
      notificationService: notificationService,
    );
  }

  static ApiLogEntity buildResponseEntity({
    required String id,
    required ApiRequestOptions options,
    required ApiResponse<dynamic> response,
    required DateTime startTime,
  }) {
    return LogEntryBuilder.build(
      id: id,
      url: options.uri.toString(),
      method: options.method.value,
      requestHeaders: options.headers,
      queryParameters: options.queryParameters,
      requestBody: options.data,
      timestamp: startTime,
      durationMs: DateTime.now().difference(startTime).inMilliseconds,
      statusCode: response.statusCode,
      responseBody: response.data,
      responseHeaders: response.headers,
    );
  }

  static ApiLogEntity buildErrorEntity({
    required String id,
    required ApiRequestOptions options,
    required ApiStudioException error,
    required DateTime startTime,
  }) {
    return LogEntryBuilder.build(
      id: id,
      url: options.uri.toString(),
      method: options.method.value,
      requestHeaders: options.headers,
      queryParameters: options.queryParameters,
      requestBody: options.data,
      timestamp: startTime,
      durationMs: DateTime.now().difference(startTime).inMilliseconds,
      statusCode: error.statusCode,
      responseBody: error.response,
      responseHeaders: error.responseHeaders,
      errorMessage: error.message,
      cancelled: error is CancelledException,
      stackTrace: StackTrace.current,
    );
  }
}
