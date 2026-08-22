import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'simple_http_client.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/hive_constants.dart';
import '../../domain/entities/performance_snapshot.dart';
import '../../services/performance_monitor.dart';
import '../models/performance_telemetry.dart';

/// Persists the timestamp of the last successful performance telemetry
/// upload so the once-per-hour interval survives app restarts.
///
/// Reuses [Hive] — the persistence mechanism the package already uses for
/// API logs — instead of introducing a new storage dependency.
abstract class PerformanceUploadStateStore {
  Future<DateTime?> getLastUploadAt();
  Future<void> setLastUploadAt(DateTime time);
}

class HivePerformanceUploadStateStore implements PerformanceUploadStateStore {
  Box? _box;

  Future<Box> _openBox() async {
    final existing = _box;
    if (existing != null && existing.isOpen) return existing;
    _box = await Hive.openBox(HiveConstants.performanceStateBoxName);
    return _box!;
  }

  @override
  Future<DateTime?> getLastUploadAt() async {
    final box = await _openBox();
    final stored = box.get(HiveConstants.lastPerformanceUploadKey);
    if (stored is! String) return null;
    return DateTime.tryParse(stored);
  }

  @override
  Future<void> setLastUploadAt(DateTime time) async {
    final box = await _openBox();
    await box.put(
      HiveConstants.lastPerformanceUploadKey,
      time.toUtc().toIso8601String(),
    );
  }
}

/// Uploads a single aggregated [PerformanceSnapshot] to the API Studio
/// backend at most once per hour, using the exact same API key and base URL
/// already configured for [ApiStudioRemoteLogger] (API logs).
///
/// Performance monitoring is opt-in: unless [configure] is called with
/// `enabled: true`, this class never performs any network request.
///
/// Fully isolated fire-and-forget behaviour — failures are swallowed and
/// never affect the user's own API requests.
class PerformanceTelemetryUploader {
  PerformanceTelemetryUploader._();

  static const Duration uploadInterval = Duration(hours: 1);
  static const Duration _timeout = Duration(seconds: 10);

  static bool _enabled = false;
  static String? _apiKey;

  static PerformanceUploadStateStore _stateStore =
      HivePerformanceUploadStateStore();
  static SimpleHttpClient? _client;

  static StreamSubscription<PerformanceSnapshot>? _subscription;

  static bool _isUploadingPerformance = false;
  static DateTime? _lastUploadAt;
  static bool _lastUploadLoaded = false;

  /// Whether performance monitoring has been explicitly enabled AND an API
  /// key is configured. When `false`, no performance network call is ever
  /// made.
  static bool get isEnabled => _enabled && _apiKey != null;

  @visibleForTesting
  static bool get isUploadingPerformance => _isUploadingPerformance;

  @visibleForTesting
  static DateTime? get lastUploadAt => _lastUploadAt;

  /// Configures (or disables) automatic remote performance telemetry
  /// upload.
  ///
  /// [apiKey] must be the exact same API key configured for API logging.
  /// Passing `enabled: false` (the default across the package) guarantees
  /// zero performance network calls.
  static void configure({
    required String? apiKey,
    required bool enabled,
  }) {
    _apiKey = (apiKey != null && apiKey.trim().isNotEmpty) ? apiKey : null;
    _enabled = enabled;

    unawaited(_subscription?.cancel());
    _subscription = null;

    if (!isEnabled) return;

    // Check the interval whenever a new aggregated snapshot is available,
    // instead of running a dedicated high-frequency upload timer.
    _subscription = PerformanceMonitor.instance.snapshotStream.listen(
      (snapshot) => unawaited(checkAndMaybeUpload(snapshot)),
      onError: (_) {},
    );
  }

  /// Forces an immediate upload of the current performance snapshot,
  /// bypassing the [uploadInterval] check.
  ///
  /// This is intended for explicit user-triggered actions such as opening
  /// the performance inspector screen. It still respects the [isEnabled]
  /// flag and the [_isUploadingPerformance] concurrency guard so it will
  /// never duplicate an in-flight upload.
  static Future<void> uploadNow() async {
    if (!isEnabled) return;
    if (_isUploadingPerformance) return;

    _isUploadingPerformance = true;
    try {
      await _ensureLastUploadLoaded();

      final snapshot = PerformanceMonitor.instance.currentSnapshot;
      final payload = _buildPayload(snapshot);
      final success = await _post(payload);
      if (success) {
        final now = DateTime.now();
        _lastUploadAt = now;
        await _stateStore.setLastUploadAt(now);
      }
    } catch (_) {
      // Performance telemetry must never throw into the caller.
    } finally {
      _isUploadingPerformance = false;
    }
  }

