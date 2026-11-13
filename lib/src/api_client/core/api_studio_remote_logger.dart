import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/hive_constants.dart';
import '../../core/device/device_context.dart';
import '../../core/utils/uuid_generator.dart';
import '../../data/datasources/hive_storage.dart';
import '../../domain/entities/api_log_entity.dart';
import 'simple_http_client.dart';

/// Uploads captured logs to the API Studio cloud (the portal).
///
/// * Payloads are only ever created from logs that already went through the
///   redaction pipeline (`LogPipeline`), so unredacted data is never queued.
/// * The queue is persisted in Hive once [attachPersistentQueue] has run, so
///   logs survive app kills and crashes — exactly when they matter most.
/// * Logs are sent in gzip-compressed batches of up to [maxBatchSize] to
///   `/api/v1/logs/batch`, falling back to one request per log on backends
///   that do not have the batch endpoint yet.
/// * Failures back off exponentially (5 s → 5 min). Rejected payloads
///   (400/413/422) are dropped so one bad log can never block the queue;
///   auth, rate-limit and server errors keep the queue for a later retry.
///
/// Completely isolated from [ApiStudioClient] and the host app's HTTP
/// stack. Never throws into, delays or affects the host app's requests.
class ApiStudioRemoteLogger {
  ApiStudioRemoteLogger._();

  static String? _apiKey;
  static SimpleHttpClient? _client;
  static Timer? _uploadTimer;
  static Timer? _debounceTimer;
  static Timer? _retryTimer;
  static _UploadQueue _queue = _MemoryQueue();
  static bool _isUploading = false;
  static Future<void>? _inFlight;
  static bool _batchUnsupported = false;
  static int _consecutiveFailures = 0;
  static DateTime? _retryAt;
  static int _batchSize = maxBatchSize;

  static const Duration _timeout = Duration(seconds: 15);
  static const Duration uploadInterval = Duration(minutes: 5);
  static const Duration _debounceInterval = Duration(milliseconds: 1500);
  static const Duration _minBackoff = Duration(seconds: 5);
  static const Duration _maxBackoff = Duration(minutes: 5);

  /// Most logs sent in one request (matches the backend limit).
  static const int maxBatchSize = 50;

  /// Upper bound on the uncompressed size of one batch request.
  static const int _maxBatchChars = 768 * 1024;

  /// Oldest payloads are dropped beyond this many pending logs.
  static const int maxPendingPayloads = 1000;
  static const int _maxBodyCharacters = 64 * 1024;

  // ── Context attached to every log ────────────────────────────────────

  /// Identifies this app launch. Lets the portal show "everything from this
  /// tester's session" in order.
  static final String sessionId = const UuidGenerator().v4();

  static Map<String, Object?>? _device;
  static Map<String, Object?>? _app;
  static Map<String, Object?>? _user;

  /// Sets the app version/build reported with every log (shown and
  /// filterable in the portal). Values are optional.
  static void setAppInfo({String? version, String? build, String? flavor}) {
    final info = <String, Object?>{
      if (version != null && version.isNotEmpty) 'version': version,
      if (build != null && build.isNotEmpty) 'build': build,
      if (flavor != null && flavor.isNotEmpty) 'flavor': flavor,
    };
    _app = info.isEmpty ? null : info;
  }

  /// Identifies the tester / signed-in user on uploaded logs. Pass `null`
  /// for all values to clear it (e.g. on sign-out).
  static void setUser({String? id, String? name, String? email}) {
    final user = <String, Object?>{
      if (id != null && id.isNotEmpty) 'id': id,
      if (name != null && name.isNotEmpty) 'name': name,
      if (email != null && email.isNotEmpty) 'email': email,
    };
    _user = user.isEmpty ? null : user;
  }

  // ── Configuration ────────────────────────────────────────────────────

  /// Configures (or disables) automatic remote logging.
  ///
  /// Passing `null` or an empty string completely disables logging with no
  /// side effects on the rest of the package.
  static void configure(String? apiKey) {
    _apiKey = (apiKey != null && apiKey.trim().isNotEmpty) ? apiKey : null;
    _uploadTimer?.cancel();
    _uploadTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    if (!isEnabled) return;
    _uploadTimer = Timer.periodic(uploadInterval, (_) {
      if (_queue.length > 0) unawaited(_uploadPending());
    });
    if (_queue.length > 0) _scheduleDebounce();
  }

  /// Moves the queue into Hive so pending logs survive restarts, and
  /// uploads anything left over from a previous launch. Never throws.
  static Future<void> attachPersistentQueue() async {
    if (_queue is _HiveQueue) return;
    try {
      final box =
          await ApiStudioHive.openBox<String>(HiveConstants.uploadQueueBoxName);
      final persistent = _HiveQueue(box);
      final inMemory = _queue.peek(maxPendingPayloads).map((e) => e.payload);
      for (final payload in inMemory) {
        await persistent.add(payload);
      }
      await persistent.trimTo(maxPendingPayloads);
      _queue = persistent;
      if (isEnabled && _queue.length > 0) _scheduleDebounce();
    } catch (e) {
      debugPrint('[ApiStudio] Upload queue not persisted ($e); '
          'keeping it in memory.');
    }
  }

