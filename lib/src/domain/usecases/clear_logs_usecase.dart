import '../repositories/api_log_repository.dart';
import '../../core/usecases/usecase.dart';

class ClearLogsUseCase implements UseCase<void, NoParams> {
  final ApiLogRepository repository;

  const ClearLogsUseCase(this.repository);

  @override
  Future<void> call(NoParams params) {
    return repository.clearAllLogs();
  }
}
