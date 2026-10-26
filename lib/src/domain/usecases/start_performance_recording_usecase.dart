import '../../core/usecases/usecase.dart';
import '../repositories/performance_repository.dart';

class StartPerformanceRecordingUseCase implements UseCase<void, NoParams> {
  final PerformanceRepository repository;

  const StartPerformanceRecordingUseCase(this.repository);

  @override
  Future<void> call(NoParams params) {
    repository.startRecording();
    return Future.value();
  }
}