  /// Whether an API key has been configured and logging is active.
  static bool get isEnabled => _apiKey != null;

  /// Number of pending payloads awaiting upload to the cloud portal.
  static int get pendingPayloadCount => _queue.length;

  /// Forces an immediate upload of all pending payloads, ignoring backoff.
  static Future<void> uploadNow() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    // Wait for an upload already in flight, then send whatever is left.
    final inFlight = _inFlight;
    if (inFlight != null) await inFlight;
    await _uploadPending(force: true);
  }

  // ── Enqueue ──────────────────────────────────────────────────────────

  /// Queues an already-prepared (redacted + truncated) [log] for upload.
  ///
  /// Only [LogPipeline] calls this, which guarantees redaction has run.
  /// Fire-and-forget: never awaits the network and never throws.
  static void enqueue(ApiLogEntity log) {
    if (!isEnabled) return;
    if (_isApiStudioRequest(log.url)) return;
    try {
      final payload = jsonEncode(buildPayload(log));
      unawaited(_queue.add(payload).then((_) {
        return _queue.trimTo(maxPendingPayloads);
      }).catchError((_) {}));

      _scheduleDebounce(immediate: log.hasError);
    } catch (_) {}
  }

  /// The JSON object sent to the backend for [log].
  @visibleForTesting
  static Map<String, Object?> buildPayload(ApiLogEntity log) {
    return {
      'method': log.methodLabel,
      'url': log.url,
      // The backend stores integers. Network failures, timeouts and
      // cancellations have neither, and are the logs users most need.
      'status_code': log.statusCode ?? 0,
      'duration_ms': log.durationMs ?? 0,
      'status': log.status.name,
      'query_params': log.queryParams.isEmpty ? null : log.queryParams,
      'request': {
        'headers': log.requestHeaders,
        'body': _safeBody(log.requestBody ??
            (log.formData == null ? null : jsonEncode(log.formData))),
        'size_bytes': log.requestSizeBytes,
      },
      'response': {
        'headers': log.responseHeaders,
        'body': _safeBody(log.responseBody),
        'size_bytes': log.responseSizeBytes,
      },
      'error': log.errorMessage,
      'is_truncated': log.isTruncated,
      'timestamp': log.timestamp.toUtc().toIso8601String(),
      'session_id': sessionId,
      'device': _device ??= describeDevice(),
      if (_app != null) 'app': _app,
      if (_user != null) 'user': _user,
      'sdk': const {'name': 'api_studio', 'version': AppConstants.sdkVersion},
    };
  }

  static bool _isApiStudioRequest(String url) {
    return url.startsWith(AppConstants.apiStudioBaseUrl) ||
        url.contains(AppConstants.apiStudioLogsPath);
  }

  static void _scheduleDebounce({bool immediate = false}) {
    if (!isEnabled) return;
    if (immediate || _queue.length >= 10) {
      _debounceTimer?.cancel();
      _debounceTimer = null;
      unawaited(_uploadPending());
      return;
    }
    if (_debounceTimer != null && _debounceTimer!.isActive) return;
    _debounceTimer = Timer(_debounceInterval, () {
      _debounceTimer = null;
      unawaited(_uploadPending());
    });
  }

  // ── Upload ───────────────────────────────────────────────────────────

  static Future<void> _uploadPending({bool force = false}) {
    if (!isEnabled || _isUploading || _queue.length == 0) {
      return Future<void>.value();
    }
    final retryAt = _retryAt;
    if (!force && retryAt != null && DateTime.now().isBefore(retryAt)) {
      return Future<void>.value();
    }
    final apiKey = _apiKey;
    if (apiKey == null) return Future<void>.value();

    _isUploading = true;
    return _inFlight = _drain(apiKey).whenComplete(() {
      _isUploading = false;
      _inFlight = null;
    });
  }

  static Future<void> _drain(String apiKey) async {
    try {
      final client = _client ??= SimpleHttpClient();
      while (isEnabled && _queue.length > 0) {
        final batch = _takeBatch();
        final outcome = await _send(client, apiKey, batch);
        switch (outcome) {
          case _Outcome.accepted:
          case _Outcome.dropped:
            await _queue.remove(batch.map((e) => e.key));
            _consecutiveFailures = 0;
            _retryAt = null;
          case _Outcome.tooLarge:
            if (batch.length > 1) {
              _batchSize = math.max(1, batch.length ~/ 2);
            } else {
              await _queue.remove(batch.map((e) => e.key));
            }
          case _Outcome.switchedMode:
            break;
          case _Outcome.retryLater:
            _backoff();
            return;
        }
      }
    } catch (_) {
      _backoff();
    }
  }

  static List<_QueuedPayload> _takeBatch() {
    final items = _queue.peek(_batchUnsupported ? 1 : _batchSize);
    var chars = 0;
    final batch = <_QueuedPayload>[];
    for (final item in items) {
      if (batch.isNotEmpty && chars + item.payload.length > _maxBatchChars) {
        break;
      }
      chars += item.payload.length;
      batch.add(item);
    }
    return batch;
  }

  static Future<_Outcome> _send(
    SimpleHttpClient client,
    String apiKey,
    List<_QueuedPayload> batch,
  ) async {
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (!_batchUnsupported) {
      final response = await client.post(
        Uri.parse(AppConstants.apiStudioLogsBatchUrl),
        headers: headers,
        body: '{"logs":[${batch.map((e) => e.payload).join(',')}]}',
        timeout: _timeout,
        gzip: true,
      );
      final code = response.statusCode;
      if (code != 404 && code != 405) return _classify(code);
      // Older backend without the batch endpoint: switch to one log per
      // request and let the loop resend from the same queue position.
      _batchUnsupported = true;
      return _Outcome.switchedMode;
    }

    final response = await client.post(
      Uri.parse(AppConstants.apiStudioLogsUrl),
      headers: headers,
      body: batch.first.payload,
      timeout: _timeout,
    );
    return _classify(response.statusCode);
  }

  static _Outcome _classify(int code) {
    if (code >= 200 && code < 300) return _Outcome.accepted;
    if (code == 413) return _Outcome.tooLarge;
    if (code == 400 || code == 422 || code == 404 || code == 410) {
      debugPrint('API Studio: Discarded rejected log payload (status $code).');
      return _Outcome.dropped;
    }
    // 401/403 (key revoked or inactive), 408, 429, 5xx: keep and retry.
    debugPrint('API Studio: Log upload paused (status $code).');
    return _Outcome.retryLater;
  }

  static void _backoff() {
    _consecutiveFailures++;
    final ms = math.min(
      _maxBackoff.inMilliseconds,
      _minBackoff.inMilliseconds * (1 << math.min(_consecutiveFailures, 10)),
    );
    final delay = Duration(milliseconds: ms);
    _retryAt = DateTime.now().add(delay);
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      _retryTimer = null;
      unawaited(_uploadPending());
    });
  }

  static dynamic _safeBody(String? body) {
    if (body == null) return null;
    if (body.length > _maxBodyCharacters) return _truncate(body);
    final trimmed = body.trimLeft();
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) return body;
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  static String _truncate(String value) {
    if (value.length <= _maxBodyCharacters) return value;
    return '${value.substring(0, _maxBodyCharacters)}…';
  }

  // ── Test hooks ───────────────────────────────────────────────────────

  /// Test-only hook to inject a fake [SimpleHttpClient].
  @visibleForTesting
  static void debugOverride({SimpleHttpClient? client}) {
    if (client != null) _client = client;
  }

  /// Test-only hook to reset all static state.
  @visibleForTesting
  static void debugReset() {
    configure(null);
    final queue = _queue;
    if (queue is _HiveQueue) unawaited(queue.clear());
    _queue = _MemoryQueue();
    _client = null;
    _isUploading = false;
    _inFlight = null;
    _batchUnsupported = false;
    _consecutiveFailures = 0;
    _retryAt = null;
    _batchSize = maxBatchSize;
    _app = null;
    _user = null;
  }
}

