import 'package:equatable/equatable.dart';

import 'frame_metrics.dart';
import 'memory_metrics.dart';
import 'startup_metrics.dart';
import 'performance_event.dart';
import 'screen_performance.dart';
import 'network_performance.dart';
import 'connectivity_performance.dart';

enum PerformanceHealthGrade { excellent, good, fair, poor, insufficientData }

class PerformanceSnapshot extends Equatable {
  final FrameMetrics frameMetrics;
  final MemoryMetrics memoryMetrics;
  final StartupMetrics startupMetrics;
  final List<PerformanceEvent> timelineEvents;
  final List<ScreenPerformance> screenPerformances;
  final NetworkPerformance networkPerformance;
  final ConnectivityPerformance connectivityPerformance;
  final bool isMonitoring;
  final bool isRecording;
  final Duration sessionDuration;
  final int performanceScore;
  final PerformanceHealthGrade healthGrade;
  final List<double> fpsHistory;
  final List<double> frameTimeHistory;
  final List<int> memoryHistoryBytes;

  const PerformanceSnapshot({
    this.frameMetrics = const FrameMetrics(),
    this.memoryMetrics = const MemoryMetrics(),
    this.startupMetrics = const StartupMetrics(),
    this.timelineEvents = const [],
    this.screenPerformances = const [],
    this.networkPerformance = const NetworkPerformance(),
    this.connectivityPerformance = const ConnectivityPerformance(),
    this.isMonitoring = false,
    this.isRecording = false,
    this.sessionDuration = Duration.zero,
    this.performanceScore = 0,
    this.healthGrade = PerformanceHealthGrade.insufficientData,
    this.fpsHistory = const [],
    this.frameTimeHistory = const [],
    this.memoryHistoryBytes = const [],
  });

  PerformanceSnapshot copyWith({
    FrameMetrics? frameMetrics,
    MemoryMetrics? memoryMetrics,
    StartupMetrics? startupMetrics,
    List<PerformanceEvent>? timelineEvents,
    List<ScreenPerformance>? screenPerformances,
    NetworkPerformance? networkPerformance,
    ConnectivityPerformance? connectivityPerformance,
    bool? isMonitoring,
    bool? isRecording,
    Duration? sessionDuration,
    int? performanceScore,
    PerformanceHealthGrade? healthGrade,
    List<double>? fpsHistory,
    List<double>? frameTimeHistory,
    List<int>? memoryHistoryBytes,
  }) {
    return PerformanceSnapshot(
      frameMetrics: frameMetrics ?? this.frameMetrics,
      memoryMetrics: memoryMetrics ?? this.memoryMetrics,
      startupMetrics: startupMetrics ?? this.startupMetrics,
      timelineEvents: timelineEvents ?? this.timelineEvents,
      screenPerformances: screenPerformances ?? this.screenPerformances,
      networkPerformance: networkPerformance ?? this.networkPerformance,
      connectivityPerformance:
          connectivityPerformance ?? this.connectivityPerformance,
      isMonitoring: isMonitoring ?? this.isMonitoring,
      isRecording: isRecording ?? this.isRecording,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      performanceScore: performanceScore ?? this.performanceScore,
      healthGrade: healthGrade ?? this.healthGrade,
      fpsHistory: fpsHistory ?? this.fpsHistory,
      frameTimeHistory: frameTimeHistory ?? this.frameTimeHistory,
      memoryHistoryBytes: memoryHistoryBytes ?? this.memoryHistoryBytes,
    );
  }

  @override
  List<Object?> get props => [
        frameMetrics,
        memoryMetrics,
        startupMetrics,
        timelineEvents,
        screenPerformances,
        networkPerformance,
        connectivityPerformance,
        isMonitoring,
        isRecording,
        sessionDuration,
        performanceScore,
        healthGrade,
        fpsHistory,
        frameTimeHistory,
        memoryHistoryBytes,
      ];
}
