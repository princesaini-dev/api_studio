import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/usecases/run_request_usecase.dart';
import 'edit_run_event.dart';
import 'edit_run_state.dart';

class EditRunBloc extends Bloc<EditRunEvent, EditRunState> {
  final RunRequestUseCase runRequestUseCase;
  final _uuid = const Uuid();

  EditRunBloc({required this.runRequestUseCase}) : super(const EditRunState()) {
    on<InitEditRunEvent>(_onInit);
    on<UpdateUrlEvent>(_onUpdateUrl);
    on<UpdateMethodEvent>(_onUpdateMethod);
    on<UpdateHeadersEvent>(_onUpdateHeaders);
    on<UpdateQueryParamsEvent>(_onUpdateQueryParams);
    on<UpdateBodyEvent>(_onUpdateBody);
    on<RunRequestEvent>(_onRun);
  }

  void _onInit(InitEditRunEvent event, Emitter<EditRunState> emit) {
    emit(EditRunState(
      originalLog: event.log,
      url: event.log.url,
      method: event.log.method,
      headers: Map<String, dynamic>.from(event.log.requestHeaders),
      queryParams: Map<String, dynamic>.from(event.log.queryParams),
      body: event.log.requestBody,
    ));
  }

  void _onUpdateUrl(UpdateUrlEvent event, Emitter<EditRunState> emit) {
    emit(state.copyWith(url: event.url));
  }

  void _onUpdateMethod(UpdateMethodEvent event, Emitter<EditRunState> emit) {
    emit(state.copyWith(method: event.method));
  }

  void _onUpdateHeaders(UpdateHeadersEvent event, Emitter<EditRunState> emit) {
    emit(state.copyWith(headers: event.headers));
  }

  void _onUpdateQueryParams(UpdateQueryParamsEvent event, Emitter<EditRunState> emit) {
    emit(state.copyWith(queryParams: event.params));
  }

  void _onUpdateBody(UpdateBodyEvent event, Emitter<EditRunState> emit) {
    emit(state.copyWith(body: event.body));
  }

  Future<void> _onRun(RunRequestEvent event, Emitter<EditRunState> emit) async {
    if (state.originalLog == null) return;
    emit(state.copyWith(status: EditRunStatus.running));
    try {
      final result = await runRequestUseCase(RunRequestParams(
        originalLog: state.originalLog!,
        url: state.url,
        method: state.method,
        headers: state.headers,
        queryParams: state.queryParams,
        body: state.body,
        newId: _uuid.v4(),
      ));
      emit(state.copyWith(status: EditRunStatus.success, resultLog: result));
    } catch (e) {
      emit(state.copyWith(status: EditRunStatus.failure, errorMessage: e.toString()));
    }
  }
}
