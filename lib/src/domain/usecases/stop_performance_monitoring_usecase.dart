import '../repositories/performance_repository.dart';
import '../../core/usecases/usecase.dart';

class StopPerformanceMonitoringUseCase implements UseCase<void, NoParams> {
  final PerformanceRepository repository;

  const StopPerformanceMonitoringUseCase(this.repository);

  @override
  Future<void> call(NoParams params) {
    repository.stopMonitoring();
    return Future.value();
  }
}
