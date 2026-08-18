import '../entities/performance_snapshot.dart';

abstract class PerformanceRepository {
  Stream<PerformanceSnapshot> get snapshotStream;
  PerformanceSnapshot get currentSnapshot;
  void startMonitoring();
  void stopMonitoring();
  void startRecording();
  void stopRecording();
  void clearSession();
  void markScreenStart(String name);
  void markScreenEnd(String name);
  void recordStartupPhase(String name, {Duration? duration});
  void addCustomEvent(String description, {String? metricValue});
  void dispose();
}
