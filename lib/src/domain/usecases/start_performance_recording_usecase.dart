import '../repositories/performance_repository.dart';
import '../../core/usecases/usecase.dart';

class StartPerformanceRecordingUseCase implements UseCase<void, NoParams> {
  final PerformanceRepository repository;

  const StartPerformanceRecordingUseCase(this.repository);

  @override
  Future<void> call(NoParams params) {
    repository.startRecording();
    return Future.value();
  }
}
