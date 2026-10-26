/// Package-wide constants.
class AppConstants {
  AppConstants._();

  static const String packageName = 'api_studio';
  static const String packageVersion = '1.1.0';
  static const int defaultPageSize = 20;

  /// Default maximum number of logs kept in local storage. Oldest logs are
  /// pruned first.
  static const int maxStoredLogs = 500;

  /// Default age after which stored logs are pruned automatically.
  static const Duration logRetention = Duration(days: 7);

  /// Default per-body size limit (UTF-8 bytes). Larger request/response
  /// bodies are truncated and flagged as such.
  static const int defaultMaxBodyBytes = 1024 * 1024;

  /// Upper bound on the combined size of all stored bodies. When exceeded,
  /// the oldest logs are pruned so large payloads cannot bloat storage.
  static const int maxStorageBytes = 50 * 1024 * 1024;

  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration performanceRefreshInterval = Duration(seconds: 2);
  static const String editedBadgeLabel = 'EDITED';
  static const String editedRequestSuffix = '_edited';

  /// Dedicated backend used ONLY for API Studio's own automatic logging.
  /// Never used for user requests.
  static const String apiStudioBaseUrl =
      'https://api-studio-backend-345113340482.asia-south1.run.app';

  /// Endpoint that automatic API execution logs are POSTed to.
  static const String apiStudioLogsPath = '/api/v1/logs';

  static String get apiStudioLogsUrl => '$apiStudioBaseUrl$apiStudioLogsPath';

  /// Endpoint that aggregated performance telemetry is POSTed to.
  ///
  /// Uses the same [apiStudioBaseUrl] as [apiStudioLogsUrl] — performance
  /// telemetry never introduces a second base URL.
  static const String apiStudioPerformancePath = '/api/v1/performance';

  static String get apiStudioPerformanceUrl =>
      '$apiStudioBaseUrl$apiStudioPerformancePath';
}
