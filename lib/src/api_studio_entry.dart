import 'package:flutter/material.dart';
import 'notification/config/notification_config.dart';
import 'services/di_service.dart';
import 'presentation/screens/api_studio_navigation_screen.dart';
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
  static bool _isInitialized = false;
  static bool _enableApiClient = true;
  static String? _baseUrl;

  /// Whether [initialize] has been called at least once.
  static bool get isInitialized => _isInitialized;

  /// Whether the built-in API Client was enabled during [initialize].
  static bool get isApiClientEnabled => _enableApiClient;

  /// The base URL configured via [initialize], or `null` if none was
  /// provided (or [isApiClientEnabled] is `false`).
  static String? get configuredBaseUrl => _baseUrl;

  /// Single, unified entry point that configures every API Studio feature —
  /// API key / remote logging, backend base URL, the built-in API Client,
  /// connectivity & failed-API monitoring and performance telemetry — in one
  /// call.
  ///
  /// ```dart
  /// void main() {
  ///   ApiStudio.initialize(
  ///     apiKey: 'YOUR_API_KEY',
  ///     baseUrl: 'https://api.example.com',
  ///     enableApiClient: true,
  ///   );
  ///   runApp(const MyApp());
  /// }
  /// ```
  ///
  /// [apiKey] is optional. When it is `null` or empty, automatic remote
  /// logging is completely disabled and the package behaves exactly as
  /// before — no exceptions are thrown either way.
  ///
  /// [baseUrl] configures the base URL used by the built-in [ApiStudioClient]
  /// (`ApiStudioClient.instance`). It is ignored when [enableApiClient] is
  /// `false`. An empty/blank [baseUrl] is treated as "not provided" — the
  /// client is simply left uninitialized, no exception is thrown.
  ///
  /// [enableApiClient] controls whether the built-in HTTP client
  /// (`ApiStudioClient`) is wired up at all. Defaults to `true` for backward
  /// compatibility. When `false`, no client controller, logger or network
  /// service is created for it — API Logs and Performance keep working
  /// normally since they don't depend on the client being enabled.
  ///
  /// [enablePerformanceMonitoring] opts in to aggregated performance
  /// telemetry upload (`POST /api/v1/performance`), using the same [apiKey]
  /// and backend already used for API logs. It defaults to `false`: unless
  /// explicitly set to `true`, no performance network request is ever made.
  /// When enabled, at most one aggregated snapshot is uploaded per hour —
  /// see [PerformanceTelemetryUploader].
  ///
  /// Calling [initialize] more than once is safe (idempotent): the latest
  /// [apiKey], [baseUrl] and [enableApiClient] values are applied, while
  /// one-time setup (local storage, blocs wiring) only ever runs once.
  static Future<void> initialize({
    String? apiKey,
    String? baseUrl,
    bool enableApiClient = true,
    ApiInspectorThemeData? theme,
    int? maxStoredLogs,
    Duration? requestTimeout,
    bool enableConnectivityStream = false,
    bool enableFailedApiStream = false,
    bool enablePerformanceMonitoring = false,
    NotificationConfig? notificationConfig,
    Duration clientTimeout = const Duration(seconds: 30),
    Map<String, String> clientDefaultHeaders = const {},
    ClientConfig? clientConfig,
  }) async {
    final effectiveApiKey =
        (apiKey != null && apiKey.trim().isNotEmpty) ? apiKey : null;
    final effectiveBaseUrl =
        (baseUrl != null && baseUrl.trim().isNotEmpty) ? baseUrl : null;

    if (baseUrl != null && baseUrl.trim().isEmpty) {
      debugPrint(
        '[ApiStudio] initialize() received an empty baseUrl — ignoring it. '
        'ApiStudioClient will remain uninitialized until a valid baseUrl is provided.',
      );
    }

    _enableApiClient = enableApiClient;
    _baseUrl = effectiveBaseUrl;

    try {
      ApiStudioRemoteLogger.configure(effectiveApiKey);
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
      enableApiClient: enableApiClient,
    );

    if (enableApiClient && effectiveBaseUrl != null) {
      try {
        ApiStudioClient.initialize(
          baseUrl: effectiveBaseUrl,
          timeout: clientTimeout,
          defaultHeaders: clientDefaultHeaders,
          config: clientConfig,
        );
      } catch (_) {
        // Never let client setup affect app startup.
      }
    }

    try {
      PerformanceTelemetryUploader.configure(
        apiKey: effectiveApiKey,
        enabled: enablePerformanceMonitoring,
      );
      if (enablePerformanceMonitoring) {
        PerformanceMonitor.instance.start();
      }
    } catch (_) {
      // Never let performance telemetry setup affect app startup.
    }

    _isInitialized = true;
  }

  static Future<void> init({
    ApiInspectorThemeData? theme,
    int? maxStoredLogs,
    Duration? requestTimeout,
    bool enableConnectivityStream = false,
    bool enableFailedApiStream = false,
    NotificationConfig? notificationConfig,
    bool enableApiClient = true,
  }) async {
    if (theme != null) _themeData = theme;
    await DiService.init(
      maxStoredLogs: maxStoredLogs,
      requestTimeout: requestTimeout,
      enableConnectivityStream: enableConnectivityStream,
      enableFailedApiStream: enableFailedApiStream,
      notificationConfig: notificationConfig,
      enableApiClient: enableApiClient,
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
  @Deprecated(
    'Use ApiStudio.initialize(baseUrl: ..., enableApiClient: true) instead. '
    'This method is kept for backward compatibility and will be removed in a future release.',
  )
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

  /// Opens the unified API Studio container — [ApiStudioNavigationScreen] —
  /// with API Logs, Performance and File Explorer accessible through a
  /// single floating bottom navigation bar.
  ///
  /// This is the recommended way to open API Studio:
  ///
  /// ```dart
  /// ApiStudio.showNavigation(context);
  /// ```
  ///
  /// [initialIndex] selects which tab is shown first (`0` = Logs,
  /// `1` = Performance, `2` = Files). Defaults to Logs.
  ///
  /// [ApiStudio.initialize] should be called before this, typically in
  /// `main()`. If it wasn't, a debug-mode assertion fires to help catch the
  /// mistake early, but the navigation screen still opens — required
  /// services are created lazily by each feature screen regardless.
  static void showNavigation(
    BuildContext context, {
    ApiInspectorThemeData? theme,
    int initialIndex = 0,
  }) {
    assert(() {
      if (!_isInitialized) {
        debugPrint(
          '[ApiStudio] showNavigation() was called before ApiStudio.initialize(). '
          'Call ApiStudio.initialize(...) in main() first.',
        );
      }
      return true;
    }());

    final effectiveTheme = theme ?? _themeData;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => ApiInspectorTheme(
          data: effectiveTheme,
          child: ApiStudioNavigationScreen(initialIndex: initialIndex),
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
