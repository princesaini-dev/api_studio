import 'package:equatable/equatable.dart';
import '../../../domain/repositories/api_log_repository.dart';

abstract class InspectorListEvent extends Equatable {
  const InspectorListEvent();

  @override
  List<Object?> get props => [];
}

class LoadLogsEvent extends InspectorListEvent {
  final bool refresh;
  const LoadLogsEvent({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

class LoadMoreLogsEvent extends InspectorListEvent {
  const LoadMoreLogsEvent();
}

class SearchLogsEvent extends InspectorListEvent {
  final String query;
  const SearchLogsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterMethodEvent extends InspectorListEvent {
  final MethodFilter filter;
  const FilterMethodEvent(this.filter);

  @override
  List<Object?> get props => [filter];
}

class FilterStatusEvent extends InspectorListEvent {
  final StatusFilter filter;
  const FilterStatusEvent(this.filter);

  @override
  List<Object?> get props => [filter];
}

class SortLogsEvent extends InspectorListEvent {
  final SortOrder order;
  const SortLogsEvent(this.order);

  @override
  List<Object?> get props => [order];
}

class DeleteLogEvent extends InspectorListEvent {
  final String id;
  const DeleteLogEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class ClearAllLogsEvent extends InspectorListEvent {
  const ClearAllLogsEvent();
}

class LogsUpdatedEvent extends InspectorListEvent {
  const LogsUpdatedEvent();
}
