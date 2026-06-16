import 'dart:convert';
import 'package:dio/dio.dart';
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
    final dio = Dio(
      BaseOptions(
        connectTimeout: AppConstants.requestTimeout,
        receiveTimeout: AppConstants.requestTimeout,
        validateStatus: (_) => true,
        headers: Map<String, dynamic>.from(params.headers),
      ),
    );

    final stopwatch = Stopwatch()..start();
    int? statusCode;
    String? responseBody;
    Map<String, dynamic> responseHeaders = {};
    String? errorMessage;
    LogStatus status = LogStatus.loading;

    try {
      final response = await dio.request(
        params.url,
        queryParameters: params.queryParams.isNotEmpty ? params.queryParams : null,
        data: params.body != null ? jsonDecode(params.body!) : null,
        options: Options(method: params.method.name.toUpperCase()),
      );

      stopwatch.stop();
      statusCode = response.statusCode;
      responseBody = response.data is String
          ? response.data as String
          : jsonEncode(response.data);
      response.headers.forEach((key, values) {
        responseHeaders[key] = values.join(', ');
      });
      status = (statusCode != null && statusCode >= 200 && statusCode < 400)
          ? LogStatus.success
          : LogStatus.error;
    } on DioException catch (e) {
      stopwatch.stop();
      statusCode = e.response?.statusCode;
      errorMessage = e.message;
      status = LogStatus.error;
    } catch (e) {
      stopwatch.stop();
      errorMessage = e.toString();
      status = LogStatus.error;
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
