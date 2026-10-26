import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'api_client/client/api_studio_client.dart';
import 'api_client/core/api_studio_performance_uploader.dart';
import 'api_client/core/api_studio_remote_logger.dart';
import 'core/pipeline/log_entry_builder.dart';
import 'core/pipeline/log_pipeline.dart';
import 'core/redaction/redaction_config.dart';
import 'core/runtime/api_studio_runtime.dart';
import 'domain/entities/api_log_entity.dart';
import 'domain/entities/performance_snapshot.dart';
import 'notification/config/notification_config.dart';
import 'presentation/screens/api_studio_navigation_screen.dart';
import 'presentation/screens/file_explorer_screen.dart';
import 'presentation/screens/inspector_list_screen.dart';
import 'presentation/screens/performance_inspector_screen.dart';
import 'presentation/widgets/api_studio_floating_button.dart';
import 'services/connectivity_service.dart';
import 'services/di_service.dart';
import 'services/failed_api_count_service.dart';
import 'services/performance_monitor.dart';
import 'theme/api_inspector_theme.dart';
import 'theme/api_inspector_theme_data.dart';

/// Entry point for API Studio: configuration, capture and UI.
///
/// ```dart
/// await ApiStudio.initialize();
/// dio.interceptors.add(ApiStudioDioInterceptor()); // package:api_studio_dio
/// // anywhere:
/// ApiStudio.showNavigation(context);
/// ```
class ApiStudio {
  ApiStudio._();

  static ApiInspectorThemeData _themeData = const ApiInspectorThemeData();
  static bool _isInitialized = false;
  static bool _enableApiClient = true;
  static String? _baseUrl;
  static AppLifecycleListener? _lifecycleListener;
  static GlobalKey<NavigatorState>? _navigatorKey;
  static bool _isOpen = false;

  /// Whether [initialize] has been called at least once.
  static bool get isInitialized => _isInitialized;

  /// Whether API Studio is active: [initialize] has run with
  /// `enabled: true` (the default in debug builds).
  ///
  /// When `false`, every capture, storage, UI and upload API is a no-op.
  /// Integrations (`ApiStudioDioInterceptor`, `ApiStudioHttpClient`) check
  /// this first so disabled builds pay almost nothing.
  static bool get isEnabled => _isInitialized && ApiStudioRuntime.enabled;

  /// Whether the built-in API Client was enabled during [initialize].
  static bool get isApiClientEnabled => _enableApiClient;

  /// The base URL configured via [initialize], or `null` if none was
  /// provided (or [isApiClientEnabled] is `false`).
  static String? get configuredBaseUrl => _baseUrl;

  /// The active redaction configuration.
  static RedactionConfig get redaction => ApiStudioRuntime.redaction;

  /// Per-body size limit in UTF-8 bytes (see `initialize(maxBodyBytes:)`).
  /// Integrations use it to avoid buffering more than will be kept.
  static int get maxBodyBytes => ApiStudioRuntime.maxBodyBytes;

  /// Navigator key used by [open] and [showFloatingButton] when no
  /// [BuildContext] is available.
  ///
  /// Either hand this key to your app —
  /// `MaterialApp(navigatorKey: ApiStudio.navigatorKey)` — or pass your
  /// existing key via `ApiStudio.initialize(navigatorKey: ...)` (or assign
  /// it to this property).
  static GlobalKey<NavigatorState> get navigatorKey =>
      _navigatorKey ??= GlobalKey<NavigatorState>(debugLabel: 'ApiStudio');

  static set navigatorKey(GlobalKey<NavigatorState> key) => _navigatorKey = key;

