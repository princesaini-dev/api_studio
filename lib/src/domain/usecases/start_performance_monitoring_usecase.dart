import '../../core/usecases/usecase.dart';
import '../repositories/performance_repository.dart';

class StartPerformanceMonitoringUseCase implements UseCase<void, NoParams> {
  final PerformanceRepository repository;

  const StartPerformanceMonitoringUseCase(this.repository);

  @override
  Future<void> call(NoParams params) {
    repository.startMonitoring();
    return Future.value();
  }
}
