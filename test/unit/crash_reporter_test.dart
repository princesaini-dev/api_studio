import 'dart:async';
import 'dart:ui';

import 'package:api_studio/src/api_client/core/api_studio_remote_logger.dart';
import 'package:api_studio/src/core/constants/app_constants.dart';
import 'package:api_studio/src/crash/crash_breadcrumbs.dart';
import 'package:api_studio/src/crash/crash_reporter.dart';
import 'package:api_studio/src/domain/entities/api_log_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers/fake_simple_http_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecordingSimpleHttpClient http;
  late FlutterExceptionHandler? originalFlutterHandler;
  late ErrorCallback? originalPlatformHandler;

  setUp(() {
    originalFlutterHandler = FlutterError.onError;
    originalPlatformHandler = PlatformDispatcher.instance.onError;
    ApiStudioCrashReporter.debugReset();
    CrashBreadcrumbs.debugReset();
    http = RecordingSimpleHttpClient(statusCode: 202);
    ApiStudioCrashReporter.debugOverride(client: http);
  });

  tearDown(() {
    ApiStudioCrashReporter.debugReset();
    CrashBreadcrumbs.debugReset();
    FlutterError.onError = originalFlutterHandler;
    PlatformDispatcher.instance.onError = originalPlatformHandler;
  });

  List<Map<String, dynamic>> sentEvents() => [
        for (final r in http.requests)
          for (final e in (r.body! as Map)['events'] as List)
            e as Map<String, dynamic>,
      ];

  test('disabled by default: nothing is captured or sent', () async {
    ApiStudioCrashReporter.capture(StateError('x'), StackTrace.current);
    await Future<void>.delayed(Duration.zero);
    expect(http.requests, isEmpty);
    expect(ApiStudioCrashReporter.isEnabled, isFalse);
  });

  test('requires an API key', () {
    ApiStudioCrashReporter.configure(apiKey: '  ', enabled: true);
    expect(ApiStudioCrashReporter.isEnabled, isFalse);
  });

  test('builds a payload with breadcrumbs and context', () {
    ApiStudioRemoteLogger.setAppInfo(version: '2.4.0', build: '118');
    ApiStudioRemoteLogger.setUser(id: 'tester-7');
    CrashBreadcrumbs.add(category: 'user', message: 'Tapped Pay');

    final payload = ApiStudioCrashReporter.buildPayload(
      StateError('Bad state'),
      StackTrace.current,
      fatal: true,
      handled: false,
      tags: {'screen': 'checkout'},
      extra: {'cart_id': 'c1', 'empty': null},
    );

    expect(payload['exception_type'], 'StateError');
    expect(payload['message'], 'Bad state: Bad state');
    expect(payload['stack_trace'], contains('crash_reporter_test.dart'));
    expect(payload['fatal'], isTrue);
    expect(payload['handled'], isFalse);
    expect(payload['session_id'], ApiStudioRemoteLogger.sessionId);
    expect(payload['app'], {'version': '2.4.0', 'build': '118'});
    expect(payload['user'], {'id': 'tester-7'});
    expect(payload['tags'], {'screen': 'checkout'});
    expect(payload['extra'], {'cart_id': 'c1'});
    expect((payload['breadcrumbs']! as List).single['message'], 'Tapped Pay');
    expect(payload['sdk'], {'name': 'api_studio', 'version': AppConstants.sdkVersion});

    ApiStudioRemoteLogger.setAppInfo();
    ApiStudioRemoteLogger.setUser();
  });

  test('captured errors are uploaded to the errors batch endpoint', () async {
    ApiStudioCrashReporter.configure(apiKey: 'sdk-key', enabled: true);
    ApiStudioCrashReporter.capture(StateError('boom'), StackTrace.current);
    await pumpEventQueue();

    expect(http.requests, hasLength(1));
    final request = http.requests.single;
    expect(request.url.toString(), AppConstants.apiStudioErrorsBatchUrl);
    expect(request.headers['Authorization'], 'Bearer sdk-key');
    expect(request.gzip, isTrue);
    expect(sentEvents().single['exception_type'], 'StateError');
    expect(ApiStudioCrashReporter.pendingCount, 0);
  });

  test('server errors keep the report queued for a retry', () async {
    http.statusCode = 503;
    ApiStudioCrashReporter.configure(apiKey: 'sdk-key', enabled: true);
    ApiStudioCrashReporter.capture(StateError('boom'), StackTrace.current);
    await pumpEventQueue();

    expect(http.requests, hasLength(1));
    expect(ApiStudioCrashReporter.pendingCount, 1);
  });

  test('rejected reports are dropped so they never block the queue', () async {
    http.statusCode = 422;
    ApiStudioCrashReporter.configure(apiKey: 'sdk-key', enabled: true);
    ApiStudioCrashReporter.capture(StateError('boom'), StackTrace.current);
    await pumpEventQueue();
    expect(ApiStudioCrashReporter.pendingCount, 0);
  });

  test('the same error is reported at most 3 times per session', () async {
    ApiStudioCrashReporter.configure(apiKey: 'sdk-key', enabled: true);
    for (var i = 0; i < 10; i++) {
      // Same throw site every iteration.
      try {
        throw StateError('loop');
      } catch (e, st) {
        ApiStudioCrashReporter.capture(e, st);
      }
      await pumpEventQueue();
    }
    expect(sentEvents(), hasLength(ApiStudioCrashReporter.maxReportsPerErrorPerSession));
  });

  test('chains onto existing FlutterError.onError handlers', () async {
    final seen = <FlutterErrorDetails>[];
    FlutterError.onError = seen.add;
    ApiStudioCrashReporter.configure(apiKey: 'sdk-key', enabled: true);

    final details = FlutterErrorDetails(
      exception: FlutterError('RenderFlex overflowed'),
      stack: StackTrace.current,
      library: 'rendering library',
    );
    FlutterError.onError!(details);
    await pumpEventQueue();

    expect(seen, [details]);
    final event = sentEvents().single;
    expect(event['exception_type'], 'FlutterError');
    expect(event['handled'], isFalse);
    expect(event['fatal'], isFalse);
    expect(event['extra'], containsPair('library', 'rendering library'));
  });

  test('silent Flutter errors are not reported', () async {
    FlutterError.onError = (_) {};
    ApiStudioCrashReporter.configure(apiKey: 'sdk-key', enabled: true);
    FlutterError.onError!(FlutterErrorDetails(exception: Exception('img'), silent: true));
    await pumpEventQueue();
    expect(http.requests, isEmpty);
  });

  test('chains onto PlatformDispatcher.onError and keeps its result', () async {
    Object? seen;
    PlatformDispatcher.instance.onError = (error, stack) {
      seen = error;
      return true;
    };
    ApiStudioCrashReporter.configure(apiKey: 'sdk-key', enabled: true);

    final handled = PlatformDispatcher.instance.onError!(ArgumentError('async'), StackTrace.current);
    await pumpEventQueue();

    expect(handled, isTrue);
    expect(seen, isA<ArgumentError>());
    expect(sentEvents().single['fatal'], isTrue);
  });

  test('disabling restores the previous handlers', () {
    void previous(FlutterErrorDetails _) {}
    FlutterError.onError = previous;
    ApiStudioCrashReporter.configure(apiKey: 'sdk-key', enabled: true);
    expect(FlutterError.onError, isNot(previous));

    ApiStudioCrashReporter.configure(apiKey: 'sdk-key', enabled: false);
    expect(FlutterError.onError, previous);
  });

  group('breadcrumbs', () {
    test('API calls drop query strings and keep status and timing', () {
      CrashBreadcrumbs.addApiCall(ApiLogEntity(
        id: '1',
        url: 'https://api.shop.com/v1/checkout?token=secret',
        method: HttpMethod.post,
        requestHeaders: const {},
        queryParams: const {'token': 'secret'},
        responseHeaders: const {},
        timestamp: DateTime(2026, 11, 16),
        statusCode: 500,
        durationMs: 812,
        status: LogStatus.error,
      ));
      final crumb = CrashBreadcrumbs.items.single;
      expect(crumb['category'], 'http');
      expect(crumb['message'], 'POST https://api.shop.com/v1/checkout 500');
      expect(crumb['level'], 'error');
      expect(crumb['data'], {
        'method': 'POST',
        'url': 'https://api.shop.com/v1/checkout',
        'status_code': 500,
        'duration_ms': 812,
      });
      expect(crumb.toString(), isNot(contains('secret')));
    });

    test('keeps only the most recent breadcrumbs', () {
      for (var i = 0; i < 100; i++) {
        CrashBreadcrumbs.add(category: 'log', message: 'step $i');
      }
      expect(CrashBreadcrumbs.items, hasLength(CrashBreadcrumbs.maxBreadcrumbs));
      expect(CrashBreadcrumbs.items.last['message'], 'step 99');
    });

    testWidgets('navigator observer records named routes', (tester) async {
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
        navigatorKey: key,
        navigatorObservers: [ApiStudioNavigatorObserver()],
        initialRoute: '/home',
        routes: {
          '/home': (_) => const SizedBox(),
          '/cart': (_) => const SizedBox(),
        },
      ));
      unawaited(key.currentState!.pushNamed('/cart'));
      await tester.pumpAndSettle();

      final nav = CrashBreadcrumbs.items.where((c) => c['category'] == 'navigation').toList();
      expect(nav.last['message'], 'push → /cart');
      expect(nav.last['data'], {'action': 'push', 'to': '/cart', 'from': '/home'});
    });
  });
}