  /// Single, unified entry point that configures every API Studio feature.
  ///
  /// ```dart
  /// Future<void> main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await ApiStudio.initialize(apiKey: 'YOUR_API_KEY'); // apiKey optional
  ///   runApp(const MyApp());
  /// }
  /// ```
  ///
  /// [enabled] is the master switch and defaults to [kDebugMode]. When it is
  /// `false` (e.g. release builds), nothing is initialized: no local
  /// storage, no timers, no frame callbacks, no network calls, and every
  /// public API becomes a cheap no-op. To use API Studio in a QA/profile
  /// build, pass `enabled: true` explicitly.
  ///
  /// [apiKey] is optional. When it is `null` or empty, remote logging to
  /// the API Studio cloud is completely disabled.
  ///
  /// [redaction] controls which headers, query parameters and JSON body
  /// keys are masked before anything is stored, uploaded or exported. The
  /// defaults are always applied unless you opt out — see [RedactionConfig].
  ///
  /// [maxStoredLogs] (default 500) and [logRetention] (default 7 days)
  /// bound local storage; older logs are pruned automatically.
  /// [maxBodyBytes] (default 1 MB) truncates oversized request/response
  /// bodies and marks them as truncated.
  ///
  /// [baseUrl] / [enableApiClient] configure the optional built-in
  /// [ApiStudioClient]. When [enableApiClient] is `false`, nothing
  /// client-related is created. If you use [ApiStudioClient] for real
  /// traffic, it is still initialized when [enabled] is `false` — it simply
  /// stops being logged.
  ///
  /// [enablePerformanceMonitoring] opts in to performance collection and
  /// aggregated telemetry upload (at most once per interval, requires
  /// [apiKey]). Defaults to `false`.
  ///
  /// [navigatorKey] lets [open] and [showFloatingButton] work without a
  /// [BuildContext].
  ///
  /// Calling [initialize] more than once is safe: the latest values are
  /// applied, while one-time setup (local storage) only runs once.
  static Future<void> initialize({
    bool? enabled,
    String? apiKey,
    String? baseUrl,
    bool enableApiClient = true,
    ApiInspectorThemeData? theme,
    int? maxStoredLogs,
    Duration? logRetention,
    int? maxBodyBytes,
    RedactionConfig? redaction,
    GlobalKey<NavigatorState>? navigatorKey,
    Duration? requestTimeout,
    bool enableConnectivityStream = false,
    bool enableFailedApiStream = false,
    bool enablePerformanceMonitoring = false,
    NotificationConfig? notificationConfig,
    Duration clientTimeout = const Duration(seconds: 30),
    Map<String, String> clientDefaultHeaders = const {},
    ClientConfig? clientConfig,
  }) async {
    final isOn = enabled ?? kDebugMode;
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
    if (theme != null) _themeData = theme;
    if (navigatorKey != null) _navigatorKey = navigatorKey;
    if (redaction != null) ApiStudioRuntime.redaction = redaction;
    if (maxBodyBytes != null) ApiStudioRuntime.maxBodyBytes = maxBodyBytes;

    if (!isOn) {
      _disable();
      _initClient(
          effectiveBaseUrl, clientTimeout, clientDefaultHeaders, clientConfig);
      _isInitialized = true;
      return;
    }

    ApiStudioRuntime.enabled = true;

    try {
      ApiStudioRemoteLogger.configure(effectiveApiKey);
    } catch (_) {
      // Never let logging setup affect app startup.
    }

    try {
      await DiService.init(
        maxStoredLogs: maxStoredLogs,
        logRetention: logRetention,
        requestTimeout: requestTimeout,
        enableConnectivityStream: enableConnectivityStream,
        enableFailedApiStream: enableFailedApiStream,
        notificationConfig: notificationConfig,
        enableApiClient: enableApiClient,
      );
    } catch (e) {
      debugPrint('[ApiStudio] Local storage unavailable: $e');
    }

    _initClient(
        effectiveBaseUrl, clientTimeout, clientDefaultHeaders, clientConfig);

    try {
      PerformanceTelemetryUploader.configure(
        apiKey: effectiveApiKey,
        enabled: enablePerformanceMonitoring,
      );
      if (enablePerformanceMonitoring) {
        PerformanceMonitor.instance.start();
      } else {
        PerformanceMonitor.instance.stopRecording();
        PerformanceMonitor.instance.stop();
      }
    } catch (_) {
      // Never let performance telemetry setup affect app startup.
    }

    try {
      _lifecycleListener?.dispose();
      _lifecycleListener = null;
      if (effectiveApiKey != null) {
        _lifecycleListener = AppLifecycleListener(
          onHide: () => unawaited(flush()),
          onPause: () => unawaited(flush()),
          onDetach: () => unawaited(flush()),
        );
      }
    } catch (_) {
      // Optional lifecycle binding in headless or test environments
    }

    _isInitialized = true;
  }

