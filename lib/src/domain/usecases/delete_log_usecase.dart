import '../repositories/api_log_repository.dart';
import '../../core/usecases/usecase.dart';

class DeleteLogUseCase implements UseCase<void, String> {
  final ApiLogRepository repository;

  const DeleteLogUseCase(this.repository);

  @override
  Future<void> call(String id) {
    return repository.deleteLog(id);
  }
}
