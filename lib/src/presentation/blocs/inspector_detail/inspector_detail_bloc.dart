import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/api_log_repository.dart';
import '../../../domain/usecases/delete_log_usecase.dart';
import '../../../core/utils/curl_generator.dart';
import 'inspector_detail_event.dart';
import 'inspector_detail_state.dart';

class InspectorDetailBloc extends Bloc<InspectorDetailEvent, InspectorDetailState> {
  final ApiLogRepository repository;
  final DeleteLogUseCase deleteLogUseCase;

  InspectorDetailBloc({
    required this.repository,
    required this.deleteLogUseCase,
  }) : super(const InspectorDetailState()) {
    on<LoadDetailEvent>(_onLoad);
    on<ChangeDetailTabEvent>(_onChangeTab);
    on<CopyCurlEvent>(_onCopyCurl);
    on<DeleteDetailLogEvent>(_onDelete);
  }

  Future<void> _onLoad(LoadDetailEvent event, Emitter<InspectorDetailState> emit) async {
    emit(state.copyWith(status: DetailStatus.loading));
    try {
      final log = await repository.getLogById(event.logId);
      if (log == null) {
        emit(state.copyWith(status: DetailStatus.failure, errorMessage: 'Log not found'));
        return;
      }
      emit(state.copyWith(status: DetailStatus.success, log: log));
    } catch (e) {
      emit(state.copyWith(status: DetailStatus.failure, errorMessage: e.toString()));
    }
  }

  void _onChangeTab(ChangeDetailTabEvent event, Emitter<InspectorDetailState> emit) {
    emit(state.copyWith(selectedTabIndex: event.tabIndex));
  }

  Future<void> _onCopyCurl(CopyCurlEvent event, Emitter<InspectorDetailState> emit) async {
    if (state.log == null) return;
    final curl = CurlGenerator.generate(state.log!);
    await Clipboard.setData(ClipboardData(text: curl));
    emit(state.copyWith(curlCopied: true));
    await Future<void>.delayed(const Duration(seconds: 2));
    emit(state.copyWith(curlCopied: false));
  }

  Future<void> _onDelete(DeleteDetailLogEvent event, Emitter<InspectorDetailState> emit) async {
    if (state.log == null) return;
    await deleteLogUseCase(state.log!.id);
    emit(state.copyWith(status: DetailStatus.deleted));
  }
}
