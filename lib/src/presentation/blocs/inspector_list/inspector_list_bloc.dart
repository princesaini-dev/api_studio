import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/repositories/api_log_repository.dart';
import '../../../domain/usecases/get_logs_usecase.dart';
import '../../../domain/usecases/delete_log_usecase.dart';
import '../../../domain/usecases/clear_logs_usecase.dart';
import '../../../core/usecases/usecase.dart';
import 'inspector_list_event.dart';
import 'inspector_list_state.dart';

class InspectorListBloc extends Bloc<InspectorListEvent, InspectorListState> {
  final GetLogsUseCase getLogsUseCase;
  final DeleteLogUseCase deleteLogUseCase;
  final ClearLogsUseCase clearLogsUseCase;
  final ApiLogRepository repository;
  StreamSubscription<dynamic>? _watchSubscription;

  InspectorListBloc({
    required this.getLogsUseCase,
    required this.deleteLogUseCase,
    required this.clearLogsUseCase,
    required this.repository,
  }) : super(const InspectorListState()) {
    on<LoadLogsEvent>(_onLoad);
    on<LoadMoreLogsEvent>(_onLoadMore);
    on<SearchLogsEvent>(_onSearch);
    on<FilterMethodEvent>(_onFilterMethod);
    on<FilterStatusEvent>(_onFilterStatus);
    on<SortLogsEvent>(_onSort);
    on<DeleteLogEvent>(_onDelete);
    on<ClearAllLogsEvent>(_onClearAll);
    on<LogsUpdatedEvent>(_onLogsUpdated);

    _watchSubscription = repository.watchLogs().listen((_) {
      add(const LogsUpdatedEvent());
    });
  }

  GetLogsParams _buildParams(InspectorListState s, {int page = 0}) {
    return GetLogsParams(
      page: page,
      pageSize: AppConstants.defaultPageSize,
      searchQuery: s.searchQuery,
      methodFilter: s.methodFilter,
      statusFilter: s.statusFilter,
      sortOrder: s.sortOrder,
    );
  }

  Future<void> _onLoad(LoadLogsEvent event, Emitter<InspectorListState> emit) async {
    emit(state.copyWith(status: InspectorListStatus.loading, currentPage: 0));
    try {
      final logs = await getLogsUseCase(_buildParams(state));
      emit(state.copyWith(
        status: InspectorListStatus.success,
        logs: logs,
        currentPage: 0,
        hasReachedMax: logs.length < AppConstants.defaultPageSize,
      ));
    } catch (e) {
      emit(state.copyWith(status: InspectorListStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadMore(LoadMoreLogsEvent event, Emitter<InspectorListState> emit) async {
    if (state.hasReachedMax) return;
    try {
      final nextPage = state.currentPage + 1;
      final more = await getLogsUseCase(_buildParams(state, page: nextPage));
      emit(state.copyWith(
        logs: [...state.logs, ...more],
        currentPage: nextPage,
        hasReachedMax: more.length < AppConstants.defaultPageSize,
      ));
    } catch (_) {}
  }

  Future<void> _onSearch(SearchLogsEvent event, Emitter<InspectorListState> emit) async {
    emit(state.copyWith(searchQuery: event.query, currentPage: 0));
    add(const LoadLogsEvent());
  }

  Future<void> _onFilterMethod(FilterMethodEvent event, Emitter<InspectorListState> emit) async {
    emit(state.copyWith(methodFilter: event.filter, currentPage: 0));
    add(const LoadLogsEvent());
  }

  Future<void> _onFilterStatus(FilterStatusEvent event, Emitter<InspectorListState> emit) async {
    emit(state.copyWith(statusFilter: event.filter, currentPage: 0));
    add(const LoadLogsEvent());
  }

  Future<void> _onSort(SortLogsEvent event, Emitter<InspectorListState> emit) async {
    emit(state.copyWith(sortOrder: event.order, currentPage: 0));
    add(const LoadLogsEvent());
  }

  Future<void> _onDelete(DeleteLogEvent event, Emitter<InspectorListState> emit) async {
    await deleteLogUseCase(event.id);
    final updated = state.logs.where((l) => l.id != event.id).toList();
    emit(state.copyWith(logs: updated));
  }

  Future<void> _onClearAll(ClearAllLogsEvent event, Emitter<InspectorListState> emit) async {
    await clearLogsUseCase(const NoParams());
    emit(state.copyWith(logs: [], hasReachedMax: true));
  }

  Future<void> _onLogsUpdated(LogsUpdatedEvent event, Emitter<InspectorListState> emit) async {
    if (state.status == InspectorListStatus.success) {
      add(const LoadLogsEvent(refresh: true));
    }
  }

  @override
  Future<void> close() {
    _watchSubscription?.cancel();
    return super.close();
  }
}
