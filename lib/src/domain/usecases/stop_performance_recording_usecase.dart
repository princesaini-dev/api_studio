import '../repositories/performance_repository.dart';
import '../../core/usecases/usecase.dart';

class StopPerformanceRecordingUseCase implements UseCase<void, NoParams> {
  final PerformanceRepository repository;

  const StopPerformanceRecordingUseCase(this.repository);

  @override
  Future<void> call(NoParams params) {
    repository.stopRecording();
    return Future.value();
  }
}
