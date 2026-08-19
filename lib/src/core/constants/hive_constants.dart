class HiveConstants {
  HiveConstants._();

  static const String apiLogBoxName = 'api_studio_logs';
  static const int apiLogTypeId = 0;
  static const String hiveSubDir = 'api_studio';

  /// Box used to persist performance telemetry upload state so the
  /// once-per-hour upload interval survives app restarts.
  static const String performanceStateBoxName = 'api_studio_performance_state';
  static const String lastPerformanceUploadKey = 'lastPerformanceUploadAt';
}
