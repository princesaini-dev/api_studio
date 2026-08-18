import '../repositories/performance_repository.dart';
import '../../core/usecases/usecase.dart';

class StartPerformanceMonitoringUseCase implements UseCase<void, NoParams> {
  final PerformanceRepository repository;

  const StartPerformanceMonitoringUseCase(this.repository);

  @override
  Future<void> call(NoParams params) {
    repository.startMonitoring();
    return Future.value();
  }
}
