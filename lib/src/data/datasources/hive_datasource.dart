import 'package:hive_ce/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/repositories/api_log_repository.dart';
import '../models/api_log_hive_model.dart';
import 'hive_storage.dart';

abstract class ApiLogLocalDataSource {
  Future<List<ApiLogHiveModel>> getLogs(GetLogsParams params);
  Future<ApiLogHiveModel?> getLogById(String id);
  Future<void> saveLog(ApiLogHiveModel model);
  Future<void> updateLog(ApiLogHiveModel model);
  Future<void> deleteLog(String id);
  Future<void> clearAllLogs();
  Future<int> getTotalCount();
  Stream<BoxEvent> watchBox();

  /// Loads the bodies of log [id]. Models returned by [getLogs] and
  /// [getLogById] carry no bodies when a body box is in use.
  Future<({String? request, String? response})> loadBodies(String id);

  /// Whether bodies live outside the models (see [loadBodies]).
  bool get storesBodiesSeparately;

  /// Applies the retention policy. Returns the number of logs removed.
  Future<int> prune();
}

class HiveApiLogDataSource implements ApiLogLocalDataSource {
  final Box<ApiLogHiveModel> _box;

  /// Bodies, keyed `<id>/q` (request) and `<id>/s` (response). `null`
  /// keeps bodies inline in [_box] (used by tests and as a fallback).
  final LazyBox<String>? _bodies;

  /// Maximum number of logs kept. Oldest logs are removed first.
  final int maxStoredLogs;

  /// Logs older than this are removed. [Duration.zero] disables age-based
  /// pruning.
  final Duration retention;

  /// Upper bound on the combined (approximate) size of stored bodies.
  final int maxStorageBytes;

  final DateTime Function() _clock;

  int _approxBytes = 0;
  DateTime? _lastPrune;

  static const Duration _agePruneInterval = Duration(minutes: 1);

  HiveApiLogDataSource(
    this._box, {
    LazyBox<String>? bodies,
    this.maxStoredLogs = AppConstants.maxStoredLogs,
    this.retention = AppConstants.logRetention,
    this.maxStorageBytes = AppConstants.maxStorageBytes,
    DateTime Function()? clock,
  })  : _bodies = bodies,
        _clock = clock ?? DateTime.now {
    _approxBytes = _box.values.fold(0, (s, m) => s + m.approximateSizeBytes);
  }

  /// Opens (and migrates, if needed) the log box and the body box.
  static Future<({Box<ApiLogHiveModel> logs, LazyBox<String>? bodies})>
      openBoxes() => LogStorageMigrator.openLogsBoxes();

  static String requestBodyKey(String id) => '$id/q';
  static String responseBodyKey(String id) => '$id/s';

  @override
  bool get storesBodiesSeparately => _bodies != null;

  @override
  Future<({String? request, String? response})> loadBodies(String id) async {
    final bodies = _bodies;
    if (bodies == null) {
      final m = _box.get(id);
      return (request: m?.requestBody, response: m?.responseBody);
    }
    try {
      return (
        request: await bodies.get(requestBodyKey(id)),
        response: await bodies.get(responseBodyKey(id)),
      );
    } catch (e) {
      throw StorageException('Failed to load log bodies: $e');
    }
  }

  Future<void> _deleteBodies(Iterable<String> ids) async {
    final bodies = _bodies;
    if (bodies == null || ids.isEmpty) return;
    await bodies.deleteAll([
      for (final id in ids) ...[requestBodyKey(id), responseBodyKey(id)],
    ]);
  }

  /// Moves the bodies of [model] into the body box (if any) and returns the
  /// model that should be stored in the main box.
  Future<ApiLogHiveModel> _externalize(ApiLogHiveModel model) async {
    final bodies = _bodies;
    if (bodies == null) return model;
    final req = model.requestBody;
    final res = model.responseBody;
    final reqKey = requestBodyKey(model.id);
    final resKey = responseBodyKey(model.id);
    if (req != null) {
      await bodies.put(reqKey, req);
    } else {
      await bodies.delete(reqKey);
    }
    if (res != null) {
      await bodies.put(resKey, res);
    } else {
      await bodies.delete(resKey);
    }
    return model
      ..requestBodyLength = req?.length
      ..responseBodyLength = res?.length
      ..requestBody = null
      ..responseBody = null;
  }

  @override
  Future<int> prune() async {
    _lastPrune = _clock();
    final models = _box.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    var remaining = models.length;
    var bytes = models.fold<int>(0, (s, m) => s + m.approximateSizeBytes);
    final now = _clock();
    final keys = <dynamic>[];
    final ids = <String>[];
    for (final m in models) {
      final expired =
          retention > Duration.zero && now.difference(m.timestamp) > retention;
      if (!expired && remaining <= maxStoredLogs && bytes <= maxStorageBytes) {
        break;
      }
      keys.add(m.key);
      ids.add(m.id);
      remaining--;
      bytes -= m.approximateSizeBytes;
    }
    if (keys.isNotEmpty) {
      await _box.deleteAll(keys);
      await _deleteBodies(ids);
    }
    _approxBytes = bytes;
    return keys.length;
  }

  bool get _needsPrune {
    if (_box.length > maxStoredLogs || _approxBytes > maxStorageBytes) {
      return true;
    }
    final last = _lastPrune;
    return retention > Duration.zero &&
        (last == null || _clock().difference(last) > _agePruneInterval);
  }

  @override
  Future<List<ApiLogHiveModel>> getLogs(GetLogsParams params) async {
    try {
      var all = _box.values.toList();

      if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
        final q = params.searchQuery!.toLowerCase();
        all = all
            .where((m) =>
                m.url.toLowerCase().contains(q) ||
                m.method == q ||
                (m.statusCode?.toString() == q))
            .toList();
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
      // Logs are keyed by id, so this is an O(1) lookup. The scan is only a
      // fallback for records whose key and id ever diverged.
      final direct = _box.get(id);
      if (direct != null) return direct;
      for (final m in _box.values) {
        if (m.id == id) return m;
      }
      return null;
    } catch (e) {
      throw StorageException('Failed to get log: $e');
    }
  }

  @override
  Future<void> saveLog(ApiLogHiveModel model) async {
    try {
      model = await _externalize(model);
      await _box.put(model.id, model);
      _approxBytes += model.approximateSizeBytes;
      if (_needsPrune) await prune();
    } catch (e) {
      throw StorageException('Failed to save log: $e');
    }
  }

  @override
  Future<void> updateLog(ApiLogHiveModel model) async {
    try {
      final previous = _box.get(model.id);
      model = await _externalize(model);
      await _box.put(model.id, model);
      _approxBytes +=
          model.approximateSizeBytes - (previous?.approximateSizeBytes ?? 0);
    } catch (e) {
      throw StorageException('Failed to update log: $e');
    }
  }

  @override
  Future<void> deleteLog(String id) async {
    try {
      final existing = _box.get(id);
      await _box.delete(id);
      await _deleteBodies([id]);
      if (existing != null) {
        _approxBytes -= existing.approximateSizeBytes;
        if (_approxBytes < 0) _approxBytes = 0;
      }
    } catch (e) {
      throw StorageException('Failed to delete log: $e');
    }
  }

  @override
  Future<void> clearAllLogs() async {
    try {
      await _box.clear();
      await _bodies?.clear();
      _approxBytes = 0;
    } catch (e) {
      throw StorageException('Failed to clear logs: $e');
    }
  }

  @override
  Future<int> getTotalCount() async => _box.length;

  @override
  Stream<BoxEvent> watchBox() => _box.watch();
}
