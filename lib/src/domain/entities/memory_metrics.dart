import 'package:equatable/equatable.dart';

enum MemoryTrend { stable, growing, decreasing, unknown }

class MemoryMetrics extends Equatable {
  final int? currentUsageBytes;
  final int? peakUsageBytes;
  final int? minUsageBytes;
  final int? growthBytes;
  final MemoryTrend trend;
  final int? sessionChangeBytes;
  final bool isAvailable;

  const MemoryMetrics({
    this.currentUsageBytes,
    this.peakUsageBytes,
    this.minUsageBytes,
    this.growthBytes,
    this.trend = MemoryTrend.unknown,
    this.sessionChangeBytes,
    this.isAvailable = false,
  });

  bool get hasData => currentUsageBytes != null;

  MemoryMetrics copyWith({
    int? currentUsageBytes,
    int? peakUsageBytes,
    int? minUsageBytes,
    int? growthBytes,
    MemoryTrend? trend,
    int? sessionChangeBytes,
    bool? isAvailable,
  }) {
    return MemoryMetrics(
      currentUsageBytes: currentUsageBytes ?? this.currentUsageBytes,
      peakUsageBytes: peakUsageBytes ?? this.peakUsageBytes,
      minUsageBytes: minUsageBytes ?? this.minUsageBytes,
      growthBytes: growthBytes ?? this.growthBytes,
      trend: trend ?? this.trend,
      sessionChangeBytes: sessionChangeBytes ?? this.sessionChangeBytes,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  List<Object?> get props => [
        currentUsageBytes,
        peakUsageBytes,
        minUsageBytes,
        growthBytes,
        trend,
        sessionChangeBytes,
        isAvailable,
      ];
}
