import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/performance_snapshot.dart';
import '../../../domain/repositories/performance_repository.dart';
import 'performance_event.dart';
import 'performance_state.dart';

class PerformanceBloc extends Bloc<PerformanceEvent, PerformanceState> {
  final PerformanceRepository repository;
  StreamSubscription<PerformanceSnapshot>? _subscription;

  PerformanceBloc({required this.repository})
      : super(const PerformanceState()) {
    on<PerformanceStartMonitoringEvent>(_onStartMonitoring);
    on<PerformanceStopMonitoringEvent>(_onStopMonitoring);
    on<PerformanceStartRecordingEvent>(_onStartRecording);
    on<PerformanceStopRecordingEvent>(_onStopRecording);
    on<PerformanceClearSessionEvent>(_onClearSession);
    on<PerformanceSnapshotUpdatedEvent>(_onSnapshotUpdated);
    on<PerformanceMarkScreenStartEvent>(_onMarkScreenStart);
    on<PerformanceMarkScreenEndEvent>(_onMarkScreenEnd);

    _subscription = repository.snapshotStream.listen(
      (snapshot) => add(PerformanceSnapshotUpdatedEvent(snapshot)),
    );
  }

  void _onStartMonitoring(
    PerformanceStartMonitoringEvent event,
    Emitter<PerformanceState> emit,
  ) {
    repository.startMonitoring();
    emit(state.copyWith(status: PerformanceStatus.monitoring));
  }

  void _onStopMonitoring(
    PerformanceStopMonitoringEvent event,
    Emitter<PerformanceState> emit,
  ) {
    repository.stopMonitoring();
    emit(state.copyWith(status: PerformanceStatus.stopped));
  }

  void _onStartRecording(
    PerformanceStartRecordingEvent event,
    Emitter<PerformanceState> emit,
  ) {
    repository.startRecording();
    emit(state.copyWith(status: PerformanceStatus.recording));
  }

  void _onStopRecording(
    PerformanceStopRecordingEvent event,
    Emitter<PerformanceState> emit,
  ) {
    repository.stopRecording();
    emit(state.copyWith(
        status: state.snapshot.isMonitoring
            ? PerformanceStatus.monitoring
            : PerformanceStatus.stopped));
  }

  void _onClearSession(
    PerformanceClearSessionEvent event,
    Emitter<PerformanceState> emit,
  ) {
    repository.clearSession();
  }

  void _onSnapshotUpdated(
    PerformanceSnapshotUpdatedEvent event,
    Emitter<PerformanceState> emit,
  ) {
    final snapshot = event.snapshot;
    PerformanceStatus status;
    if (snapshot.isRecording) {
      status = PerformanceStatus.recording;
    } else if (snapshot.isMonitoring) {
      status = PerformanceStatus.monitoring;
    } else {
      status = PerformanceStatus.stopped;
    }
    emit(state.copyWith(status: status, snapshot: snapshot));
  }

  void _onMarkScreenStart(
    PerformanceMarkScreenStartEvent event,
    Emitter<PerformanceState> emit,
  ) {
    repository.markScreenStart(event.screenName);
  }

  void _onMarkScreenEnd(
    PerformanceMarkScreenEndEvent event,
    Emitter<PerformanceState> emit,
  ) {
    repository.markScreenEnd(event.screenName);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
