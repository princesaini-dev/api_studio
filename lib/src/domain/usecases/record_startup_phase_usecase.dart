import '../repositories/performance_repository.dart';

class RecordStartupPhaseUseCase {
  final PerformanceRepository repository;

  const RecordStartupPhaseUseCase(this.repository);

  void call(String name, {Duration? duration}) =>
      repository.recordStartupPhase(name, duration: duration);
}
