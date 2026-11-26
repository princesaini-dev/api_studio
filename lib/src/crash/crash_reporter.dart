import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../api_client/core/api_studio_remote_logger.dart';
import '../api_client/core/simple_http_client.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/hive_constants.dart';
import '../core/utils/uuid_generator.dart';
import '../data/datasources/hive_storage.dart';
import 'crash_breadcrumbs.dart';

/// Captures uncaught Flutter / Dart errors and reports them to the API
/// Studio portal, where they are grouped into issues.
///
/// * Chains onto [FlutterError.onError] and [PlatformDispatcher.onError]:
///   handlers the app installed before are still called, and the default
///   console output is unchanged.
/// * Reports are queued in Hive before uploading, so a crash survives the
///   app being killed and is sent on the next launch.
/// * The same error is reported at most [maxReportsPerErrorPerSession]
///   times per app launch, so an error thrown on every frame cannot flood
///   the queue or the backend.
/// * Never throws into the app.
class ApiStudioCrashReporter {
  ApiStudioCrashReporter._();

  static const int maxPending = 30;
  static const int maxReportsPerErrorPerSession = 3;
  static const int _maxBatch = 20;
  static const Duration _timeout = Duration(seconds: 15);
  static const Duration _minBackoff = Duration(seconds: 15);
  static const Duration _maxBackoff = Duration(minutes: 5);
  static const int _maxStackChars = 60 * 1000;
  static const int _maxMessageChars = 4000;

  static String? _apiKey;
  static bool _enabled = false;
  static bool _installed = false;
  static FlutterExceptionHandler? _previousFlutterHandler;
  static ErrorCallback? _previousPlatformHandler;

  static final List<String> _memoryQueue = [];
  static Box<String>? _box;
  static String? _installId;
  static SimpleHttpClient? _client;
  static bool _uploading = false;
  static Timer? _retryTimer;
  static int _failures = 0;
  static final Map<String, int> _sentPerError = {};

  /// Whether crash reporting is on and an API key is configured.
  static bool get isEnabled => _enabled && _apiKey != null;

  @visibleForTesting
  static int get pendingCount => _box?.length ?? _memoryQueue.length;

  /// Turns crash reporting on or off. Installs the global handlers the
  /// first time it is enabled and restores the previous ones when disabled.
  static void configure({required String? apiKey, required bool enabled}) {
    _apiKey = (apiKey != null && apiKey.trim().isNotEmpty) ? apiKey : null;
    _enabled = enabled;
    if (isEnabled) {
      _install();
    } else {
      _uninstall();
    }
  }

  /// Moves the queue onto disk and sends reports left from a previous
  /// launch. Never throws.
  static Future<void> attachPersistentQueue() async {
    if (_box != null) return;
    try {
      final box =
          await ApiStudioHive.openBox<String>(HiveConstants.crashQueueBoxName);
      _installId = box.get(HiveConstants.installIdKey);
      if (_installId == null) {
        _installId = const UuidGenerator().v4();
        await box.put(HiveConstants.installIdKey, _installId!);
      }
      for (final payload in _memoryQueue) {
        await box.add(payload);
      }
      _memoryQueue.clear();
      _box = box;
      await _trim();
      if (isEnabled) unawaited(upload());
    } catch (e) {
      debugPrint('[ApiStudio] Crash queue not persisted ($e).');
    }
  }

  // ── Handlers ─────────────────────────────────────────────────────────

  static void _install() {
    if (_installed) return;
    _installed = true;
    _previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = _onFlutterError;
    _previousPlatformHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = _onPlatformError;
  }

  static void _uninstall() {
    if (!_installed) return;
    _installed = false;
    if (FlutterError.onError == _onFlutterError) {
      FlutterError.onError = _previousFlutterHandler;
    }
    if (PlatformDispatcher.instance.onError == _onPlatformError) {
      PlatformDispatcher.instance.onError = _previousPlatformHandler;
    }
    _previousFlutterHandler = null;
    _previousPlatformHandler = null;
  }

