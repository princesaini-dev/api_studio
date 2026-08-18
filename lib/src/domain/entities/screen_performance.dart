import 'package:equatable/equatable.dart';

enum ScreenPerformanceStatus { good, warning, critical }

class ScreenPerformance extends Equatable {
  final String screenName;
  final int? loadTimeMs;
  final double averageFps;
  final int jankyFrames;
  final double averageFrameTimeMs;
  final int? peakMemoryBytes;
  final Duration sessionDuration;
  final ScreenPerformanceStatus status;

  const ScreenPerformance({
    required this.screenName,
    this.loadTimeMs,
    this.averageFps = 0,
    this.jankyFrames = 0,
    this.averageFrameTimeMs = 0,
    this.peakMemoryBytes,
    this.sessionDuration = Duration.zero,
    this.status = ScreenPerformanceStatus.good,
  });

  @override
  List<Object?> get props => [
        screenName,
        loadTimeMs,
        averageFps,
        jankyFrames,
        averageFrameTimeMs,
        peakMemoryBytes,
        sessionDuration,
        status,
      ];
}
