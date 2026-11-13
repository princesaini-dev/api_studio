/// Storage constants used by API Studio's local log persistence.
class HiveConstants {
  HiveConstants._();

  static const String apiLogBoxName = 'api_studio_logs';

  /// Lazy box holding request/response bodies (schema 3+). Bodies are only
  /// read from disk when a log is opened or exported, so hundreds of large
  /// responses no longer sit in the host app's memory.
  static const String apiLogBodiesBoxName = 'api_studio_log_bodies';
  static const int apiLogTypeId = 0;
  static const String hiveSubDir = 'api_studio';

  /// Box used to persist performance telemetry upload state so the
  /// once-per-hour upload interval survives app restarts.
  static const String performanceStateBoxName = 'api_studio_performance_state';
  static const String lastPerformanceUploadKey = 'lastPerformanceUploadAt';

  /// Box holding cloud-upload payloads that have not been accepted by the
  /// backend yet, so they survive app restarts and crashes.
  static const String uploadQueueBoxName = 'api_studio_upload_queue';

  /// Box holding storage metadata (schema version) used for migrations.
  static const String metaBoxName = 'api_studio_meta';
  static const String schemaVersionKey = 'schemaVersion';
}
