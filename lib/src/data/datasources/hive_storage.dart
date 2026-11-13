import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/hive_constants.dart';
import '../../core/pipeline/log_pipeline.dart';
import '../models/api_log_hive_model.dart';
import 'hive_datasource.dart';

/// Thin wrapper around `hive_ce` that keeps API Studio's boxes in their own
/// directory (`<app documents>/api_studio`, identical to 1.0.x) without
/// calling the global `Hive.init`, so a host app that also uses `hive_ce`
/// keeps its own home directory untouched. Internal.
class ApiStudioHive {
  ApiStudioHive._();

  static Future<String?>? _directory;

  /// Directory holding API Studio's boxes, or `null` on the web (IndexedDB).
  static Future<String?> directory() => _directory ??= _resolveDirectory();

  static Future<String?> _resolveDirectory() async {
    if (kIsWeb) return null;
    final docs = await getApplicationDocumentsDirectory();
    return '${docs.path}/${HiveConstants.hiveSubDir}';
  }

  static void registerAdapters() {
    if (!Hive.isAdapterRegistered(HiveConstants.apiLogTypeId)) {
      Hive.registerAdapter(ApiLogHiveModelAdapter());
    }
  }

  static Future<Box<T>> openBox<T>(String name) async =>
      Hive.openBox<T>(name, path: await directory());

  static Future<LazyBox<T>> openLazyBox<T>(String name) async =>
      Hive.openLazyBox<T>(name, path: await directory());

  static Future<void> deleteBox(String name) async =>
      Hive.deleteBoxFromDisk(name, path: await directory());

  @visibleForTesting
  static void debugReset() => _directory = null;
}

/// Opens the API log box and upgrades data written by older versions.
///
/// * Schema 1 (API Studio ≤ 1.0.7, `hive` 2.x): bodies up to 64 KB and
///   **unredacted** headers/bodies. Migrating re-runs every stored log
///   through the current redaction + truncation pipeline.
/// * Schema 2 (1.1.0, `hive_ce`): bodies stored inline in the log box, so
///   every body was resident in memory.
/// * Schema 3 (1.2.0+): bodies live in a separate lazy box and are only read
///   when a log is opened or exported.
///
/// If the box cannot be opened at all (corrupt file, unknown type ids), it
/// is deleted and recreated — losing debug logs is preferable to crashing
/// the host app on startup. Internal.
class LogStorageMigrator {
  LogStorageMigrator._();

  static const int currentSchemaVersion = 3;

  /// Opens the log box and the lazy body box, migrating older data.
  ///
  /// If the body box cannot be opened, bodies stay inline (schema 2
  /// layout) rather than failing initialization.
  static Future<({Box<ApiLogHiveModel> logs, LazyBox<String>? bodies})>
      openLogsBoxes() async {
    final logs = await openLogsBox();
    LazyBox<String>? bodies;
    try {
      bodies = await _openBodiesBox();
      await moveBodiesOut(logs, bodies);
    } catch (e) {
      debugPrint('[ApiStudio] Body storage unavailable ($e); '
          'keeping bodies inline.');
      bodies = null;
    }
    return (logs: logs, bodies: bodies);
  }

  static Future<LazyBox<String>> _openBodiesBox() async {
    try {
      return await ApiStudioHive.openLazyBox<String>(
          HiveConstants.apiLogBodiesBoxName);
    } catch (_) {
      await ApiStudioHive.deleteBox(HiveConstants.apiLogBodiesBoxName);
      return ApiStudioHive.openLazyBox<String>(
          HiveConstants.apiLogBodiesBoxName);
    }
  }

  /// Schema 2 → 3: moves any inline bodies into [bodies]. Idempotent, so it
  /// also picks up bodies written inline after a body-box failure.
  static Future<void> moveBodiesOut(
      Box<ApiLogHiveModel> logs, LazyBox<String> bodies) async {
    var moved = 0;
    for (final key in logs.keys.toList()) {
      final model = logs.get(key);
      if (model == null) continue;
      final req = model.requestBody;
      final res = model.responseBody;
      if (req == null && res == null) continue;
      if (req != null) {
        await bodies.put(HiveApiLogDataSource.requestBodyKey(model.id), req);
      }
      if (res != null) {
        await bodies.put(HiveApiLogDataSource.responseBodyKey(model.id), res);
      }
      model
        ..requestBodyLength = req?.length
        ..responseBodyLength = res?.length
        ..requestBody = null
        ..responseBody = null;
      await logs.put(key, model);
      moved++;
    }
    if (moved > 0) await logs.compact();
  }

  static Future<Box<ApiLogHiveModel>> openLogsBox() async {
    Box<ApiLogHiveModel> box;
    try {
      box = await ApiStudioHive.openBox<ApiLogHiveModel>(
        HiveConstants.apiLogBoxName,
      );
    } catch (e) {
      debugPrint('[ApiStudio] Stored logs are unreadable ($e); '
          'clearing them and starting fresh.');
      await ApiStudioHive.deleteBox(HiveConstants.apiLogBoxName);
      box = await ApiStudioHive.openBox<ApiLogHiveModel>(
        HiveConstants.apiLogBoxName,
      );
    }
    try {
      await migrate(box);
    } catch (e) {
      debugPrint('[ApiStudio] Log migration failed ($e); clearing logs.');
      await box.clear();
    }
    return box;
  }

  static Future<void> migrate(Box<ApiLogHiveModel> box) async {
    final meta =
        await ApiStudioHive.openBox<dynamic>(HiveConstants.metaBoxName);
    final stored = meta.get(HiveConstants.schemaVersionKey);
    final version =
        stored is int ? stored : (box.isEmpty ? currentSchemaVersion : 1);

    if (version < 2) {
      for (final key in box.keys.toList()) {
        try {
          final model = box.get(key);
          if (model == null) continue;
          final upgraded = LogPipeline.prepare(model.toEntity());
          await box.put(key, ApiLogHiveModel.fromEntity(upgraded));
        } catch (_) {
          await box.delete(key);
        }
      }
      await box.compact();
    }

    if (stored != currentSchemaVersion) {
      await meta.put(HiveConstants.schemaVersionKey, currentSchemaVersion);
    }
  }
}
