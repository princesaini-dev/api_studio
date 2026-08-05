class AppConstants {
  AppConstants._();

  static const String packageName = 'api_studio';
  static const String packageVersion = '1.0.0';
  static const int defaultPageSize = 20;
  static const int maxStoredLogs = 10000;
  static const Duration requestTimeout = Duration(seconds: 30);
  static const String editedBadgeLabel = 'EDITED';
  static const String editedRequestSuffix = '_edited';

  /// Dedicated backend used ONLY for API Studio's own automatic logging.
  /// Never used for user requests.
  static const String apiStudioBaseUrl =
      'https://api-studio-backend-345113340482.asia-south1.run.app';

  /// Endpoint that automatic API execution logs are POSTed to.
  static const String apiStudioLogsPath = '/api/v1/logs';

  static String get apiStudioLogsUrl => '$apiStudioBaseUrl$apiStudioLogsPath';
}
