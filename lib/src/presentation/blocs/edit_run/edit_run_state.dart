import 'package:equatable/equatable.dart';
import '../../../domain/entities/api_log_entity.dart';

enum EditRunStatus { idle, running, success, failure }

class EditRunState extends Equatable {
  final EditRunStatus status;
  final ApiLogEntity? originalLog;
  final String url;
  final HttpMethod method;
  final Map<String, dynamic> headers;
  final Map<String, dynamic> queryParams;
  final String? body;
  final ApiLogEntity? resultLog;
  final String? errorMessage;

  const EditRunState({
    this.status = EditRunStatus.idle,
    this.originalLog,
    this.url = '',
    this.method = HttpMethod.get,
    this.headers = const {},
    this.queryParams = const {},
    this.body,
    this.resultLog,
    this.errorMessage,
  });

  EditRunState copyWith({
    EditRunStatus? status,
    ApiLogEntity? originalLog,
    String? url,
    HttpMethod? method,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParams,
    String? body,
    ApiLogEntity? resultLog,
    String? errorMessage,
  }) {
    return EditRunState(
      status: status ?? this.status,
      originalLog: originalLog ?? this.originalLog,
      url: url ?? this.url,
      method: method ?? this.method,
      headers: headers ?? this.headers,
      queryParams: queryParams ?? this.queryParams,
      body: body ?? this.body,
      resultLog: resultLog ?? this.resultLog,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        originalLog,
        url,
        method,
        headers,
        queryParams,
        body,
        resultLog,
        errorMessage,
      ];
}
