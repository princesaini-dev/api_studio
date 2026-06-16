import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/api_log_entity.dart';
import '../../domain/repositories/api_log_repository.dart';
import '../datasources/hive_datasource.dart';
import '../models/api_log_hive_model.dart';

class ApiLogRepositoryImpl implements ApiLogRepository {
  final ApiLogLocalDataSource dataSource;

  const ApiLogRepositoryImpl(this.dataSource);

  @override
  Future<List<ApiLogEntity>> getLogs(GetLogsParams params) async {
    try {
      final models = await dataSource.getLogs(params);
      return models.map((m) => m.toEntity()).toList();
    } on StorageException catch (e) {
      throw StorageFailure(e.message);
    }
  }

  @override
  Future<ApiLogEntity?> getLogById(String id) async {
    try {
      final model = await dataSource.getLogById(id);
      return model?.toEntity();
    } on StorageException catch (e) {
      throw StorageFailure(e.message);
    }
  }

  @override
  Future<void> saveLog(ApiLogEntity log) async {
    try {
      final model = ApiLogHiveModel.fromEntity(log);
      await dataSource.saveLog(model);
    } on StorageException catch (e) {
      throw StorageFailure(e.message);
    }
  }

  @override
  Future<void> updateLog(ApiLogEntity log) async {
    try {
      final model = ApiLogHiveModel.fromEntity(log);
      await dataSource.updateLog(model);
    } on StorageException catch (e) {
      throw StorageFailure(e.message);
    }
  }

  @override
  Future<void> deleteLog(String id) async {
    try {
      await dataSource.deleteLog(id);
    } on StorageException catch (e) {
      throw StorageFailure(e.message);
    }
  }

  @override
  Future<void> clearAllLogs() async {
    try {
      await dataSource.clearAllLogs();
    } on StorageException catch (e) {
      throw StorageFailure(e.message);
    }
  }

  @override
  Future<int> getTotalCount() async {
    return dataSource.getTotalCount();
  }

  @override
  Stream<List<ApiLogEntity>> watchLogs() {
    return dataSource.watchBox().asyncMap((_) async {
      final models = await dataSource.getLogs(const GetLogsParams());
      return models.map((m) => m.toEntity()).toList();
    });
  }
}
