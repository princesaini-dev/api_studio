import '../../core/usecases/usecase.dart';
import '../entities/api_log_entity.dart';
import '../repositories/api_log_repository.dart';

class GetLogsUseCase implements UseCase<List<ApiLogEntity>, GetLogsParams> {
  final ApiLogRepository repository;

  const GetLogsUseCase(this.repository);

  @override
  Future<List<ApiLogEntity>> call(GetLogsParams params) {
    return repository.getLogs(params);
  }
}
