import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/repositories/api_log_repository.dart';
import '../../domain/usecases/get_logs_usecase.dart';
import '../../domain/usecases/delete_log_usecase.dart';
import '../../domain/usecases/clear_logs_usecase.dart';
import '../../core/usecases/usecase.dart';
import '../states/inspector_list_state.dart';

class InspectorListController extends ChangeNotifier {
  final GetLogsUseCase getLogsUseCase;
  final DeleteLogUseCase deleteLogUseCase;
  final ClearLogsUseCase clearLogsUseCase;
  final ApiLogRepository repository;
  StreamSubscription<dynamic>? _watchSubscription;

  InspectorListState _state = const InspectorListState();
  InspectorListState get state => _state;

  InspectorListController({
    required this.getLogsUseCase,
    required this.deleteLogUseCase,
    required this.clearLogsUseCase,
    required this.repository,
  }) {
    _watchSubscription = repository.watchLogs().listen((_) {
      if (_state.status == InspectorListStatus.success) {
        loadLogs(refresh: true);
      }
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

  Future<void> loadLogs({bool refresh = false}) async {
    _state =
        _state.copyWith(status: InspectorListStatus.loading, currentPage: 0);
    notifyListeners();
    try {
      final logs = await getLogsUseCase(_buildParams(_state));
      _state = _state.copyWith(
        status: InspectorListStatus.success,
        logs: logs,
        currentPage: 0,
        hasReachedMax: logs.length < AppConstants.defaultPageSize,
      );
    } catch (e) {
      _state = _state.copyWith(
          status: InspectorListStatus.failure, errorMessage: e.toString());
    }
    notifyListeners();
  }

  Future<void> loadMoreLogs() async {
    if (_state.hasReachedMax) return;
    try {
      final nextPage = _state.currentPage + 1;
      final more = await getLogsUseCase(_buildParams(_state, page: nextPage));
      _state = _state.copyWith(
        logs: [..._state.logs, ...more],
        currentPage: nextPage,
        hasReachedMax: more.length < AppConstants.defaultPageSize,
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<void> searchLogs(String query) async {
    _state = _state.copyWith(searchQuery: query, currentPage: 0);
    notifyListeners();
    await loadLogs();
  }

  Future<void> filterMethod(MethodFilter filter) async {
    _state = _state.copyWith(methodFilter: filter, currentPage: 0);
    notifyListeners();
    await loadLogs();
  }

  Future<void> filterStatus(StatusFilter filter) async {
    _state = _state.copyWith(statusFilter: filter, currentPage: 0);
    notifyListeners();
    await loadLogs();
  }

  Future<void> sortLogs(SortOrder order) async {
    _state = _state.copyWith(sortOrder: order, currentPage: 0);
    notifyListeners();
    await loadLogs();
  }

  Future<void> deleteLog(String id) async {
    await deleteLogUseCase(id);
    final updated = _state.logs.where((l) => l.id != id).toList();
    _state = _state.copyWith(logs: updated);
    notifyListeners();
  }

  Future<void> clearAllLogs() async {
    await clearLogsUseCase(const NoParams());
    _state = _state.copyWith(logs: [], hasReachedMax: true);
    notifyListeners();
  }

  @override
  void dispose() {
    _watchSubscription?.cancel();
    super.dispose();
  }
}
