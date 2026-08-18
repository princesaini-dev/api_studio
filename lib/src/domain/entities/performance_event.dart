import 'package:equatable/equatable.dart';

enum PerformanceEventType {
  appStarted,
  screenChanged,
  apiRequest,
  apiFailed,
  jankDetected,
  memoryUpdate,
  connectivityChanged,
  recordingStarted,
  recordingStopped,
  custom,
}

enum PerformanceEventSeverity { info, success, warning, error }

class PerformanceEvent extends Equatable {
  final DateTime timestamp;
  final PerformanceEventType type;
  final String description;
  final String? metricValue;
  final PerformanceEventSeverity severity;

  const PerformanceEvent({
    required this.timestamp,
    required this.type,
    required this.description,
    this.metricValue,
    this.severity = PerformanceEventSeverity.info,
  });

  @override
  List<Object?> get props =>
      [timestamp, type, description, metricValue, severity];
}
