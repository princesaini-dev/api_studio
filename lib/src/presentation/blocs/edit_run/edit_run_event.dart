import 'package:equatable/equatable.dart';
import '../../../domain/entities/api_log_entity.dart';

abstract class EditRunEvent extends Equatable {
  const EditRunEvent();

  @override
  List<Object?> get props => [];
}

class InitEditRunEvent extends EditRunEvent {
  final ApiLogEntity log;
  const InitEditRunEvent(this.log);

  @override
  List<Object?> get props => [log];
}

class UpdateUrlEvent extends EditRunEvent {
  final String url;
  const UpdateUrlEvent(this.url);

  @override
  List<Object?> get props => [url];
}

class UpdateMethodEvent extends EditRunEvent {
  final HttpMethod method;
  const UpdateMethodEvent(this.method);

  @override
  List<Object?> get props => [method];
}

class UpdateHeadersEvent extends EditRunEvent {
  final Map<String, dynamic> headers;
  const UpdateHeadersEvent(this.headers);

  @override
  List<Object?> get props => [headers];
}

class UpdateQueryParamsEvent extends EditRunEvent {
  final Map<String, dynamic> params;
  const UpdateQueryParamsEvent(this.params);

  @override
  List<Object?> get props => [params];
}

class UpdateBodyEvent extends EditRunEvent {
  final String? body;
  const UpdateBodyEvent(this.body);

  @override
  List<Object?> get props => [body];
}

class RunRequestEvent extends EditRunEvent {
  const RunRequestEvent();
}
