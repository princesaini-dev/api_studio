import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/performance_snapshot.dart';
import '../../domain/repositories/performance_repository.dart';
import '../states/performance_state.dart';

class PerformanceController extends ChangeNotifier {
  final PerformanceRepository repository;
  StreamSubscription<PerformanceSnapshot>? _subscription;

  PerformanceState _state = const PerformanceState();
  PerformanceState get state => _state;

  PerformanceController({required this.repository}) {
    _subscription = repository.snapshotStream.listen((snapshot) {
      _onSnapshotUpdated(snapshot);
    });
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
    _state = _state.copyWith(status: status, snapshot: snapshot);
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
    super.dispose();
  }
}
