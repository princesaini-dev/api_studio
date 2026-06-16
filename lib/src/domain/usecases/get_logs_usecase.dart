import '../entities/api_log_entity.dart';
import '../repositories/api_log_repository.dart';
import '../../core/usecases/usecase.dart';

class GetLogsUseCase implements UseCase<List<ApiLogEntity>, GetLogsParams> {
  final ApiLogRepository repository;

  const GetLogsUseCase(this.repository);

  @override
  Future<List<ApiLogEntity>> call(GetLogsParams params) {
    return repository.getLogs(params);
  }
}
