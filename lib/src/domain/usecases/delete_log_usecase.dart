import '../../core/usecases/usecase.dart';
import '../repositories/api_log_repository.dart';

class DeleteLogUseCase implements UseCase<void, String> {
  final ApiLogRepository repository;

  const DeleteLogUseCase(this.repository);

  @override
  Future<void> call(String id) {
    return repository.deleteLog(id);
  }
}
