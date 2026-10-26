import 'dart:convert';

import '../../api_client/adapters/http_adapter.dart';
import '../../api_client/cache/cache_store.dart';
import '../../api_client/cookie/cookie_jar.dart';
import '../../api_client/core/client_config.dart';
import '../../api_client/enums/http_method_enum.dart';
import '../../api_client/exceptions/api_exceptions.dart';
import '../../api_client/request/api_request_options.dart';
import '../../core/constants/app_constants.dart';
import '../../core/pipeline/log_pipeline.dart';
import '../../core/usecases/usecase.dart';
import '../../core/utils/url_utils.dart';
import '../entities/api_log_entity.dart';
import '../repositories/api_log_repository.dart';

class RunRequestParams {
  final ApiLogEntity originalLog;
  final String url;
  final HttpMethod method;
  final Map<String, dynamic> headers;
  final Map<String, dynamic> queryParams;
  final String? body;
  final String newId;

  const RunRequestParams({
    required this.originalLog,
    required this.url,
    required this.method,
    required this.headers,
    required this.queryParams,
    this.body,
    required this.newId,
  });
}

class RunRequestUseCase implements UseCase<ApiLogEntity, RunRequestParams> {
  final ApiLogRepository repository;

  const RunRequestUseCase(this.repository);

  /// Transport-level headers that must not be replayed verbatim: they are
  /// recomputed by the HTTP stack and become wrong once the body is edited.
  static const Set<String> _hopByHopHeaders = {
    'content-length',
    'host',
    'transfer-encoding',
    'connection',
  };

  /// Headers to send when replaying a captured request: drops transport
  /// headers and flattens multi-value headers (e.g. captured from Dio).
  static Map<String, dynamic> replayHeaders(Map<String, dynamic> headers) => {
        for (final e in headers.entries)
          if (!_hopByHopHeaders.contains(e.key.toLowerCase()))
            e.key: UrlUtils.headerValue(e.value),
      };

  static ApiHttpMethod _toApiHttpMethod(HttpMethod method) {
    switch (method) {
      case HttpMethod.get:
        return ApiHttpMethod.get;
      case HttpMethod.post:
        return ApiHttpMethod.post;
      case HttpMethod.put:
        return ApiHttpMethod.put;
      case HttpMethod.patch:
        return ApiHttpMethod.patch;
      case HttpMethod.delete:
        return ApiHttpMethod.delete;
      case HttpMethod.head:
        return ApiHttpMethod.head;
      case HttpMethod.options:
        return ApiHttpMethod.options;
    }
  }

  @override
  Future<ApiLogEntity> call(RunRequestParams params) async {
    final stopwatch = Stopwatch()..start();
    int? statusCode;
    String? responseBody;
    Map<String, dynamic> responseHeaders = {};
    String? errorMessage;
    LogStatus status = LogStatus.loading;

    try {
      // Build the final URI (repeated query keys preserved) and send it as
      // an absolute path so the adapter does not re-encode the query.
      final uri = UrlUtils.mergeQuery(params.url, params.queryParams) ??
          (throw FormatException('Invalid URL: ${params.url}'));

      final schemeAndHost = uri.hasScheme && uri.host.isNotEmpty
          ? '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}'
          : '';

      final adapter = HttpAdapter(
        config: ClientConfig(
          baseUrl: schemeAndHost,
          connectTimeout: AppConstants.requestTimeout,
          receiveTimeout: AppConstants.requestTimeout,
          sendTimeout: AppConstants.requestTimeout,
        ),
        cacheStore: MemoryCacheStore(),
        cookieJar: ApiCookieJar(),
      );

      final options = ApiRequestOptions(
        method: _toApiHttpMethod(params.method),
        baseUrl: schemeAndHost,
        path: uri.toString(),
        headers: replayHeaders(params.headers),
        data: params.body,
        connectTimeout: AppConstants.requestTimeout,
        receiveTimeout: AppConstants.requestTimeout,
        sendTimeout: AppConstants.requestTimeout,
        requestId: params.newId,
      );

      final response = await adapter.send<dynamic>(options);
      statusCode = response.statusCode;
      responseHeaders = Map<String, dynamic>.from(response.headers);
      if (response.data != null) {
        if (response.data is String) {
          responseBody = response.data as String;
        } else {
          try {
            responseBody = jsonEncode(response.data);
          } catch (_) {
            responseBody = response.data.toString();
          }
        }
      }
      status = (statusCode >= 200 && statusCode < 400)
          ? LogStatus.success
          : LogStatus.error;
    } on ApiStudioException catch (e) {
      statusCode = e.statusCode;
      errorMessage = e.message;
      if (e.responseHeaders.isNotEmpty) {
        responseHeaders = Map<String, dynamic>.from(e.responseHeaders);
      }
      if (e.response != null) {
        try {
          responseBody = e.response is String
              ? e.response as String
              : jsonEncode(e.response);
        } catch (_) {
          responseBody = e.response.toString();
        }
      }
      status = LogStatus.error;
    } catch (e) {
      errorMessage = e.toString();
      status = LogStatus.error;
    } finally {
      stopwatch.stop();
    }

    final newLog = ApiLogEntity(
      id: params.newId,
      url: params.url,
      method: params.method,
      requestHeaders: params.headers,
      queryParams: params.queryParams,
      requestBody: params.body,
      timestamp: DateTime.now(),
      durationMs: stopwatch.elapsedMilliseconds,
      statusCode: statusCode,
      responseBody: responseBody,
      responseHeaders: responseHeaders,
      requestSizeBytes: params.body?.length,
      responseSizeBytes: responseBody?.length,
      errorMessage: errorMessage,
      status: status,
      isEdited: true,
      parentId: params.originalLog.id,
    );

    // Replays go through the same redaction/truncation pipeline before
    // being stored; they are not uploaded to the cloud.
    final stored = await LogPipeline.record(
      newLog,
      upload: false,
      repository: repository,
    );
    return stored ?? newLog;
  }
}
