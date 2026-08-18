import 'package:equatable/equatable.dart';

import '../../../domain/entities/performance_snapshot.dart';

abstract class PerformanceEvent extends Equatable {
  const PerformanceEvent();

  @override
  List<Object?> get props => [];
}

class PerformanceStartMonitoringEvent extends PerformanceEvent {
  const PerformanceStartMonitoringEvent();
}

class PerformanceStopMonitoringEvent extends PerformanceEvent {
  const PerformanceStopMonitoringEvent();
}

class PerformanceStartRecordingEvent extends PerformanceEvent {
  const PerformanceStartRecordingEvent();
}

class PerformanceStopRecordingEvent extends PerformanceEvent {
  const PerformanceStopRecordingEvent();
}

class PerformanceClearSessionEvent extends PerformanceEvent {
  const PerformanceClearSessionEvent();
}

class PerformanceSnapshotUpdatedEvent extends PerformanceEvent {
  final PerformanceSnapshot snapshot;

  const PerformanceSnapshotUpdatedEvent(this.snapshot);

  @override
  List<Object?> get props => [snapshot];
}

class PerformanceMarkScreenStartEvent extends PerformanceEvent {
  final String screenName;
  const PerformanceMarkScreenStartEvent(this.screenName);

  @override
  List<Object?> get props => [screenName];
}

class PerformanceMarkScreenEndEvent extends PerformanceEvent {
  final String screenName;
  const PerformanceMarkScreenEndEvent(this.screenName);

  @override
  List<Object?> get props => [screenName];
}
