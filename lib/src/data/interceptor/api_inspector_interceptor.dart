import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/api_log_entity.dart';
import '../../domain/repositories/api_log_repository.dart';
import '../../notification/services/notification_service.dart';

class ApiInspectorInterceptor extends Interceptor {
  final ApiLogRepository repository;
  final int maxStoredLogs;
  final Duration requestTimeout;
  final NotificationService? notificationService;
  final _uuid = const Uuid();
  final Map<String, _PendingRequest> _pending = {};

  ApiInspectorInterceptor({
    required this.repository,
    this.maxStoredLogs = AppConstants.maxStoredLogs,
    this.requestTimeout = AppConstants.requestTimeout,
    this.notificationService,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final id = _uuid.v4();
    options.extra['_inspector_id'] = id;
    options.extra['_inspector_start'] = DateTime.now().millisecondsSinceEpoch;

    _pending[id] = _PendingRequest(
      id: id,
      url: options.uri.toString(),
      method: _parseMethod(options.method),
      requestHeaders: Map<String, dynamic>.from(options.headers),
      queryParams: Map<String, dynamic>.from(options.queryParameters),
      requestBody: _encodeBody(options.data),
      formData: options.data is FormData
          ? _parseFormData(options.data as FormData)
          : null,
      isMultipart: options.data is FormData,
      timestamp: DateTime.now(),
    );

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final id = response.requestOptions.extra['_inspector_id'] as String?;
    final startMs = response.requestOptions.extra['_inspector_start'] as int?;
    if (id == null) {
      handler.next(response);
      return;
    }

    final pending = _pending.remove(id);
    if (pending == null) {
      handler.next(response);
      return;
    }

    final durationMs = startMs != null
        ? DateTime.now().millisecondsSinceEpoch - startMs
        : null;

    final responseBody = _encodeBody(response.data);
    final responseHeaders = <String, dynamic>{};
    response.headers.forEach((key, values) {
      responseHeaders[key] = values.join(', ');
    });

    final statusCode = response.statusCode ?? 0;
    final log = ApiLogEntity(
      id: id,
      url: pending.url,
      method: pending.method,
      requestHeaders: pending.requestHeaders,
      queryParams: pending.queryParams,
      requestBody: pending.requestBody,
      formData: pending.formData,
      isMultipart: pending.isMultipart,
      timestamp: pending.timestamp,
      durationMs: durationMs,
      statusCode: statusCode,
      responseBody: responseBody,
      responseHeaders: responseHeaders,
      requestSizeBytes: pending.requestBody?.length,
      responseSizeBytes: responseBody?.length,
      status: statusCode >= 200 && statusCode < 400
          ? LogStatus.success
          : LogStatus.error,
    );

    _saveWithLimit(log);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final id = err.requestOptions.extra['_inspector_id'] as String?;
    final startMs = err.requestOptions.extra['_inspector_start'] as int?;
    if (id == null) {
      handler.next(err);
      return;
    }

    final pending = _pending.remove(id);
    if (pending == null) {
      handler.next(err);
      return;
    }

    final durationMs = startMs != null
        ? DateTime.now().millisecondsSinceEpoch - startMs
        : null;

    String? responseBody;
    Map<String, dynamic> responseHeaders = {};
    if (err.response != null) {
      responseBody = _encodeBody(err.response!.data);
      err.response!.headers.forEach((key, values) {
        responseHeaders[key] = values.join(', ');
      });
    }

    final log = ApiLogEntity(
      id: id,
      url: pending.url,
      method: pending.method,
      requestHeaders: pending.requestHeaders,
      queryParams: pending.queryParams,
      requestBody: pending.requestBody,
      formData: pending.formData,
      isMultipart: pending.isMultipart,
      timestamp: pending.timestamp,
      durationMs: durationMs,
      statusCode: err.response?.statusCode,
      responseBody: responseBody,
      responseHeaders: responseHeaders,
      requestSizeBytes: pending.requestBody?.length,
      responseSizeBytes: responseBody?.length,
      errorMessage: err.message,
      stackTrace: err.stackTrace.toString(),
      status: LogStatus.error,
    );

    await _saveWithLimit(log);

    // Trigger notification for failed API
    await _triggerNotification(log);

    handler.next(err);
  }

  /// Triggers notification for failed API if notification service is configured.
  Future<void> _triggerNotification(ApiLogEntity log) async {
    if (notificationService == null) return;
    if (!notificationService!.hasProviders) return;

    // Fire and forget - notification should not block the error flow
    unawaited(notificationService!.notifyApiFailed(log));
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

  static const Map<String, HttpMethod> _methodMap = {
    'GET': HttpMethod.get,
    'POST': HttpMethod.post,
    'PUT': HttpMethod.put,
    'PATCH': HttpMethod.patch,
    'DELETE': HttpMethod.delete,
    'HEAD': HttpMethod.head,
    'OPTIONS': HttpMethod.options,
  };

  HttpMethod _parseMethod(String method) =>
      _methodMap[method.toUpperCase()] ?? HttpMethod.get;

  String? _encodeBody(dynamic data) {
    if (data == null) return null;
    if (data is String) return data;
    if (data is FormData) return '[FormData]';
    try {
      return jsonEncode(data);
    } catch (_) {
      return data.toString();
    }
  }

  Map<String, dynamic>? _parseFormData(FormData formData) {
    final result = <String, dynamic>{};
    for (final field in formData.fields) {
      result[field.key] = field.value;
    }
    for (final file in formData.files) {
      result[file.key] = '[File: ${file.value.filename ?? 'unknown'}]';
    }
    return result;
  }
}

class _PendingRequest {
  final String id;
  final String url;
  final HttpMethod method;
  final Map<String, dynamic> requestHeaders;
  final Map<String, dynamic> queryParams;
  final String? requestBody;
  final Map<String, dynamic>? formData;
  final bool isMultipart;
  final DateTime timestamp;

  const _PendingRequest({
    required this.id,
    required this.url,
    required this.method,
    required this.requestHeaders,
    required this.queryParams,
    this.requestBody,
    this.formData,
    required this.isMultipart,
    required this.timestamp,
  });
}
