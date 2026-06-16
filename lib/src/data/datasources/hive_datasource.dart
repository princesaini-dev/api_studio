import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/hive_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/repositories/api_log_repository.dart';
import '../models/api_log_hive_model.dart';

abstract class ApiLogLocalDataSource {
  Future<List<ApiLogHiveModel>> getLogs(GetLogsParams params);
  Future<ApiLogHiveModel?> getLogById(String id);
  Future<void> saveLog(ApiLogHiveModel model);
  Future<void> updateLog(ApiLogHiveModel model);
  Future<void> deleteLog(String id);
  Future<void> clearAllLogs();
  Future<int> getTotalCount();
  Stream<BoxEvent> watchBox();
}

class HiveApiLogDataSource implements ApiLogLocalDataSource {
  final Box<ApiLogHiveModel> _box;

  HiveApiLogDataSource(this._box);

  static Future<Box<ApiLogHiveModel>> openBox() async {
    return Hive.openBox<ApiLogHiveModel>(HiveConstants.apiLogBoxName);
  }

  @override
  Future<List<ApiLogHiveModel>> getLogs(GetLogsParams params) async {
    try {
      var all = _box.values.toList();

      if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
        final q = params.searchQuery!.toLowerCase();
        all = all.where((m) => m.url.toLowerCase().contains(q)).toList();
      }

      if (params.methodFilter != MethodFilter.all) {
        final methodName = params.methodFilter.name;
        all = all.where((m) => m.method == methodName).toList();
      }

      if (params.statusFilter != StatusFilter.all) {
        if (params.statusFilter == StatusFilter.success) {
          all = all.where((m) {
            final code = m.statusCode ?? 0;
            return code >= 200 && code < 400;
          }).toList();
        } else {
          all = all.where((m) {
            final code = m.statusCode ?? 0;
            return code == 0 || code >= 400;
          }).toList();
        }
      }

      all = _sort(all, params.sortOrder);

      final start = params.page * params.pageSize;
      if (start >= all.length) return [];
      return all.skip(start).take(params.pageSize).toList();
    } catch (e) {
      throw StorageException('Failed to retrieve logs: $e');
    }
  }

  List<ApiLogHiveModel> _sort(List<ApiLogHiveModel> list, SortOrder order) {
    switch (order) {
      case SortOrder.newest:
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      case SortOrder.oldest:
        list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      case SortOrder.duration:
        list.sort((a, b) => (b.durationMs ?? 0).compareTo(a.durationMs ?? 0));
      case SortOrder.statusCode:
        list.sort((a, b) => (b.statusCode ?? 0).compareTo(a.statusCode ?? 0));
    }
    return list;
  }

  @override
  Future<ApiLogHiveModel?> getLogById(String id) async {
    try {
      return _box.values.cast<ApiLogHiveModel?>().firstWhere(
            (m) => m?.id == id,
            orElse: () => null,
          );
    } catch (e) {
      throw StorageException('Failed to get log: $e');
    }
  }

  @override
  Future<void> saveLog(ApiLogHiveModel model) async {
    try {
      if (_box.length >= AppConstants.maxStoredLogs) {
        final oldest = _box.values.reduce(
          (a, b) => a.timestamp.isBefore(b.timestamp) ? a : b,
        );
        await oldest.delete();
      }
      await _box.put(model.id, model);
    } catch (e) {
      throw StorageException('Failed to save log: $e');
    }
  }

  @override
  Future<void> updateLog(ApiLogHiveModel model) async {
    try {
      await _box.put(model.id, model);
    } catch (e) {
      throw StorageException('Failed to update log: $e');
    }
  }

  @override
  Future<void> deleteLog(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw StorageException('Failed to delete log: $e');
    }
  }

  @override
  Future<void> clearAllLogs() async {
    try {
      await _box.clear();
    } catch (e) {
      throw StorageException('Failed to clear logs: $e');
    }
  }

  @override
  Future<int> getTotalCount() async => _box.length;

  @override
  Stream<BoxEvent> watchBox() => _box.watch();
}
