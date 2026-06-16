import 'package:equatable/equatable.dart';
import '../../../domain/entities/api_log_entity.dart';
import '../../../domain/repositories/api_log_repository.dart';

enum InspectorListStatus { initial, loading, success, failure }

class InspectorListState extends Equatable {
  final InspectorListStatus status;
  final List<ApiLogEntity> logs;
  final bool hasReachedMax;
  final int currentPage;
  final String? searchQuery;
  final MethodFilter methodFilter;
  final StatusFilter statusFilter;
  final SortOrder sortOrder;
  final String? errorMessage;

  const InspectorListState({
    this.status = InspectorListStatus.initial,
    this.logs = const [],
    this.hasReachedMax = false,
    this.currentPage = 0,
    this.searchQuery,
    this.methodFilter = MethodFilter.all,
    this.statusFilter = StatusFilter.all,
    this.sortOrder = SortOrder.newest,
    this.errorMessage,
  });

  InspectorListState copyWith({
    InspectorListStatus? status,
    List<ApiLogEntity>? logs,
    bool? hasReachedMax,
    int? currentPage,
    String? searchQuery,
    MethodFilter? methodFilter,
    StatusFilter? statusFilter,
    SortOrder? sortOrder,
    String? errorMessage,
  }) {
    return InspectorListState(
      status: status ?? this.status,
      logs: logs ?? this.logs,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
      methodFilter: methodFilter ?? this.methodFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      sortOrder: sortOrder ?? this.sortOrder,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        logs,
        hasReachedMax,
        currentPage,
        searchQuery,
        methodFilter,
        statusFilter,
        sortOrder,
        errorMessage,
      ];
}