  static void _initClient(
    String? baseUrl,
    Duration timeout,
    Map<String, String> defaultHeaders,
    ClientConfig? config,
  ) {
    if (!_enableApiClient || baseUrl == null) return;
    try {
      ApiStudioClient.initialize(
        baseUrl: baseUrl,
        timeout: timeout,
        defaultHeaders: defaultHeaders,
        config: config,
      );
    } catch (_) {
      // Never let client setup affect app startup.
    }
  }

  /// Tears down every active subsystem without touching storage.
  static void _disable() {
    ApiStudioRuntime.enabled = false;
    try {
      ApiStudioRemoteLogger.configure(null);
      PerformanceTelemetryUploader.configure(apiKey: null, enabled: false);
      if (PerformanceMonitor.instance.isMonitoring) {
        PerformanceMonitor.instance.stop();
      }
      _lifecycleListener?.dispose();
      _lifecycleListener = null;
      hideFloatingButton();
    } catch (_) {}
  }

  /// Legacy initializer.
  @Deprecated(
    'Use ApiStudio.initialize(...) instead, which also supports the '
    '`enabled` master switch and redaction. Will be removed in 2.0.0.',
  )
  static Future<void> init({
    ApiInspectorThemeData? theme,
    int? maxStoredLogs,
    Duration? requestTimeout,
    bool enableConnectivityStream = false,
    bool enableFailedApiStream = false,
    NotificationConfig? notificationConfig,
    bool enableApiClient = true,
  }) =>
      initialize(
        theme: theme,
        maxStoredLogs: maxStoredLogs,
        requestTimeout: requestTimeout,
        enableConnectivityStream: enableConnectivityStream,
        enableFailedApiStream: enableFailedApiStream,
        notificationConfig: notificationConfig,
        enableApiClient: enableApiClient,
      );

  /// Initialises [ApiStudioClient] with the given [baseUrl] and optional
  /// [config].
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

  /// One-off internet reachability check. Works regardless of [isEnabled],
  /// since it returns real data your app may depend on.
  static Future<bool> isInternetConnected() => DiService.isInternetAvailable;

  /// Connectivity changes. Requires `enableConnectivityStream: true`.
  static Stream<bool> get internetConnectivityStream =>
      ConnectivityService.instance.stream;

  /// Number of failed API calls captured this session. Requires
  /// `enableFailedApiStream: true`.
  static int get failedApiCount =>
      FailedApiCountService.instance.failedApiCount;

  /// Stream of [failedApiCount] updates.
  static Stream<int> get failedApiCountStream =>
      FailedApiCountService.instance.stream;

  static bool _guardUi(String method) {
    if (isEnabled && DiService.isInitialized) return true;
    assert(() {
      debugPrint('[ApiStudio] $method() ignored: API Studio is '
          '${isEnabled ? 'not ready (storage failed to initialize)' : 'disabled or not initialized'}.');
      return true;
    }());
    return false;
  }

