import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/performance_snapshot.dart';
import '../../domain/repositories/performance_repository.dart';
import '../states/performance_state.dart';

class PerformanceController extends ChangeNotifier {
  final PerformanceRepository repository;
  StreamSubscription<PerformanceSnapshot>? _subscription;

  PerformanceState _state;
  PerformanceState get state => _state;

  late final ValueNotifier<PerformanceSnapshot> headerSnapshot;
  late final ValueNotifier<PerformanceSnapshot> overviewSnapshot;
  late final ValueNotifier<PerformanceSnapshot> frameSnapshot;
  late final ValueNotifier<PerformanceSnapshot> memorySnapshot;
  late final ValueNotifier<PerformanceSnapshot> connectivitySnapshot;
  late final ValueNotifier<PerformanceSnapshot> scoreSnapshot;

  PerformanceController({required this.repository})
      : _state = PerformanceState(snapshot: repository.currentSnapshot) {
    final snapshot = _state.snapshot;
    headerSnapshot = ValueNotifier(snapshot);
    overviewSnapshot = ValueNotifier(snapshot);
    frameSnapshot = ValueNotifier(snapshot);
    memorySnapshot = ValueNotifier(snapshot);
    connectivitySnapshot = ValueNotifier(snapshot);
    scoreSnapshot = ValueNotifier(snapshot);
    _subscription = repository.snapshotStream.listen(_onSnapshotUpdated);
  }

  void _onSnapshotUpdated(PerformanceSnapshot snapshot) {
    PerformanceStatus status;
    if (snapshot.isRecording) {
      status = PerformanceStatus.recording;
    } else if (snapshot.isMonitoring) {
      status = PerformanceStatus.monitoring;
    } else {
      status = PerformanceStatus.stopped;
    }
    final previous = _state.snapshot;
    _state = _state.copyWith(status: status, snapshot: snapshot);
    if (previous.isMonitoring != snapshot.isMonitoring ||
        previous.isRecording != snapshot.isRecording) {
      headerSnapshot.value = snapshot;
    }
    if (previous.frameMetrics != snapshot.frameMetrics ||
        previous.memoryMetrics != snapshot.memoryMetrics ||
        previous.startupMetrics != snapshot.startupMetrics ||
        previous.sessionDuration != snapshot.sessionDuration) {
      overviewSnapshot.value = snapshot;
    }
    if (previous.frameMetrics != snapshot.frameMetrics ||
        previous.fpsHistory != snapshot.fpsHistory ||
        previous.frameTimeHistory != snapshot.frameTimeHistory) {
      frameSnapshot.value = snapshot;
    }
    if (previous.memoryMetrics != snapshot.memoryMetrics ||
        previous.memoryHistoryBytes != snapshot.memoryHistoryBytes) {
      memorySnapshot.value = snapshot;
    }
    if (previous.connectivityPerformance != snapshot.connectivityPerformance) {
      connectivitySnapshot.value = snapshot;
    }
    if (previous.performanceScore != snapshot.performanceScore ||
        previous.healthGrade != snapshot.healthGrade) {
      scoreSnapshot.value = snapshot;
    }
    notifyListeners();
  }

  void startMonitoring() {
    repository.startMonitoring();
    _state = _state.copyWith(status: PerformanceStatus.monitoring);
    notifyListeners();
  }

  void stopMonitoring() {
    repository.stopMonitoring();
    _state = _state.copyWith(status: PerformanceStatus.stopped);
    notifyListeners();
  }

  void startRecording() {
    repository.startRecording();
    _state = _state.copyWith(status: PerformanceStatus.recording);
    notifyListeners();
  }

  void stopRecording() {
    repository.stopRecording();
    _state = _state.copyWith(
        status: _state.snapshot.isMonitoring
            ? PerformanceStatus.monitoring
            : PerformanceStatus.stopped);
    notifyListeners();
  }

  void clearSession() {
    repository.clearSession();
  }

  void markScreenStart(String screenName) {
    repository.markScreenStart(screenName);
  }

  void markScreenEnd(String screenName) {
    repository.markScreenEnd(screenName);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    headerSnapshot.dispose();
    overviewSnapshot.dispose();
    frameSnapshot.dispose();
    memorySnapshot.dispose();
    connectivitySnapshot.dispose();
    scoreSnapshot.dispose();
    super.dispose();
  }
}
