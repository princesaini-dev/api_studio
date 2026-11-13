import 'dart:async';

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
      final entities = models.map((m) => m.toEntity()).toList();
      if (!params.includeBodies || !dataSource.storesBodiesSeparately) {
        return entities;
      }
      return [for (final e in entities) await _withBodies(e)];
    } on StorageException catch (e) {
      throw StorageFailure(e.message);
    }
  }

  @override
  Future<ApiLogEntity?> getLogById(String id) async {
    try {
      final model = await dataSource.getLogById(id);
      if (model == null) return null;
      final entity = model.toEntity();
      return dataSource.storesBodiesSeparately
          ? await _withBodies(entity)
          : entity;
    } on StorageException catch (e) {
      throw StorageFailure(e.message);
    }
  }

  Future<ApiLogEntity> _withBodies(ApiLogEntity entity) async {
    final bodies = await dataSource.loadBodies(entity.id);
    return entity.copyWith(
      requestBody: bodies.request,
      responseBody: bodies.response,
    );
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

  /// Emits the newest page of logs after storage changes.
  ///
  /// Bursts of writes (e.g. 30 parallel requests finishing together) are
  /// coalesced into a single query instead of re-reading and re-sorting the
  /// whole box once per write.
  @override
  Stream<List<ApiLogEntity>> watchLogs() {
    late StreamController<List<ApiLogEntity>> controller;
    StreamSubscription<dynamic>? sub;
    Timer? pending;

    Future<void> emit() async {
      pending = null;
      try {
        final models =
            await dataSource.getLogs(const GetLogsParams(includeBodies: false));
        if (!controller.isClosed) {
          controller.add(models.map((m) => m.toEntity()).toList());
        }
      } catch (_) {}
    }

    controller = StreamController<List<ApiLogEntity>>(
      onListen: () {
        sub = dataSource.watchBox().listen((_) {
          pending ??= Timer(watchCoalesceWindow, () => unawaited(emit()));
        });
      },
      onPause: () => sub?.pause(),
      onResume: () => sub?.resume(),
      onCancel: () async {
        pending?.cancel();
        await sub?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  /// Window in which consecutive storage events are merged by [watchLogs].
  static const Duration watchCoalesceWindow = Duration(milliseconds: 100);
}