  static Future<void> _push(NavigatorState navigator, Widget child,
      ApiInspectorThemeData? theme) async {
    final effectiveTheme = theme ?? _themeData;
    _isOpen = true;
    try {
      await navigator.push(
        PageRouteBuilder<void>(
          pageBuilder: (_, __, ___) =>
              ApiInspectorTheme(data: effectiveTheme, child: child),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    } finally {
      _isOpen = false;
    }
  }

  /// Opens the API Inspector (logs list). No-op when disabled.
  static void show(
    BuildContext context, {
    ApiInspectorThemeData? theme,
  }) {
    if (!_guardUi('show')) return;
    unawaited(_push(Navigator.of(context), const InspectorListScreen(), theme));
  }

  /// Opens the read-only File Explorer. No-op when disabled.
  ///
  /// **Warning:** the File Explorer can browse and share files from your
  /// app's sandbox (databases, caches, tokens stored on disk). It is only
  /// available while API Studio is enabled — never pass `enabled: true` in
  /// builds that reach end users.
  static void showFileExplorer(
    BuildContext context, {
    ApiInspectorThemeData? theme,
  }) {
    if (!_guardUi('showFileExplorer')) return;
    unawaited(_push(Navigator.of(context), const FileExplorerScreen(), theme));
  }

  /// Opens the Performance Inspector as a full-screen page. No-op when
  /// disabled.
  static void showPerformanceInspector(
    BuildContext context, {
    ApiInspectorThemeData? theme,
  }) {
    if (!_guardUi('showPerformanceInspector')) return;
    unawaited(_push(
        Navigator.of(context), const PerformanceInspectorScreen(), theme));
  }

  /// Opens the unified API Studio container — [ApiStudioNavigationScreen] —
  /// with API Logs, Performance and File Explorer tabs. No-op when disabled.
  ///
  /// [initialIndex] selects which tab is shown first (`0` = Logs,
  /// `1` = Performance, `2` = Files).
  static void showNavigation(
    BuildContext context, {
    ApiInspectorThemeData? theme,
    int initialIndex = 0,
  }) {
    if (!_guardUi('showNavigation')) return;
    unawaited(_push(Navigator.of(context),
        ApiStudioNavigationScreen(initialIndex: initialIndex), theme));
  }

  /// Opens the unified API Studio screen without a [BuildContext], using
  /// [navigatorKey]. No-op when disabled or when the key is not attached to
  /// a navigator.
  static void open({ApiInspectorThemeData? theme, int initialIndex = 0}) {
    if (!_guardUi('open')) return;
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      debugPrint('[ApiStudio] open() needs ApiStudio.navigatorKey to be '
          'attached to your MaterialApp (or passed to initialize()).');
      return;
    }
    if (_isOpen) return;
    unawaited(_push(navigator,
        ApiStudioNavigationScreen(initialIndex: initialIndex), theme));
  }

  // ── Floating debug button ──────────────────────────────────────────

  static OverlayEntry? _floatingEntry;

  /// Whether the floating debug button is currently shown.
  static bool get isFloatingButtonVisible => _floatingEntry != null;

  /// Shows a draggable floating button that opens API Studio when tapped.
  ///
  /// Uses the root [Overlay] of [context], or of [navigatorKey] when
  /// [context] is omitted. Call it after the first frame, e.g. from
  /// `initState` via `WidgetsBinding.instance.addPostFrameCallback`.
  /// No-op when disabled or already visible.
  static void showFloatingButton([BuildContext? context]) {
    if (!_guardUi('showFloatingButton') || _floatingEntry != null) return;
    final overlay = context != null
        ? Overlay.maybeOf(context, rootOverlay: true)
        : _navigatorKey?.currentState?.overlay;
    if (overlay == null) {
      debugPrint('[ApiStudio] showFloatingButton() could not find an Overlay.');
      return;
    }
    final entry = OverlayEntry(
      builder: (ctx) => ApiStudioFloatingButton(
        onTap: () {
          if (_isOpen) return;
          final navigator = Navigator.maybeOf(ctx, rootNavigator: true) ??
              _navigatorKey?.currentState;
          if (navigator != null && isEnabled) {
            unawaited(
                _push(navigator, const ApiStudioNavigationScreen(), null));
          }
        },
      ),
    );
    _floatingEntry = entry;
    overlay.insert(entry);
  }

  /// Removes the floating debug button, if shown.
  static void hideFloatingButton() {
    _floatingEntry?.remove();
    _floatingEntry = null;
  }

  // ── Performance Monitoring API ─────────────────────────────────────

  /// Starts performance monitoring (frame timings, memory polling). No-op
  /// when disabled.
  static void startPerformanceMonitoring() {
    if (!isEnabled) return;
    PerformanceMonitor.instance.start();
  }

  /// Stops performance monitoring.
  static void stopPerformanceMonitoring() => PerformanceMonitor.instance.stop();

  /// A broadcast stream of [PerformanceSnapshot] updates.
  static Stream<PerformanceSnapshot> get performanceStream =>
      PerformanceMonitor.instance.snapshotStream;

  // ── Cloud Sync & Universal Logging API ──────────────────────────────

  /// Immediately flushes all pending remote logs to the API Studio Cloud
  /// portal (`https://apistudio.cloud/`). No-op when disabled or when no
  /// API key is configured.
  static Future<void> flush() async {
    if (!isEnabled) return;
    await ApiStudioRemoteLogger.uploadNow();
  }

  /// Logs an HTTP request/response into API Studio.
  ///
  /// This is the shared pipeline used by every integration
  /// (`ApiStudioDioInterceptor`, `ApiStudioHttpClient`, [ApiStudioClient]):
  /// the log is redacted (see [RedactionConfig]), oversized bodies are
  /// truncated, then it is stored locally, forwarded to notification
  /// providers on failure and — if an API key is configured — queued for
  /// upload to the API Studio cloud.
  ///
  /// Use it directly for clients without a ready-made integration
  /// (Chopper, GraphQL, gRPC-web, …):
  ///
  /// ```dart
  /// ApiStudio.log(
  ///   url: 'https://api.example.com/users',
  ///   method: 'GET',
  ///   statusCode: 200,
  ///   durationMs: 145,
  ///   responseBody: '{"id": 1}',
  /// );
  /// ```
  ///
  /// Bodies may be a `String`, JSON-encodable `Map`/`List`, or raw bytes
  /// (`List<int>`, stored as a size placeholder). Set [cancelled] for
  /// requests aborted by the caller, and [formData]/[isMultipart] for
  /// multipart uploads. [requestSizeBytes]/[responseSizeBytes] override the
  /// sizes computed from the bodies (useful when a body was only partially
  /// captured).
  ///
  /// A no-op when API Studio is disabled. Never throws.
  static Future<void> log({
    required String url,
    required String method,
    int? statusCode,
    int? durationMs,
    Map<String, dynamic> requestHeaders = const {},
    Map<String, dynamic> queryParameters = const {},
    dynamic requestBody,
    Map<String, dynamic> responseHeaders = const {},
    dynamic responseBody,
    String? errorMessage,
    StackTrace? stackTrace,
    DateTime? timestamp,
    Map<String, dynamic>? formData,
    bool isMultipart = false,
    bool cancelled = false,
    int? requestSizeBytes,
    int? responseSizeBytes,
  }) async {
    if (!isEnabled) return;
    try {
      final entity = LogEntryBuilder.build(
        url: url,
        method: method,
        statusCode: statusCode,
        durationMs: durationMs,
        requestHeaders: requestHeaders,
        queryParameters: queryParameters,
        requestBody: requestBody,
        responseHeaders: responseHeaders,
        responseBody: responseBody,
        formData: formData,
        isMultipart: isMultipart,
        cancelled: cancelled,
        errorMessage: errorMessage,
        stackTrace: stackTrace,
        timestamp: timestamp,
        requestSizeBytes: requestSizeBytes,
        responseSizeBytes: responseSizeBytes,
      );
      await LogPipeline.record(entity);
    } catch (_) {
      // Logging must never throw into the host app.
    }
  }

  /// Test hook: receives every log after redaction and truncation, exactly
  /// as it is stored and uploaded.
  @visibleForTesting
  static set debugLogListener(void Function(ApiLogEntity log)? listener) =>
      LogPipeline.debugListener = listener;
}
