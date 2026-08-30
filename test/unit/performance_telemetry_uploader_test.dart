import 'dart:async';
import 'dart:convert';

import 'package:api_studio/src/api_client/core/api_studio_performance_uploader.dart';
import 'package:api_studio/src/api_client/core/simple_http_client.dart';
import 'package:api_studio/src/domain/entities/frame_metrics.dart';
import 'package:api_studio/src/domain/entities/memory_metrics.dart';
import 'package:api_studio/src/domain/entities/performance_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simple in-memory fake so tests never touch real Hive storage.
class _InMemoryStateStore implements PerformanceUploadStateStore {
  DateTime? stored;
  _InMemoryStateStore([this.stored]);

  @override
  Future<DateTime?> getLastUploadAt() async => stored;

  @override
  Future<void> setLastUploadAt(DateTime time) async {
    stored = time;
  }
}

/// Fake [SimpleHttpClient] that captures request details and returns
/// a controlled response without making any real network call.
class _FakeSimpleHttpClient extends SimpleHttpClient {
  final FutureOr<SimpleHttpResponse> Function(
      Uri url, Map<String, String> headers, String body) _handler;
  int requestCount = 0;

  _FakeSimpleHttpClient(this._handler);

  @override
  Future<SimpleHttpResponse> post(
    Uri url, {
    required Map<String, String> headers,
    required String body,
    Duration? timeout,
  }) async {
    requestCount++;
    return Future.value(_handler(url, headers, body));
  }

  @override
  void close() {}
}

