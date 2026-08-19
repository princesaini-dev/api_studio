import 'dart:convert';

import 'package:api_studio/src/api_client/core/api_studio_performance_uploader.dart';
import 'package:api_studio/src/domain/entities/frame_metrics.dart';
import 'package:api_studio/src/domain/entities/memory_metrics.dart';
import 'package:api_studio/src/domain/entities/performance_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return http.Response('{}', 200);
      });

      PerformanceTelemetryUploader.debugOverride(
        client: client,
        stateStore: _InMemoryStateStore(),
      );
      PerformanceTelemetryUploader.configure(apiKey: 'key', enabled: false);

      await PerformanceTelemetryUploader.checkAndMaybeUpload(_fakeSnapshot());

      expect(requestCount, 0);
      expect(PerformanceTelemetryUploader.isEnabled, isFalse);
    });
  });

  group('PerformanceTelemetryUploader — interval', () {
    test('does nothing if last upload was 30 minutes ago', () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return http.Response('{}', 200);
      });
      final store = _InMemoryStateStore(
        DateTime.now().subtract(const Duration(minutes: 30)),
      );

      PerformanceTelemetryUploader.debugOverride(
        client: client,
        stateStore: store,
      );
      PerformanceTelemetryUploader.configure(apiKey: 'key', enabled: true);

      await PerformanceTelemetryUploader.checkAndMaybeUpload(_fakeSnapshot());

      expect(requestCount, 0);
    });

    test('uploads once interval (persisted 2 hours ago) has elapsed', () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return http.Response('{}', 200);
      });
      final store = _InMemoryStateStore(
        DateTime.now().subtract(const Duration(hours: 2)),
      );

      PerformanceTelemetryUploader.debugOverride(
        client: client,
        stateStore: store,
      );
      PerformanceTelemetryUploader.configure(apiKey: 'key', enabled: true);

      await PerformanceTelemetryUploader.checkAndMaybeUpload(_fakeSnapshot());

      expect(requestCount, 1);
      expect(store.stored, isNotNull);
    });

    test('no previous upload timestamp does not trigger an immediate upload',
        () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return http.Response('{}', 200);
      });

      PerformanceTelemetryUploader.debugOverride(
        client: client,
        stateStore: _InMemoryStateStore(null),
      );
      PerformanceTelemetryUploader.configure(apiKey: 'key', enabled: true);

      await PerformanceTelemetryUploader.checkAndMaybeUpload(_fakeSnapshot());

      expect(requestCount, 0);
    });
  });

  group('PerformanceTelemetryUploader — uploadNow', () {
    test('uploads immediately even if last upload was 30 minutes ago',
        () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return http.Response('{}', 200);
      });
      final store = _InMemoryStateStore(
        DateTime.now().subtract(const Duration(minutes: 30)),
      );

      PerformanceTelemetryUploader.debugOverride(
        client: client,
        stateStore: store,
      );
      PerformanceTelemetryUploader.configure(apiKey: 'key', enabled: true);

      await PerformanceTelemetryUploader.uploadNow();

      expect(requestCount, 1);
      expect(store.stored, isNotNull);
    });

    test('uploads immediately even with no previous upload timestamp',
        () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return http.Response('{}', 200);
      });

      PerformanceTelemetryUploader.debugOverride(
        client: client,
        stateStore: _InMemoryStateStore(null),
      );
      PerformanceTelemetryUploader.configure(apiKey: 'key', enabled: true);

      await PerformanceTelemetryUploader.uploadNow();

      expect(requestCount, 1);
    });

    test('does nothing when disabled', () async {
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        return http.Response('{}', 200);
      });

      PerformanceTelemetryUploader.debugOverride(
        client: client,
        stateStore: _InMemoryStateStore(),
      );
      PerformanceTelemetryUploader.configure(apiKey: 'key', enabled: false);

      await PerformanceTelemetryUploader.uploadNow();

      expect(requestCount, 0);
    });
  });

  group('PerformanceTelemetryUploader — success / failure', () {
    test('failed upload does not update lastPerformanceUploadAt', () async {
      final client = MockClient((request) async => http.Response('', 500));
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
      final client = MockClient((request) async => http.Response('{}', 200));
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
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response('{}', 200);
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

      expect(requestCount, 1);
    });
  });

  group('PerformanceTelemetryUploader — request contents', () {
    test('uses Bearer auth with the configured API key and correct URL',
        () async {
      http.Request? captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response('{}', 200);
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

      expect(captured, isNotNull);
      expect(
        captured!.headers['Authorization'],
        'Bearer my_test_api_key',
      );
      expect(
        captured!.url.toString(),
        endsWith('/api/v1/performance'),
      );

      final body = jsonDecode(captured!.body) as Map<String, dynamic>;
      expect(body['session_duration_ms'], 300000);
      expect(body['health_score'], 92);
      expect(body['jank']['total_frames'], 1000);
    });
  });
}
