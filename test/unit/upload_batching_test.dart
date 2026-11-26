import 'dart:convert';

import 'package:api_studio/src/api_client/core/api_studio_remote_logger.dart';
import 'package:api_studio/src/api_client/core/simple_http_client.dart';
import 'package:api_studio/src/crash/crash_reporter.dart';
import 'package:api_studio/src/domain/entities/api_log_entity.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records upload batches; each upload takes [latency] like a real network.
class _SlowBackend extends SimpleHttpClient {
  // Each upload takes as long as a real round trip.
  static const latency = Duration(milliseconds: 300);
  final List<int> batches = [];
  final List<int> crashUploads = [];

  @override
  Future<SimpleHttpResponse> post(
    Uri url, {
    required Map<String, String> headers,
    required String body,
    Duration? timeout,
    bool gzip = false,
  }) async {
    final json = jsonDecode(body) as Map<String, dynamic>;
    if (json['logs'] is List) {
      batches.add((json['logs'] as List).length);
    } else if (json['events'] is List) {
      crashUploads.add((json['events'] as List).length);
    }
    await Future<void>.delayed(latency);
    return SimpleHttpResponse(statusCode: 202, body: '{}');
  }

  @override
  void close() {}
}

ApiLogEntity _log(int i, {bool failed = false}) => ApiLogEntity(
      id: 'log-$i',
      url: 'https://api.example.com/v1/master/table$i',
      method: HttpMethod.get,
      requestHeaders: const {'Accept': 'application/json'},
      queryParams: const {},
      timestamp: DateTime.now(),
      durationMs: 120,
      statusCode: failed ? 500 : 200,
      responseBody: '{"rows":[]}',
      responseHeaders: const {'content-type': 'application/json'},
      status: failed ? LogStatus.error : LogStatus.success,
    );

/// Runs [calls] app API calls [gap] apart and returns the upload batches.
List<int> _simulate(
  FakeAsync async,
  _SlowBackend backend, {
  required int calls,
  required Duration gap,
  bool Function(int i)? failed,
}) {
  for (var i = 0; i < calls; i++) {
    ApiStudioRemoteLogger.enqueue(_log(i, failed: failed?.call(i) ?? false));
    async.elapse(gap);
  }
  async.elapse(const Duration(seconds: 30));
  return backend.batches;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _SlowBackend backend;

  setUp(() {
    ApiStudioRemoteLogger.debugReset();
    backend = _SlowBackend();
    ApiStudioRemoteLogger.debugOverride(client: backend);
  });

  tearDown(ApiStudioRemoteLogger.debugReset);

  group('a 50-call master sync', () {
    test('one after another (200 ms apart) costs 1–2 uploads, not 50', () {
      fakeAsync((async) {
        ApiStudioRemoteLogger.configure('key');
        final batches = _simulate(
          async,
          backend,
          calls: 50,
          gap: const Duration(milliseconds: 200),
        );
        expect(batches.length, lessThanOrEqualTo(2));
        expect(batches.fold<int>(0, (a, b) => a + b), 50);
        expect(ApiStudioRemoteLogger.pendingPayloadCount, 0);
      });
    });

    test('all at once goes as a single full batch', () {
      fakeAsync((async) {
        ApiStudioRemoteLogger.configure('key');
        final batches = _simulate(
          async,
          backend,
          calls: 50,
          gap: const Duration(milliseconds: 5),
        );
        expect(batches, [50]);
      });
    });

    test('with failures in it still costs only a few uploads', () {
      fakeAsync((async) {
        ApiStudioRemoteLogger.configure('key');
        final batches = _simulate(
          async,
          backend,
          calls: 50,
          gap: const Duration(milliseconds: 200),
          failed: (i) => i % 5 == 0,
        );
        // Each failure pulls its window in to 2 s: ~one upload per 2 s.
        expect(batches.length, lessThanOrEqualTo(6));
        expect(batches.fold<int>(0, (a, b) => a + b), 50);
      });
    });

    test('slow calls (2 s apart) send once per 10 s window', () {
      fakeAsync((async) {
        ApiStudioRemoteLogger.configure('key');
        final batches = _simulate(
          async,
          backend,
          calls: 50,
          gap: const Duration(seconds: 2),
        );
        // 100 s of calls -> about 10 windows (was 50 uploads before).
        expect(batches.length, lessThanOrEqualTo(11));
        expect(batches.fold<int>(0, (a, b) => a + b), 50);
      });
    });
  });

  test('a normal log waits for the 10 s window, a failure for 2 s', () {
    fakeAsync((async) {
      ApiStudioRemoteLogger.configure('key');
      ApiStudioRemoteLogger.enqueue(_log(1));
      async.elapse(const Duration(seconds: 9));
      expect(backend.batches, isEmpty);
      async.elapse(const Duration(seconds: 2));
      expect(backend.batches, [1]);

      ApiStudioRemoteLogger.enqueue(_log(2));
      async.elapse(const Duration(seconds: 1));
      ApiStudioRemoteLogger.enqueue(_log(3, failed: true));
      async.elapse(const Duration(milliseconds: 1900));
      expect(backend.batches, [1]);
      async.elapse(const Duration(milliseconds: 200));
      // The failure pulled the window in, and took the waiting log along.
      expect(backend.batches, [1, 2]);
    });
  });

  test('sends everything pending when the app goes to the background', () {
    fakeAsync((async) {
      ApiStudioRemoteLogger.configure('key');
      final binding = TestWidgetsFlutterBinding.instance;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      for (var i = 0; i < 3; i++) {
        ApiStudioRemoteLogger.enqueue(_log(i));
      }
      async.elapse(const Duration(milliseconds: 100));
      expect(backend.batches, isEmpty);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      async.elapse(const Duration(milliseconds: 500));
      expect(backend.batches, [3]);

      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      async.elapse(const Duration(seconds: 1));
      expect(backend.batches, [3]); // nothing left: no empty upload
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
  });

  test('a crash sends the waiting API logs right away, with the report', () {
    fakeAsync((async) {
      ApiStudioCrashReporter.debugReset();
      ApiStudioCrashReporter.debugOverride(client: backend);
      ApiStudioCrashReporter.configure(apiKey: 'key', enabled: true);
      addTearDown(ApiStudioCrashReporter.debugReset);
      ApiStudioRemoteLogger.configure('key');

      ApiStudioRemoteLogger.enqueue(_log(1));
      ApiStudioRemoteLogger.enqueue(_log(2));
      async.elapse(const Duration(milliseconds: 100));
      expect(backend.batches, isEmpty);

      ApiStudioCrashReporter.capture(
        StateError('Bad state: no element'),
        StackTrace.current,
        fatal: true,
        handled: false,
      );
      async.elapse(const Duration(milliseconds: 500));
      expect(backend.crashUploads, [1]);
      expect(backend.batches, [2]); // not 10 s later
    });
  });

  test('turning uploads off stops the window and the lifecycle flush', () {
    fakeAsync((async) {
      ApiStudioRemoteLogger.configure('key');
      ApiStudioRemoteLogger.enqueue(_log(1));
      ApiStudioRemoteLogger.configure(null);
      async.elapse(const Duration(seconds: 30));
      TestWidgetsFlutterBinding.instance
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(backend.batches, isEmpty);
    });
  });
}
