import '../../core/usecases/usecase.dart';
import '../repositories/performance_repository.dart';

class StopPerformanceMonitoringUseCase implements UseCase<void, NoParams> {
  final PerformanceRepository repository;

  const StopPerformanceMonitoringUseCase(this.repository);

  @override
  Future<void> call(NoParams params) {
    repository.stopMonitoring();
    return Future.value();
  }
}
