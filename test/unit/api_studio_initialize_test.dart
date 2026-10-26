import 'dart:io';

import 'package:api_studio/api_studio.dart';
import 'package:api_studio/src/api_client/core/api_studio_remote_logger.dart';
import 'package:api_studio/src/services/di_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers/fake_path_provider.dart';
import '../test_helpers/fake_simple_http_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    tempDir = installFakePathProvider();
    // Never hit the real API Studio backend from tests.
    ApiStudioRemoteLogger.debugOverride(client: RecordingSimpleHttpClient());
  });

  tearDownAll(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('ApiStudio.initialize — unified configuration', () {
    test('succeeds with valid apiKey, baseUrl and enableApiClient', () async {
      await ApiStudio.initialize(
        apiKey: 'test-key-1',
        baseUrl: 'https://api.example.com',
        enableApiClient: true,
      );

      expect(ApiStudio.isInitialized, isTrue);
      expect(ApiStudio.isApiClientEnabled, isTrue);
      expect(ApiStudio.configuredBaseUrl, 'https://api.example.com');
      expect(ApiStudioRemoteLogger.isEnabled, isTrue);
    });

    test('multiple initialize() calls apply the latest configuration',
        () async {
      await ApiStudio.initialize(
        apiKey: 'test-key-2',
        baseUrl: 'https://second.example.com',
        enableApiClient: true,
      );

      expect(ApiStudio.configuredBaseUrl, 'https://second.example.com');
      expect(ApiStudioRemoteLogger.isEnabled, isTrue);

      // Re-initializing must never throw.
      await expectLater(
        ApiStudio.initialize(
          apiKey: null,
          baseUrl: 'https://third.example.com',
          enableApiClient: true,
        ),
        completes,
      );
      expect(ApiStudio.configuredBaseUrl, 'https://third.example.com');
      // A null apiKey on a later call disables remote logging again.
      expect(ApiStudioRemoteLogger.isEnabled, isFalse);
    });

    test('null or empty apiKey disables remote logging without throwing',
        () async {
      await expectLater(
        ApiStudio.initialize(apiKey: '', baseUrl: 'https://example.com'),
        completes,
      );
      expect(ApiStudioRemoteLogger.isEnabled, isFalse);
    });

    test('empty/blank baseUrl is treated as not provided', () async {
      await ApiStudio.initialize(
        apiKey: 'test-key-3',
        baseUrl: '   ',
        enableApiClient: true,
      );

      expect(ApiStudio.configuredBaseUrl, isNull);
    });

    test('enableApiClient is stored and reflected via isApiClientEnabled',
        () async {
      await ApiStudio.initialize(enableApiClient: false);
      expect(ApiStudio.isApiClientEnabled, isFalse);

      await ApiStudio.initialize(enableApiClient: true);
      expect(ApiStudio.isApiClientEnabled, isTrue);
    });

    test('ApiStudio.log logs custom requests and ApiStudio.flush completes',
        () async {
      await ApiStudio.initialize(
        apiKey: 'test-key-log',
        baseUrl: 'https://example.com',
      );

      await expectLater(
        ApiStudio.log(
          url: 'https://example.com/custom/test',
          method: 'POST',
          statusCode: 201,
          durationMs: 42,
          requestHeaders: {'Content-Type': 'application/json'},
          requestBody: '{"hello":"world"}',
          responseBody: '{"success":true}',
        ),
        completes,
      );

      // Verify the log was written to Hive repository
      final logs = await DiService.repository.getLogs(
        const GetLogsParams(searchQuery: 'custom/test'),
      );
      expect(logs.any((l) => l.url.contains('custom/test')), isTrue);

      // Verify flush executes cleanly
      await expectLater(ApiStudio.flush(), completes);
    });
  });
}
