import 'package:flutter/material.dart';
import 'notification/config/notification_config.dart';
import 'services/di_service.dart';
import 'presentation/screens/inspector_list_screen.dart';
import 'presentation/screens/file_explorer_screen.dart';
import 'presentation/screens/performance_inspector_screen.dart';
import 'theme/api_inspector_theme.dart';
import 'theme/api_inspector_theme_data.dart';
import 'api_client/client/api_studio_client.dart';
import 'api_client/core/api_studio_remote_logger.dart';
import 'api_client/core/api_studio_performance_uploader.dart';
import 'services/performance_monitor.dart';
import 'domain/entities/performance_snapshot.dart';

class ApiStudio {
  ApiStudio._();

  static ApiInspectorThemeData _themeData = const ApiInspectorThemeData();

  /// Initialises API Studio, optionally enabling automatic API execution
  /// logging to the API Studio backend.
  ///
  /// ```dart
  /// ApiStudio.initialize(
  ///   apiKey: "YOUR_API_KEY", // Optional
  /// );
  /// ```
  ///
  /// [apiKey] is optional. When it is `null` or empty, automatic remote
  /// logging is completely disabled and the package behaves exactly as
  /// before — no exceptions are thrown either way.
  ///
  /// [enablePerformanceMonitoring] opts in to aggregated performance
  /// telemetry upload (`POST /api/v1/performance`), using the same
  /// [apiKey] and backend already used for API logs. It defaults to
  /// `false`: unless explicitly set to `true`, no performance network
  /// request is ever made. When enabled, at most one aggregated snapshot
  /// is uploaded per hour — see [PerformanceTelemetryUploader].
  static Future<void> initialize({
    String? apiKey,
    ApiInspectorThemeData? theme,
    int? maxStoredLogs,
    Duration? requestTimeout,
    bool enableConnectivityStream = false,
    bool enableFailedApiStream = false,
    bool enablePerformanceMonitoring = false,
    NotificationConfig? notificationConfig,
  }) async {
    try {
      ApiStudioRemoteLogger.configure(apiKey);
    } catch (_) {
      // Never let logging setup affect app startup.
    }
    await init(
      theme: theme,
      maxStoredLogs: maxStoredLogs,
      requestTimeout: requestTimeout,
      enableConnectivityStream: enableConnectivityStream,
      enableFailedApiStream: enableFailedApiStream,
      notificationConfig: notificationConfig,
    );
    try {
      PerformanceTelemetryUploader.configure(
        apiKey: apiKey,
        enabled: enablePerformanceMonitoring,
      );
      if (enablePerformanceMonitoring) {
        PerformanceMonitor.instance.start();
      }
    } catch (_) {
      // Never let performance telemetry setup affect app startup.
    }
  }

  static Future<void> init({
    ApiInspectorThemeData? theme,
    int? maxStoredLogs,
    Duration? requestTimeout,
    bool enableConnectivityStream = false,
    bool enableFailedApiStream = false,
    NotificationConfig? notificationConfig,
  }) async {
    if (theme != null) _themeData = theme;
    await DiService.init(
      maxStoredLogs: maxStoredLogs,
      requestTimeout: requestTimeout,
      enableConnectivityStream: enableConnectivityStream,
      enableFailedApiStream: enableFailedApiStream,
      notificationConfig: notificationConfig,
    );
  }

  /// Initialises [ApiStudioClient] with the given [baseUrl] and optional
  /// [config]. Call this after [ApiStudio.init].
  ///
  /// ```dart
  /// await ApiStudio.init(...);
  /// ApiStudio.initClient(baseUrl: 'https://api.example.com');
  /// // Then use: ApiStudioClient.instance.get(...)
  /// ```
  static void initClient({
    required String baseUrl,
    Duration timeout = const Duration(seconds: 30),
    Map<String, String> defaultHeaders = const {},
    ClientConfig? config,
  }) {
    ApiStudioClient.initialize(
      baseUrl: baseUrl,
      timeout: timeout,
      defaultHeaders: defaultHeaders,
      config: config,
    );
  }

  static Future<bool> isInternetConnected() => DiService.isInternetAvailable;

  static Stream<bool> get internetConnectivityStream =>
      DiService.internetConnectivityStream;

  static int get failedApiCount => DiService.failedApiCount;

  static Stream<int> get failedApiCountStream => DiService.failedApiCountStream;

  static void show(
    BuildContext context, {
    ApiInspectorThemeData? theme,
  }) {
    final effectiveTheme = theme ?? _themeData;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => ApiInspectorTheme(
          data: effectiveTheme,
          child: const InspectorListScreen(),
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  static void showFileExplorer(
    BuildContext context, {
    ApiInspectorThemeData? theme,
  }) {
    final effectiveTheme = theme ?? _themeData;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => ApiInspectorTheme(
          data: effectiveTheme,
          child: const FileExplorerScreen(),
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  /// Opens the Performance Inspector as a full-screen page.
  ///
  /// ```dart
  /// ApiStudio.showPerformanceInspector(context);
  /// ```
  static void showPerformanceInspector(
    BuildContext context, {
    ApiInspectorThemeData? theme,
  }) {
    final effectiveTheme = theme ?? _themeData;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => ApiInspectorTheme(
          data: effectiveTheme,
          child: const PerformanceInspectorScreen(),
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  // ── Performance Monitoring API ─────────────────────────────────────

  /// Starts performance monitoring (frame timings, memory polling).
  static void startPerformanceMonitoring() =>
      PerformanceMonitor.instance.start();

  /// Stops performance monitoring.
  static void stopPerformanceMonitoring() => PerformanceMonitor.instance.stop();

  /// A broadcast stream of [PerformanceSnapshot] updates.
  static Stream<PerformanceSnapshot> get performanceStream =>
      PerformanceMonitor.instance.snapshotStream;
}
