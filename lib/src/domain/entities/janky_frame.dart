import 'package:equatable/equatable.dart';

import 'frame_metrics.dart';

class JankyFrame extends Equatable {
  final int frameNumber;
  final double durationMs;
  final double uiTimeMs;
  final double rasterTimeMs;
  final FrameSeverity severity;

  const JankyFrame({
    required this.frameNumber,
    required this.durationMs,
    required this.uiTimeMs,
    required this.rasterTimeMs,
    required this.severity,
  });

  @override
  List<Object?> get props =>
      [frameNumber, durationMs, uiTimeMs, rasterTimeMs, severity];
}
