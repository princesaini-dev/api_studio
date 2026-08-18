import 'package:equatable/equatable.dart';

class StartupPhase extends Equatable {
  final String name;
  final Duration? duration;
  final DateTime? timestamp;

  const StartupPhase({
    required this.name,
    this.duration,
    this.timestamp,
  });

  bool get hasData => duration != null;

  @override
  List<Object?> get props => [name, duration, timestamp];
}

class StartupMetrics extends Equatable {
  final List<StartupPhase> phases;
  final Duration? totalStartupDuration;
  final Duration? timeToFirstFrame;
  final bool isAvailable;

  const StartupMetrics({
    this.phases = const [],
    this.totalStartupDuration,
    this.timeToFirstFrame,
    this.isAvailable = false,
  });

  bool get hasData =>
      phases.any((p) => p.hasData) || totalStartupDuration != null;

  @override
  List<Object?> get props =>
      [phases, totalStartupDuration, timeToFirstFrame, isAvailable];
}
