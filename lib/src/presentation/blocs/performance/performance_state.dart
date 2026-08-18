import 'package:equatable/equatable.dart';

import '../../../domain/entities/performance_snapshot.dart';

enum PerformanceStatus { initial, monitoring, recording, stopped }

class PerformanceState extends Equatable {
  final PerformanceStatus status;
  final PerformanceSnapshot snapshot;

  const PerformanceState({
    this.status = PerformanceStatus.initial,
    this.snapshot = const PerformanceSnapshot(),
  });

  PerformanceState copyWith({
    PerformanceStatus? status,
    PerformanceSnapshot? snapshot,
  }) {
    return PerformanceState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
    );
  }

  @override
  List<Object?> get props => [status, snapshot];
}
