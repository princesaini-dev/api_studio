import '../../core/usecases/usecase.dart';
import '../entities/api_log_entity.dart';
import '../repositories/api_log_repository.dart';

class SaveLogUseCase implements UseCase<void, ApiLogEntity> {
  final ApiLogRepository repository;

  const SaveLogUseCase(this.repository);

  @override
  Future<void> call(ApiLogEntity params) {
    return repository.saveLog(params);
  }
}
