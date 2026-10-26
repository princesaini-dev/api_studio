import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/api_log_entity.dart';
import 'simple_http_client.dart';

/// Sends fire-and-forget API execution logs to the dedicated API Studio
/// backend.
///
/// Payloads are only ever created from logs that already went through the
/// redaction pipeline (`LogPipeline`), so unredacted data is never queued.
///
/// This is completely isolated from [ApiStudioClient]'s own configuration:
/// it never reuses the user's base URL, headers, authentication, cookies,
/// interceptors or retry logic. It builds its own [HttpClient] request with
/// its own headers, authenticated using the API Studio API key only.
///
/// All failures are swallowed silently — logging must never affect, delay or
/// throw for the user's request.
class ApiStudioRemoteLogger {
  ApiStudioRemoteLogger._();

  static String? _apiKey;
  static SimpleHttpClient? _client;
  static Timer? _uploadTimer;
  static Timer? _debounceTimer;
  static final List<String> _pendingPayloads = [];
  static bool _isUploading = false;

  static const Duration _timeout = Duration(seconds: 10);
  static const Duration uploadInterval = Duration(minutes: 5);
  static const Duration _debounceInterval = Duration(milliseconds: 1500);
  static const int _maxPendingPayloads = 100;
  static const int _maxBodyCharacters = 64 * 1024;

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
    if (!isEnabled) return;
    _uploadTimer = Timer.periodic(
      uploadInterval,
      (_) => unawaited(_uploadPending()),
    );
  }

  /// Whether an API key has been configured and logging is active.
  static bool get isEnabled => _apiKey != null;

  /// Number of pending payloads awaiting upload to the cloud portal.
  static int get pendingPayloadCount => _pendingPayloads.length;

  /// Forces an immediate upload of all pending payloads to API Studio Cloud.
  static Future<void> uploadNow() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    await _uploadPending();
  }

  /// Queues an already-prepared (redacted + truncated) [log] for upload.
  ///
  /// Only [LogPipeline] calls this, which guarantees redaction has run.
  /// Fire-and-forget: never awaits the network and never throws.
  static void enqueue(ApiLogEntity log) {
    if (!isEnabled) return;
    if (_isApiStudioRequest(log.url)) return;
    try {
      final payload = jsonEncode({
        'method': log.methodLabel,
        'url': log.url,
        'status_code': log.statusCode,
        'duration_ms': log.durationMs,
        'request': {
          'headers': log.requestHeaders,
          'body': _safeBody(log.requestBody ??
              (log.formData == null ? null : jsonEncode(log.formData))),
        },
        'response': {
          'headers': log.responseHeaders,
          'body': _safeBody(log.responseBody),
        },
        'error': log.errorMessage,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      _pendingPayloads.add(payload);
      if (_pendingPayloads.length > _maxPendingPayloads) {
        _pendingPayloads.removeAt(0);
      }

      final statusCode = log.statusCode;
      final isError = log.errorMessage != null ||
          (statusCode != null && (statusCode < 200 || statusCode >= 400));
      _scheduleDebounce(immediate: isError);
    } catch (_) {}
  }

  static bool _isApiStudioRequest(String url) {
    return url.startsWith(AppConstants.apiStudioBaseUrl) ||
        url.contains(AppConstants.apiStudioLogsPath);
  }

  static void _scheduleDebounce({bool immediate = false}) {
    if (!isEnabled) return;
    if (immediate || _pendingPayloads.length >= 5) {
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

  static Future<void> _uploadPending() async {
    if (!isEnabled || _isUploading || _pendingPayloads.isEmpty) return;
    final apiKey = _apiKey;
    if (apiKey == null) return;

    _isUploading = true;
    try {
      final client = _client ??= SimpleHttpClient();
      while (_pendingPayloads.isNotEmpty) {
        final payload = _pendingPayloads.first;
        final response = await client.post(
          Uri.parse(AppConstants.apiStudioLogsUrl),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: payload,
          timeout: _timeout,
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          _pendingPayloads.removeAt(0);
          debugPrint('API Studio: API logs uploaded successfully.');
        } else if (response.statusCode >= 400 && response.statusCode < 500) {
          // Client rejection (e.g. malformed or invalid schema) — discard
          // poison pill so the rest of the queue continues to upload.
          _pendingPayloads.removeAt(0);
          debugPrint(
            'API Studio: Discarded rejected log payload (status ${response.statusCode}).',
          );
        } else {
          // 5xx server error: pause and retry on the next interval.
          return;
        }
      }
    } catch (_) {
      return;
    } finally {
      _isUploading = false;
    }
  }

  static dynamic _safeBody(String? body) {
    if (body == null) return null;
    if (body.length > _maxBodyCharacters) return _truncate(body);
    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  /// Test-only hook to inject a fake [SimpleHttpClient].
  @visibleForTesting
  static void debugOverride({SimpleHttpClient? client}) {
    if (client != null) _client = client;
  }

  /// Test-only hook to reset all static state.
  @visibleForTesting
  static void debugReset() {
    configure(null);
    _pendingPayloads.clear();
    _client = null;
    _isUploading = false;
  }

  static String _truncate(String value) {
    if (value.length <= _maxBodyCharacters) return value;
    return '${value.substring(0, _maxBodyCharacters)}…';
  }
}