  static void _onFlutterError(FlutterErrorDetails details) {
    if (!details.silent) {
      capture(
        details.exception,
        details.stack,
        fatal: false,
        handled: false,
        message: _safe(details.exceptionAsString),
        extra: {
          if (details.library != null) 'library': details.library,
          if (details.context != null)
            'context': _safe(() => details.context!.toDescription()),
        },
      );
    }
    final previous = _previousFlutterHandler;
    if (previous != null) {
      previous(details);
    } else {
      FlutterError.presentError(details);
    }
  }

  static bool _onPlatformError(Object error, StackTrace stack) {
    capture(error, stack, fatal: true, handled: false);
    return _previousPlatformHandler?.call(error, stack) ?? false;
  }

  // ── Capture ──────────────────────────────────────────────────────────

  /// Reports [error]. Used by the global handlers and by
  /// `ApiStudio.captureException` (with [handled] `true`).
  static void capture(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    bool handled = true,
    String? message,
    Map<String, String>? tags,
    Map<String, Object?>? extra,
    List<String>? fingerprint,
  }) {
    if (!isEnabled) return;
    try {
      final payload = buildPayload(
        error,
        stack,
        fatal: fatal,
        handled: handled,
        message: message,
        tags: tags,
        extra: extra,
        fingerprint: fingerprint,
      );
      final key = '${payload['exception_type']}|${_firstFrame(payload)}';
      final sent = _sentPerError[key] ?? 0;
      if (sent >= maxReportsPerErrorPerSession) return;
      _sentPerError[key] = sent + 1;

      unawaited(_enqueue(jsonEncode(payload)).then((_) => upload()));
      // The API calls that led here are usually still waiting for their
      // batch window: send them now, next to the crash, rather than risk
      // the app closing first. (If it does, they go on the next launch.)
      if (ApiStudioRemoteLogger.pendingPayloadCount > 0) {
        unawaited(ApiStudioRemoteLogger.uploadNow().catchError((_) {}));
      }
    } catch (_) {
      // A crash reporter that crashes is worse than none.
    }
  }

  @visibleForTesting
  static Map<String, Object?> buildPayload(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    bool handled = true,
    String? message,
    Map<String, String>? tags,
    Map<String, Object?>? extra,
    List<String>? fingerprint,
  }) {
    final stackText = _truncate(
        (stack ?? (error is Error ? error.stackTrace : null))?.toString() ?? '',
        _maxStackChars);
    final cleanExtra = <String, Object?>{...?extra}
      ..removeWhere((_, v) => v == null);
    return {
      'exception_type': _exceptionType(error),
      'message': _truncate(message ?? _safe(error.toString), _maxMessageChars),
      if (stackText.isNotEmpty) 'stack_trace': stackText,
      'fatal': fatal,
      'handled': handled,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'session_id': ApiStudioRemoteLogger.sessionId,
      if (fingerprint != null && fingerprint.isNotEmpty)
        'fingerprint': fingerprint,
      'breadcrumbs': CrashBreadcrumbs.items,
      'device': {
        ...ApiStudioRemoteLogger.deviceInfo,
        if (_installId != null) 'install_id': _installId,
      },
      if (ApiStudioRemoteLogger.appInfo != null)
        'app': ApiStudioRemoteLogger.appInfo,
      if (ApiStudioRemoteLogger.userInfo != null)
        'user': ApiStudioRemoteLogger.userInfo,
      if (tags != null && tags.isNotEmpty) 'tags': tags,
      if (cleanExtra.isNotEmpty) 'extra': cleanExtra,
      'sdk': const {'name': 'api_studio', 'version': AppConstants.sdkVersion},
    };
  }

  static String _exceptionType(Object error) {
    if (error is FlutterError) return 'FlutterError';
    final type = error.runtimeType.toString();
    // Private implementation types read better as their public interface.
    if (type == '_TypeError') return 'TypeError';
    if (type == '_Exception') return 'Exception';
    if (type.startsWith('_') && error is Exception) return 'Exception';
    return type;
  }

  static String _firstFrame(Map<String, Object?> payload) {
    final stack = payload['stack_trace'] as String? ?? '';
    final line = stack
        .split('\n')
        .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    // Drop line:column so the dedupe key is stable within the session.
    return line.replaceAll(RegExp(r':\d+(:\d+)?'), '');
  }

  static String _safe(String Function() describe) {
    try {
      return describe();
    } catch (_) {
      return '';
    }
  }

  static String _truncate(String value, int max) =>
      value.length <= max ? value : '${value.substring(0, max)}…';

  // ── Queue & upload ───────────────────────────────────────────────────

  static Future<void> _enqueue(String payload) async {
    final box = _box;
    if (box != null) {
      await box.add(payload);
      await _trim();
    } else {
      _memoryQueue.add(payload);
      if (_memoryQueue.length > maxPending) {
        _memoryQueue.removeRange(0, _memoryQueue.length - maxPending);
      }
    }
  }

  static Iterable<dynamic> _reportKeys(Box<String> box) =>
      box.keys.where((k) => k != HiveConstants.installIdKey);

  static Future<void> _trim() async {
    final box = _box;
    if (box == null) return;
    final keys = _reportKeys(box).toList();
    if (keys.length > maxPending) {
      await box.deleteAll(keys.take(keys.length - maxPending));
    }
  }

  static List<(Object key, String payload)> _peek() {
    final box = _box;
    if (box != null) {
      return [
        for (final key in _reportKeys(box).take(_maxBatch))
          if (box.get(key) case final String value) (key as Object, value),
      ];
    }
    return [
      for (var i = 0; i < math.min(_maxBatch, _memoryQueue.length); i++)
        (i, _memoryQueue[i]),
    ];
  }

  static Future<void> _remove(List<(Object, String)> batch) async {
    final box = _box;
    if (box != null) {
      await box.deleteAll(batch.map((e) => e.$1));
    } else {
      _memoryQueue.removeRange(0, math.min(batch.length, _memoryQueue.length));
    }
  }

  /// Sends pending reports. Safe to call often; never throws.
  static Future<void> upload() async {
    final apiKey = _apiKey;
    if (!isEnabled || apiKey == null || _uploading) return;
    _uploading = true;
    try {
      while (isEnabled) {
        final batch = _peek();
        if (batch.isEmpty) break;
        final body = jsonEncode({
          'events': [for (final item in batch) jsonDecode(item.$2)],
        });
        final client = _client ??= SimpleHttpClient();
        final response = await client.post(
          Uri.parse(AppConstants.apiStudioErrorsBatchUrl),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: body,
          gzip: true,
          timeout: _timeout,
        );
        final code = response.statusCode;
        if ((code >= 200 && code < 300) ||
            code == 400 ||
            code == 413 ||
            code == 422) {
          // Accepted, or rejected for good: never let one report block the queue.
          await _remove(batch);
          _failures = 0;
          continue;
        }
        _scheduleRetry();
        break;
      }
    } catch (_) {
      _scheduleRetry();
    } finally {
      _uploading = false;
    }
  }

  static void _scheduleRetry() {
    _failures++;
    final seconds = math.min(
      _maxBackoff.inSeconds,
      _minBackoff.inSeconds * math.pow(2, _failures - 1).toInt(),
    );
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(seconds: seconds), () => unawaited(upload()));
  }

  // ── Testing ──────────────────────────────────────────────────────────

  @visibleForTesting
  static void debugOverride({SimpleHttpClient? client}) {
    if (client != null) _client = client;
  }

  @visibleForTesting
  static void debugReset() {
    _uninstall();
    _apiKey = null;
    _enabled = false;
    _memoryQueue.clear();
    _box = null;
    _installId = null;
    _client = null;
    _uploading = false;
    _retryTimer?.cancel();
    _retryTimer = null;
    _failures = 0;
    _sentPerError.clear();
  }
}
