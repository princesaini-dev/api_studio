import '../repositories/performance_repository.dart';
import '../../core/usecases/usecase.dart';

class ClearPerformanceSessionUseCase implements UseCase<void, NoParams> {
  final PerformanceRepository repository;

  const ClearPerformanceSessionUseCase(this.repository);

  @override
  Future<void> call(NoParams params) {
    repository.clearSession();
    return Future.value();
  }
}