enum _Outcome { accepted, dropped, tooLarge, switchedMode, retryLater }

typedef _QueuedPayload = ({Object key, String payload});

abstract class _UploadQueue {
  int get length;
  List<_QueuedPayload> peek(int count);
  Future<void> add(String payload);
  Future<void> remove(Iterable<Object> keys);
  Future<void> trimTo(int max);
}

class _MemoryQueue implements _UploadQueue {
  final List<_QueuedPayload> _items = [];
  int _next = 0;

  @override
  int get length => _items.length;

  @override
  List<_QueuedPayload> peek(int count) => _items.take(count).toList();

  @override
  Future<void> add(String payload) async =>
      _items.add((key: _next++, payload: payload));

  @override
  Future<void> remove(Iterable<Object> keys) async {
    final set = keys.toSet();
    _items.removeWhere((e) => set.contains(e.key));
  }

  @override
  Future<void> trimTo(int max) async {
    if (_items.length > max) _items.removeRange(0, _items.length - max);
  }
}

/// Keys are Hive's auto-increment integers, so key order is FIFO order.
class _HiveQueue implements _UploadQueue {
  final Box<String> _box;

  _HiveQueue(this._box);

  @override
  int get length => _box.length;

  @override
  List<_QueuedPayload> peek(int count) {
    final out = <_QueuedPayload>[];
    for (final key in _box.keys) {
      if (out.length >= count) break;
      final value = _box.get(key);
      if (value != null) out.add((key: key as Object, payload: value));
    }
    return out;
  }

  @override
  Future<void> add(String payload) => _box.add(payload);

  @override
  Future<void> remove(Iterable<Object> keys) => _box.deleteAll(keys);

  @override
  Future<void> trimTo(int max) async {
    final extra = _box.length - max;
    if (extra > 0) await _box.deleteAll(_box.keys.take(extra).toList());
  }

  Future<void> clear() => _box.clear();
}
