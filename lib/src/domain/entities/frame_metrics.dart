import 'package:equatable/equatable.dart';

enum FrameSeverity { good, warning, critical }

class FrameMetrics extends Equatable {
  final double currentFps;
  final double averageFps;
  final double minFps;
  final double maxFps;
  final double averageFrameTimeMs;
  final int totalFrames;
  final int slowFrames;
  final int jankyFrames;
  final double jankRate;
  final double averageUiTimeMs;
  final double averageRasterTimeMs;
  final double averageTotalProcessingMs;
  final double lastFrameTimeMs;
  final double lastUiTimeMs;
  final double lastRasterTimeMs;
  final FrameSeverity severity;

  const FrameMetrics({
    this.currentFps = 0,
    this.averageFps = 0,
    this.minFps = 0,
    this.maxFps = 0,
    this.averageFrameTimeMs = 0,
    this.totalFrames = 0,
    this.slowFrames = 0,
    this.jankyFrames = 0,
    this.jankRate = 0,
    this.averageUiTimeMs = 0,
    this.averageRasterTimeMs = 0,
    this.averageTotalProcessingMs = 0,
    this.lastFrameTimeMs = 0,
    this.lastUiTimeMs = 0,
    this.lastRasterTimeMs = 0,
    this.severity = FrameSeverity.good,
  });

  bool get hasData => totalFrames > 0;

  FrameMetrics copyWith({
    double? currentFps,
    double? averageFps,
    double? minFps,
    double? maxFps,
    double? averageFrameTimeMs,
    int? totalFrames,
    int? slowFrames,
    int? jankyFrames,
    double? jankRate,
    double? averageUiTimeMs,
    double? averageRasterTimeMs,
    double? averageTotalProcessingMs,
    double? lastFrameTimeMs,
    double? lastUiTimeMs,
    double? lastRasterTimeMs,
    FrameSeverity? severity,
  }) {
    return FrameMetrics(
      currentFps: currentFps ?? this.currentFps,
      averageFps: averageFps ?? this.averageFps,
      minFps: minFps ?? this.minFps,
      maxFps: maxFps ?? this.maxFps,
      averageFrameTimeMs: averageFrameTimeMs ?? this.averageFrameTimeMs,
      totalFrames: totalFrames ?? this.totalFrames,
      slowFrames: slowFrames ?? this.slowFrames,
      jankyFrames: jankyFrames ?? this.jankyFrames,
      jankRate: jankRate ?? this.jankRate,
      averageUiTimeMs: averageUiTimeMs ?? this.averageUiTimeMs,
      averageRasterTimeMs: averageRasterTimeMs ?? this.averageRasterTimeMs,
      averageTotalProcessingMs:
          averageTotalProcessingMs ?? this.averageTotalProcessingMs,
      lastFrameTimeMs: lastFrameTimeMs ?? this.lastFrameTimeMs,
      lastUiTimeMs: lastUiTimeMs ?? this.lastUiTimeMs,
      lastRasterTimeMs: lastRasterTimeMs ?? this.lastRasterTimeMs,
      severity: severity ?? this.severity,
    );
  }

  @override
  List<Object?> get props => [
        currentFps,
        averageFps,
        minFps,
        maxFps,
        averageFrameTimeMs,
        totalFrames,
        slowFrames,
        jankyFrames,
        jankRate,
        averageUiTimeMs,
        averageRasterTimeMs,
        averageTotalProcessingMs,
        lastFrameTimeMs,
        lastUiTimeMs,
        lastRasterTimeMs,
        severity,
      ];
}
