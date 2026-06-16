import '../entities/api_log_entity.dart';
import '../repositories/api_log_repository.dart';
import '../../core/usecases/usecase.dart';

class SaveLogUseCase implements UseCase<void, ApiLogEntity> {
  final ApiLogRepository repository;

  const SaveLogUseCase(this.repository);

  @override
  Future<void> call(ApiLogEntity params) {
    return repository.saveLog(params);
  }
}
