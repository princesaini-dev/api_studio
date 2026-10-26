import 'dart:async';
import 'dart:io';

import 'package:api_studio/api_studio.dart';
import 'package:api_studio/src/api_client/core/api_studio_performance_uploader.dart';
import 'package:api_studio/src/api_client/core/api_studio_remote_logger.dart';
import 'package:api_studio/src/services/di_service.dart';
import 'package:api_studio/src/services/performance_monitor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers/fake_path_provider.dart';
import '../test_helpers/fake_simple_http_client.dart';

/// This file must not call `initialize(enabled: true)`: it proves that a
/// disabled API Studio never touches storage, timers, frame callbacks or
/// the network. (Each test file runs in its own isolate.)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late RecordingSimpleHttpClient network;

  setUpAll(() {
    tempDir = installFakePathProvider();
    network = RecordingSimpleHttpClient();
    ApiStudioRemoteLogger.debugOverride(client: network);
    PerformanceTelemetryUploader.debugOverride(client: network);
  });

  tearDownAll(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('enabled: false is a cheap no-op across every public API', () async {
    var timersCreated = 0;
    final logged = <ApiLogEntity>[];
    ApiStudio.debugLogListener = logged.add;

    await runZoned(
      () async {
        await ApiStudio.initialize(
          enabled: false,
          apiKey: 'would-enable-cloud-upload',
          enablePerformanceMonitoring: true,
          enableConnectivityStream: true,
          enableFailedApiStream: true,
        );
        await ApiStudio.log(
          url: 'https://api.example.com/fail',
          method: 'POST',
          statusCode: 500,
          requestHeaders: {'Authorization': 'Bearer secret'},
          errorMessage: 'boom',
        );
        ApiStudio.startPerformanceMonitoring();
        await ApiStudio.flush();
      },
      zoneSpecification: ZoneSpecification(
        createTimer: (self, parent, zone, duration, f) {
          timersCreated++;
          return parent.createTimer(zone, duration, f);
        },
        createPeriodicTimer: (self, parent, zone, period, f) {
          timersCreated++;
          return parent.createPeriodicTimer(zone, period, f);
        },
      ),
    );
    await pumpEventQueue();

    expect(ApiStudio.isInitialized, isTrue);
    expect(ApiStudio.isEnabled, isFalse);

    // No timers (remote upload, debounce, performance polling).
    expect(timersCreated, 0);

    // No storage: Hive was never opened and nothing was written to disk.
    expect(DiService.isInitialized, isFalse);
    expect(tempDir.listSync(recursive: true), isEmpty);

    // No frame callbacks: the performance monitor never started.
    expect(PerformanceMonitor.instance.isMonitoring, isFalse);

    // No network: neither uploader is configured and nothing was sent.
    expect(ApiStudioRemoteLogger.isEnabled, isFalse);
    expect(ApiStudioRemoteLogger.pendingPayloadCount, 0);
    expect(PerformanceTelemetryUploader.isEnabled, isFalse);
    expect(network.requests, isEmpty);

    // Nothing reached the logging pipeline.
    expect(logged, isEmpty);
    ApiStudio.debugLogListener = null;
  });

  testWidgets('UI entry points do nothing when disabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: ApiStudio.navigatorKey,
        home: Builder(
          builder: (context) => Column(
            children: [
              TextButton(
                onPressed: () {
                  ApiStudio.show(context);
                  ApiStudio.showNavigation(context);
                  ApiStudio.showFileExplorer(context);
                  ApiStudio.showPerformanceInspector(context);
                  ApiStudio.showFloatingButton(context);
                  ApiStudio.open();
                },
                child: const Text('open all'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const FileExplorerScreen(),
                  ),
                ),
                child: const Text('push explorer directly'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('open all'));
    await tester.pumpAndSettle();

    expect(find.byType(ApiStudioNavigationScreen), findsNothing);
    expect(find.byType(InspectorListScreen), findsNothing);
    expect(find.byType(FileExplorerScreen), findsNothing);
    expect(find.byType(PerformanceInspectorScreen), findsNothing);
    expect(find.byKey(const Key('apiStudioFloatingButton')), findsNothing);
    expect(ApiStudio.isFloatingButtonVisible, isFalse);

    // Even when pushed directly, the File Explorer refuses to browse.
    await tester.tap(find.text('push explorer directly'));
    await tester.pumpAndSettle();
    expect(find.textContaining('only available while API Studio is enabled'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
