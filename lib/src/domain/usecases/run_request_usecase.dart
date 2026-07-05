import 'dart:convert';
import 'dart:io';
import '../entities/api_log_entity.dart';
import '../repositories/api_log_repository.dart';
import '../../core/usecases/usecase.dart';
import '../../core/constants/app_constants.dart';

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

  @override
  Future<ApiLogEntity> call(RunRequestParams params) async {
    final stopwatch = Stopwatch()..start();
    int? statusCode;
    String? responseBody;
    Map<String, dynamic> responseHeaders = {};
    String? errorMessage;
    LogStatus status = LogStatus.loading;

    try {
      // Build URI with query parameters
      var uri = Uri.parse(params.url);
      if (params.queryParams.isNotEmpty) {
        final merged = Map<String, String>.from(uri.queryParameters)
          ..addAll(params.queryParams.map((k, v) => MapEntry(k, v.toString())));
        uri = uri.replace(queryParameters: merged);
      }

      final client = HttpClient()
        ..connectionTimeout = AppConstants.requestTimeout;

      final ioRequest =
          await client.openUrl(params.method.name.toUpperCase(), uri).timeout(
                AppConstants.requestTimeout,
              );

      // Headers
      for (final e in params.headers.entries) {
        try {
          ioRequest.headers.set(e.key, e.value.toString());
        } catch (_) {}
      }

      // Body
      if (params.body != null && params.body!.isNotEmpty) {
        final bytes = utf8.encode(params.body!);
        ioRequest.contentLength = bytes.length;
        if (ioRequest.headers.value(HttpHeaders.contentTypeHeader) == null) {
          ioRequest.headers.contentType =
              ContentType('application', 'json', charset: 'utf-8');
        }
        ioRequest.add(bytes);
      }

      final ioResponse =
          await ioRequest.close().timeout(AppConstants.requestTimeout);

      // Collect response headers
      ioResponse.headers.forEach((name, values) {
        responseHeaders[name] = values.join(', ');
      });

      // Read body
      final chunks = <int>[];
      await for (final chunk in ioResponse) {
        chunks.addAll(chunk);
      }
      final rawBody = utf8.decode(chunks, allowMalformed: true);

      // Try JSON decode, fall back to raw string
      try {
        final decoded = jsonDecode(rawBody);
        responseBody = decoded is String ? decoded : jsonEncode(decoded);
      } catch (_) {
        responseBody = rawBody;
      }

      statusCode = ioResponse.statusCode;
      status = (statusCode >= 200 && statusCode < 400)
          ? LogStatus.success
          : LogStatus.error;

      client.close();
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

    await repository.saveLog(newLog);
    return newLog;
  }
}
