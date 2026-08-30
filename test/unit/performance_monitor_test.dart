import 'package:api_studio/src/services/performance_monitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final monitor = PerformanceMonitor.instance;

  tearDown(monitor.stop);

  test('performance monitoring is disabled by default', () {
    monitor.stop();

    expect(monitor.isMonitoring, isFalse);
    expect(monitor.isRecording, isFalse);
    expect(monitor.currentSnapshot.isMonitoring, isFalse);
    expect(monitor.currentSnapshot.frameTimeHistory, isEmpty);
    expect(monitor.currentSnapshot.memoryHistoryBytes, isEmpty);
  });

  test('monitoring starts only after an explicit start', () {
    monitor.stop();

    monitor.start();

    expect(monitor.isMonitoring, isTrue);
    expect(monitor.currentSnapshot.isMonitoring, isTrue);
  });

  test('stop clears active state and all retained samples', () {
    monitor.start();
    monitor.startRecording();

    monitor.stop();

    final snapshot = monitor.currentSnapshot;
    expect(monitor.isMonitoring, isFalse);
    expect(monitor.isRecording, isFalse);
    expect(snapshot.isMonitoring, isFalse);
    expect(snapshot.isRecording, isFalse);
    expect(snapshot.sessionDuration, Duration.zero);
    expect(snapshot.frameTimeHistory, isEmpty);
    expect(snapshot.fpsHistory, isEmpty);
    expect(snapshot.memoryHistoryBytes, isEmpty);
    expect(snapshot.timelineEvents, isEmpty);
    expect(snapshot.screenPerformances, isEmpty);
    expect(snapshot.connectivityPerformance.changes, isEmpty);
  });
}