  /// Checks whether an upload is due and, if so, performs it.
  ///
  /// Safe to call as often as needed (e.g. on every performance snapshot or
  /// app resume): it is a no-op unless monitoring is enabled, no upload is
  /// already in flight, and at least [uploadInterval] has elapsed since the
  /// last successful upload.
  static Future<void> checkAndMaybeUpload(PerformanceSnapshot snapshot) async {
    if (!isEnabled) return;
    if (_isUploadingPerformance) return;

    // Set the guard synchronously (no await before this point) so that two
    // near-simultaneous calls can never both proceed past this check.
    _isUploadingPerformance = true;
    try {
      await _ensureLastUploadLoaded();

      final now = DateTime.now();
      if (_lastUploadAt != null &&
          now.difference(_lastUploadAt!) < uploadInterval) {
        return;
      }

      final payload = _buildPayload(snapshot);
      final success = await _post(payload);
      if (success) {
        _lastUploadAt = now;
        await _stateStore.setLastUploadAt(now);
      }
    } catch (_) {
      // Performance telemetry must never throw into the caller.
    } finally {
      _isUploadingPerformance = false;
    }
  }

  static Future<void> _ensureLastUploadLoaded() async {
    if (_lastUploadLoaded) return;
    try {
      final stored = await _stateStore.getLastUploadAt();
      // No previous upload recorded: do NOT upload immediately. Use "now"
      // as the baseline so the first upload only happens once a full
      // interval has elapsed from this point, per the package's first-run
      // behaviour (no unnecessary network request during init).
      _lastUploadAt = stored ?? DateTime.now();
    } catch (_) {
      _lastUploadAt = DateTime.now();
    } finally {
      _lastUploadLoaded = true;
    }
  }

  static PerformanceTelemetry _buildPayload(PerformanceSnapshot snapshot) {
    final frame = snapshot.frameMetrics;
    final memory = snapshot.memoryMetrics;
    final startup = snapshot.startupMetrics;

    PerformanceFps? fps;
    PerformanceFrameTime? frameTime;
    PerformanceJank? jank;

    if (frame.hasData) {
      fps = PerformanceFps(
        average: frame.averageFps,
        min: frame.minFps,
        p95: _percentile(snapshot.fpsHistory, 95) ?? frame.averageFps,
      );
      frameTime = PerformanceFrameTime(
        averageMs: frame.averageFrameTimeMs,
        p95Ms: _percentile(snapshot.frameTimeHistory, 95) ??
            frame.averageFrameTimeMs,
      );
      jank = PerformanceJank(
        totalFrames: frame.totalFrames,
        jankyFrames: frame.jankyFrames,
        jankRate: frame.jankRate,
      );
    }

    PerformanceMemory? memoryPayload;
    if (memory.isAvailable && memory.currentUsageBytes != null) {
      const bytesPerMb = 1024 * 1024;
      final history = snapshot.memoryHistoryBytes;
      final averageBytes = history.isNotEmpty
          ? history.reduce((a, b) => a + b) / history.length
          : memory.currentUsageBytes!.toDouble();
      final peakBytes = memory.peakUsageBytes ?? memory.currentUsageBytes!;
      memoryPayload = PerformanceMemory(
        averageMb: averageBytes / bytesPerMb,
        peakMb: peakBytes / bytesPerMb,
      );
    }

    PerformanceStartup? startupPayload;
    if (startup.isAvailable && startup.totalStartupDuration != null) {
      startupPayload = PerformanceStartup(
        durationMs: startup.totalStartupDuration!.inMilliseconds,
      );
    }

    return PerformanceTelemetry(
      timestamp: DateTime.now().toUtc(),
      sessionDurationMs: snapshot.sessionDuration.inMilliseconds,
      fps: fps,
      frameTime: frameTime,
      jank: jank,
      memory: memoryPayload,
      startup: startupPayload,
      healthScore: frame.hasData ? snapshot.performanceScore : null,
    );
  }

  static double? _percentile(List<double> values, double percentile) {
    if (values.isEmpty) return null;
    final sorted = [...values]..sort();
    final index = ((percentile / 100) * (sorted.length - 1)).round();
    return sorted[index.clamp(0, sorted.length - 1)];
  }

  static Future<bool> _post(PerformanceTelemetry payload) async {
    final apiKey = _apiKey;
    if (apiKey == null) return false;

    try {
      final client = _client ??= SimpleHttpClient();
      final response = await client.post(
        Uri.parse(AppConstants.apiStudioPerformanceUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload.toJson()),
        timeout: _timeout,
      );

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Test-only hook to inject a fake [SimpleHttpClient] and/or
  /// [PerformanceUploadStateStore], avoiding real network/Hive access in
  /// unit tests.
  @visibleForTesting
  static void debugOverride({
    SimpleHttpClient? client,
    PerformanceUploadStateStore? stateStore,
  }) {
    if (client != null) _client = client;
    if (stateStore != null) _stateStore = stateStore;
  }

  /// Test-only hook to reset all static state between tests.
  @visibleForTesting
  static Future<void> debugReset() async {
    await _subscription?.cancel();
    _subscription = null;
    _enabled = false;
    _apiKey = null;
    _client = null;
    _stateStore = HivePerformanceUploadStateStore();
    _isUploadingPerformance = false;
    _lastUploadAt = null;
    _lastUploadLoaded = false;
  }
}
