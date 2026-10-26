import 'dart:convert';
import 'dart:io';

import 'package:api_studio/api_studio.dart';
import 'package:api_studio/src/data/datasources/hive_storage.dart';
import 'package:api_studio/src/services/di_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers/fake_path_provider.dart';

/// Upgrading from API Studio 1.0.7 (`hive` 2.x, unredacted logs) to 1.1.0
/// (`hive_ce`, redacted logs) must keep existing logs readable and scrub
/// the secrets they contain.
///
/// The fixture was written by `hive` 2.2.3 using the exact generated
/// adapter shipped in 1.0.7.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    tempDir = installFakePathProvider();
    final dir = Directory('${tempDir.path}/${HiveConstants.hiveSubDir}')
      ..createSync(recursive: true);
    File('test/fixtures/hive2_v1.0.7_api_studio_logs.hive')
        .copySync('${dir.path}/${HiveConstants.apiLogBoxName}.hive');
  });

  tearDownAll(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('reads 1.0.7 logs with hive_ce and redacts them in place', () async {
    await ApiStudio.initialize(enabled: true);
    expect(DiService.isInitialized, isTrue);

    final logs = await DiService.repository.getLogs(const GetLogsParams());
    expect(logs, hasLength(3));

    for (final log in logs) {
      expect(log.id, startsWith('legacy-'));
      expect(log.method, HttpMethod.post);
      expect(log.statusCode, 200);
      expect(log.durationMs, 120);
      expect(log.isTruncated, isFalse);
      expect(log.requestHeaders['Accept'], 'application/json');
      expect(log.requestHeaders['Authorization'], RedactionConfig.placeholder);
      expect(log.responseHeaders['set-cookie'], RedactionConfig.placeholder);
      expect(log.queryParams['token'], RedactionConfig.placeholder);
      expect(log.url, contains('token=${RedactionConfig.placeholder}'));
      expect(log.requestBody, contains('"user":"u"'));
      final serialized = jsonEncode([
        log.url,
        log.requestHeaders,
        log.queryParams,
        log.requestBody,
        log.responseHeaders,
        log.responseBody,
      ]);
      expect(serialized, isNot(contains('leaked')));
    }

    // The scrubbed values were written back to disk, not just to memory.
    final raw = File('${tempDir.path}/${HiveConstants.hiveSubDir}/'
            '${HiveConstants.apiLogBoxName}.hive')
        .readAsBytesSync();
    expect(String.fromCharCodes(raw), isNot(contains('leaked-secret')));

    final meta =
        await ApiStudioHive.openBox<dynamic>(HiveConstants.metaBoxName);
    expect(meta.get(HiveConstants.schemaVersionKey),
        LogStorageMigrator.currentSchemaVersion);
  });

  test('new logs are written with the new isTruncated field', () async {
    await ApiStudio.log(
      url: 'https://api.example.com/new',
      method: 'GET',
      statusCode: 200,
    );
    final logs = await DiService.repository
        .getLogs(const GetLogsParams(searchQuery: '/new'));
    expect(logs.single.isTruncated, isFalse);
  });
}
