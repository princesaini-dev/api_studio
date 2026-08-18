import 'dart:async';

import '../../domain/entities/performance_snapshot.dart';
import '../../domain/repositories/performance_repository.dart';
import '../../services/performance_monitor.dart';

class PerformanceRepositoryImpl implements PerformanceRepository {
  final PerformanceMonitor _monitor;

  PerformanceRepositoryImpl(this._monitor);

  @override
  Stream<PerformanceSnapshot> get snapshotStream => _monitor.snapshotStream;

  @override
  PerformanceSnapshot get currentSnapshot => _monitor.currentSnapshot;

  @override
  void startMonitoring() => _monitor.start();

  @override
  void stopMonitoring() => _monitor.stop();

  @override
  void startRecording() => _monitor.startRecording();

  @override
  void stopRecording() => _monitor.stopRecording();

  @override
  void clearSession() => _monitor.clearSession();

  @override
  void markScreenStart(String name) => _monitor.markScreenStart(name);

  @override
  void markScreenEnd(String name) => _monitor.markScreenEnd(name);

  @override
  void recordStartupPhase(String name, {Duration? duration}) =>
      _monitor.recordStartupPhase(name, duration: duration);

  @override
  void addCustomEvent(String description, {String? metricValue}) =>
      _monitor.addCustomEvent(description, metricValue: metricValue);

  @override
  void dispose() => _monitor.dispose();
}