PerformanceSnapshot _fakeSnapshot() {
  return const PerformanceSnapshot(
    frameMetrics: FrameMetrics(
      averageFps: 58.7,
      minFps: 41.2,
      totalFrames: 1000,
      jankyFrames: 7,
      jankRate: 0.7,
      averageFrameTimeMs: 17.1,
    ),
    memoryMetrics: MemoryMetrics(
      currentUsageBytes: 190000000,
      peakUsageBytes: 250000000,
      isAvailable: true,
    ),
    sessionDuration: Duration(minutes: 5),
    performanceScore: 92,
    fpsHistory: [55.0, 58.0, 59.0, 60.0],
    frameTimeHistory: [16.0, 17.0, 18.0, 20.0],
    memoryHistoryBytes: [180000000, 190000000, 200000000],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await PerformanceTelemetryUploader.debugReset();
  });

  group('PerformanceTelemetryUploader — disabled', () {
    test('enablePerformanceMonitoring = false makes zero requests', () async {
      final client = _FakeSimpleHttpClient(
        (_, __, ___) => const SimpleHttpResponse(statusCode: 200, body: '{}'),
      );

      PerformanceTelemetryUploader.debugOverride(
        client: client,
        stateStore: _InMemoryStateStore(),
      );
      PerformanceTelemetryUploader.configure(apiKey: 'key', enabled: false);

      await PerformanceTelemetryUploader.checkAndMaybeUpload(_fakeSnapshot());

      expect(client.requestCount, 0);
      expect(PerformanceTelemetryUploader.isEnabled, isFalse);
    });
  });

  group('PerformanceTelemetryUploader — interval', () {
    test('does nothing if last upload was 3 minutes ago', () async {
      final client = _FakeSimpleHttpClient(
        (_, __, ___) => const SimpleHttpResponse(statusCode: 200, body: '{}'),
      );
      final store = _InMemoryStateStore(
        DateTime.now().subtract(const Duration(minutes: 3)),
      );

      PerformanceTelemetryUploader.debugOverride(
        client: client,
        stateStore: store,
      );
      PerformanceTelemetryUploader.configure(apiKey: 'key', enabled: true);

      await PerformanceTelemetryUploader.checkAndMaybeUpload(_fakeSnapshot());

      expect(client.requestCount, 0);
    });

    test('uploads once interval (persisted 2 hours ago) has elapsed', () async {
      final client = _FakeSimpleHttpClient(
        (_, __, ___) => const SimpleHttpResponse(statusCode: 200, body: '{}'),
      );
      final store = _InMemoryStateStore(
        DateTime.now().subtract(const Duration(hours: 2)),
      );

      PerformanceTelemetryUploader.debugOverride(
        client: client,
        stateStore: store,
      );
      PerformanceTelemetryUploader.configure(apiKey: 'key', enabled: true);

      await PerformanceTelemetryUploader.checkAndMaybeUpload(_fakeSnapshot());

      expect(client.requestCount, 1);
      expect(store.stored, isNotNull);
    });

    test('no previous upload timestamp does not trigger an immediate upload',
        () async {
      final client = _FakeSimpleHttpClient(
        (_, __, ___) => const SimpleHttpResponse(statusCode: 200, body: '{}'),
      );

      PerformanceTelemetryUploader.debugOverride(
        client: client,
        stateStore: _InMemoryStateStore(null),
      );
      PerformanceTelemetryUploader.configure(apiKey: 'key', enabled: true);

      await PerformanceTelemetryUploader.checkAndMaybeUpload(_fakeSnapshot());

      expect(client.requestCount, 0);
    });
  });

  group('PerformanceTelemetryUploader — uploadNow', () {
    test('uploads immediately even if last upload was 30 minutes ago',
        () async {
      final client = _FakeSimpleHttpClient(
        (_, __, ___) => const SimpleHttpResponse(statusCode: 200, body: '{}'),
      );
      final store = _InMemoryStateStore(
        DateTime.now().subtract(const Duration(minutes: 30)),
      );

      PerformanceTelemetryUploader.debugOverride(
        client: client,
        stateStore: store,
      );
      PerformanceTelemetryUploader.configure(apiKey: 'key', enabled: true);

      await PerformanceTelemetryUploader.uploadNow();

      expect(client.requestCount, 1);
      expect(store.stored, isNotNull);
    });

    test('uploads immediately even with no previous upload timestamp',
        () async {
      final client = _FakeSimpleHttpClient(
        (_, __, ___) => const SimpleHttpResponse(statusCode: 200, body: '{}'),
      );

      PerformanceTelemetryUploader.debugOverride(
        client: client,
        stateStore: _InMemoryStateStore(null),
      );
      PerformanceTelemetryUploader.configure(apiKey: 'key', enabled: true);

      await PerformanceTelemetryUploader.uploadNow();

      expect(client.requestCount, 1);
    });

    test('does nothing when disabled', () async {
      final client = _FakeSimpleHttpClient(
        (_, __, ___) => const SimpleHttpResponse(statusCode: 200, body: '{}'),
      );

      PerformanceTelemetryUploader.debugOverride(
        client: client,
        stateStore: _InMemoryStateStore(),
      );
      PerformanceTelemetryUploader.configure(apiKey: 'key', enabled: false);

      await PerformanceTelemetryUploader.uploadNow();

      expect(client.requestCount, 0);
    });
  });

  group('PerformanceTelemetryUploader — success / failure', () {
    test('failed upload does not update lastPerformanceUploadAt', () async {
      final client = _FakeSimpleHttpClient(
        (_, __, ___) => const SimpleHttpResponse(statusCode: 500, body: ''),
      );
      final store = _InMemoryStateStore(
        DateTime.now().subtract(const Duration(hours: 2)),
      );

      PerformanceTelemetryUploader.debugOverride(
        client: client,
        stateStore: store,
      );
      PerformanceTelemetryUploader.configure(apiKey: 'key', enabled: true);

      final before = store.stored;
      await PerformanceTelemetryUploader.checkAndMaybeUpload(_fakeSnapshot());

      expect(store.stored, before);
    });

    test('successful upload updates lastPerformanceUploadAt', () async {
      final client = _FakeSimpleHttpClient(
        (_, __, ___) => const SimpleHttpResponse(statusCode: 200, body: '{}'),
      );
      final store = _InMemoryStateStore(
        DateTime.now().subtract(const Duration(hours: 2)),
      );

      PerformanceTelemetryUploader.debugOverride(
        client: client,
        stateStore: store,
      );
      PerformanceTelemetryUploader.configure(apiKey: 'key', enabled: true);

      await PerformanceTelemetryUploader.checkAndMaybeUpload(_fakeSnapshot());

      expect(store.stored, isNotNull);
      expect(
        DateTime.now().difference(store.stored!).inSeconds < 5,
        isTrue,
      );
    });
  });

  group('PerformanceTelemetryUploader — concurrency', () {
    test('two near-simultaneous calls result in only one network request',
        () async {
      final client = _FakeSimpleHttpClient((_, __, ___) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return const SimpleHttpResponse(statusCode: 200, body: '{}');
      });
      final store = _InMemoryStateStore(
        DateTime.now().subtract(const Duration(hours: 2)),
      );

      PerformanceTelemetryUploader.debugOverride(
        client: client,
        stateStore: store,
      );
      PerformanceTelemetryUploader.configure(apiKey: 'key', enabled: true);

      final snapshot = _fakeSnapshot();
      await Future.wait([
        PerformanceTelemetryUploader.checkAndMaybeUpload(snapshot),
        PerformanceTelemetryUploader.checkAndMaybeUpload(snapshot),
      ]);

      expect(client.requestCount, 1);
    });
  });

  group('PerformanceTelemetryUploader — request contents', () {
    test('uses Bearer auth with the configured API key and correct URL',
        () async {
      Uri? capturedUrl;
      Map<String, String>? capturedHeaders;
      String? capturedBody;
      final client = _FakeSimpleHttpClient((url, headers, body) {
        capturedUrl = url;
        capturedHeaders = headers;
        capturedBody = body;
        return const SimpleHttpResponse(statusCode: 200, body: '{}');
      });
      final store = _InMemoryStateStore(
        DateTime.now().subtract(const Duration(hours: 2)),
      );

      PerformanceTelemetryUploader.debugOverride(
        client: client,
        stateStore: store,
      );
      PerformanceTelemetryUploader.configure(
        apiKey: 'my_test_api_key',
        enabled: true,
      );

      await PerformanceTelemetryUploader.checkAndMaybeUpload(_fakeSnapshot());

      expect(capturedUrl, isNotNull);
      expect(
        capturedHeaders!['Authorization'],
        'Bearer my_test_api_key',
      );
      expect(
        capturedUrl!.toString(),
        endsWith('/api/v1/performance'),
      );

      final body = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(body['session_duration_ms'], 300000);
      expect(body['health_score'], 92);
      expect(body['jank']['total_frames'], 1000);
    });
  });
}
