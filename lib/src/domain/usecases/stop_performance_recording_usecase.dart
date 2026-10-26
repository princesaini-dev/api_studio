import '../../core/usecases/usecase.dart';
import '../repositories/performance_repository.dart';

class StopPerformanceRecordingUseCase implements UseCase<void, NoParams> {
  final PerformanceRepository repository;

  const StopPerformanceRecordingUseCase(this.repository);

  @override
  Future<void> call(NoParams params) {
    repository.stopRecording();
    return Future.value();
  }
}
