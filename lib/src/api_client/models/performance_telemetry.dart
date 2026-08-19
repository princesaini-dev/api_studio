/// Aggregated performance telemetry payload sent to the API Studio backend
/// at `POST /api/v1/performance`.
///
/// This is a dedicated, typed model instead of an untyped `Map` so the
/// backend contract is explicit and easy to evolve. Every nested section is
/// nullable: if the underlying [PerformanceMonitor] snapshot did not have
/// enough data to compute a value, the field is omitted rather than faked.
class PerformanceTelemetry {
  final DateTime timestamp;
  final int sessionDurationMs;
  final PerformanceFps? fps;
  final PerformanceFrameTime? frameTime;
  final PerformanceJank? jank;
  final PerformanceMemory? memory;
  final PerformanceStartup? startup;
  final int? healthScore;

  const PerformanceTelemetry({
    required this.timestamp,
    required this.sessionDurationMs,
    this.fps,
    this.frameTime,
    this.jank,
    this.memory,
    this.startup,
    this.healthScore,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'timestamp': timestamp.toUtc().toIso8601String(),
      'session_duration_ms': sessionDurationMs,
    };
    if (fps != null) json['fps'] = fps!.toJson();
    if (frameTime != null) json['frame_time'] = frameTime!.toJson();
    if (jank != null) json['jank'] = jank!.toJson();
    if (memory != null) json['memory'] = memory!.toJson();
    if (startup != null) json['startup'] = startup!.toJson();
    if (healthScore != null) json['health_score'] = healthScore;
    return json;
  }
}

class PerformanceFps {
  final double average;
  final double min;
  final double p95;

  const PerformanceFps({
    required this.average,
    required this.min,
    required this.p95,
  });

  Map<String, dynamic> toJson() => {
        'average': average,
        'min': min,
        'p95': p95,
      };
}

class PerformanceFrameTime {
  final double averageMs;
  final double p95Ms;

  const PerformanceFrameTime({
    required this.averageMs,
    required this.p95Ms,
  });

  Map<String, dynamic> toJson() => {
        'average_ms': averageMs,
        'p95_ms': p95Ms,
      };
}

class PerformanceJank {
  final int totalFrames;
  final int jankyFrames;
  final double jankRate;

  const PerformanceJank({
    required this.totalFrames,
    required this.jankyFrames,
    required this.jankRate,
  });

  Map<String, dynamic> toJson() => {
        'total_frames': totalFrames,
        'janky_frames': jankyFrames,
        'jank_rate': jankRate,
      };
}

class PerformanceMemory {
  final double averageMb;
  final double peakMb;

  const PerformanceMemory({
    required this.averageMb,
    required this.peakMb,
  });

  Map<String, dynamic> toJson() => {
        'average_mb': averageMb,
        'peak_mb': peakMb,
      };
}

class PerformanceStartup {
  final int durationMs;

  const PerformanceStartup({required this.durationMs});

  Map<String, dynamic> toJson() => {'duration_ms': durationMs};
}
