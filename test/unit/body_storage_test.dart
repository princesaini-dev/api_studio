import 'dart:io';

import 'package:api_studio/api_studio.dart';
import 'package:api_studio/src/data/datasources/hive_datasource.dart';
import 'package:api_studio/src/data/datasources/hive_storage.dart';
import 'package:api_studio/src/data/models/api_log_hive_model.dart';
import 'package:api_studio/src/data/repositories/api_log_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

/// Schema 3: bodies live in a lazy box, not in memory with every log.
void main() {
  late Directory dir;
  var n = 0;

  setUpAll(() {
    dir = Directory.systemTemp.createTempSync('api_studio_bodies_');
    ApiStudioHive.registerAdapters();
  });

  tearDownAll(() async {
    await Hive.close();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  ApiLogEntity log(String id, {String? req, String? res}) => ApiLogEntity(
        id: id,
        url: 'https://api.example.com/$id',
        method: HttpMethod.post,
        requestHeaders: const {},
        queryParams: const {},
        responseHeaders: const {},
        status: LogStatus.success,
        timestamp: DateTime.now(),
        statusCode: 200,
        requestBody: req,
        responseBody: res,
      );

  Future<
      ({
        Box<ApiLogHiveModel> logs,
        LazyBox<String> bodies,
        ApiLogRepositoryImpl repo
      })> open() async {
    n++;
    final logs = await Hive.openBox<ApiLogHiveModel>('logs$n', path: dir.path);
    final bodies = await Hive.openLazyBox<String>('bodies$n', path: dir.path);
    final repo =
        ApiLogRepositoryImpl(HiveApiLogDataSource(logs, bodies: bodies));
    return (logs: logs, bodies: bodies, repo: repo);
  }

  test('bodies are stored outside the in-memory log box', () async {
    final s = await open();
    await s.repo.saveLog(log('a', req: '{"q":1}', res: 'x' * 5000));

    final inline = s.logs.get('a')!;
    expect(inline.requestBody, isNull);
    expect(inline.responseBody, isNull);
    expect(inline.responseBodyLength, 5000);
    expect(inline.approximateSizeBytes, greaterThan(5000));
    expect(await s.bodies.get('a/s'), 'x' * 5000);
  });

  test('lists skip bodies; detail and default getLogs hydrate them', () async {
    final s = await open();
    await s.repo.saveLog(log('a', req: 'REQ', res: 'RES'));

    final list =
        await s.repo.getLogs(const GetLogsParams(includeBodies: false));
    expect(list.single.responseBody, isNull);

    final full = await s.repo.getLogs(const GetLogsParams());
    expect(full.single.requestBody, 'REQ');
    expect(full.single.responseBody, 'RES');

    final one = await s.repo.getLogById('a');
    expect(one!.responseBody, 'RES');
  });

  test('delete, clear and update keep the body box in sync', () async {
    final s = await open();
    await s.repo.saveLog(log('a', req: 'A', res: 'A'));
    await s.repo.saveLog(log('b', req: 'B', res: 'B'));

    await s.repo.updateLog(log('b', res: 'B2'));
    expect(await s.bodies.get('b/q'), isNull);
    expect((await s.repo.getLogById('b'))!.responseBody, 'B2');

    await s.repo.deleteLog('a');
    expect(await s.bodies.get('a/q'), isNull);
    expect(await s.bodies.get('a/s'), isNull);

    await s.repo.clearAllLogs();
    expect(s.bodies.length, 0);
  });

  test('schema 2 boxes with inline bodies are migrated', () async {
    n++;
    final logs = await Hive.openBox<ApiLogHiveModel>('logs$n', path: dir.path);
    await logs.put('old', ApiLogHiveModel.fromEntity(log('old', res: 'OLD')));
    final bodies = await Hive.openLazyBox<String>('bodies$n', path: dir.path);

    await LogStorageMigrator.moveBodiesOut(logs, bodies);

    expect(logs.get('old')!.responseBody, isNull);
    expect(logs.get('old')!.responseBodyLength, 3);
    expect(await bodies.get('old/s'), 'OLD');
    final repo =
        ApiLogRepositoryImpl(HiveApiLogDataSource(logs, bodies: bodies));
    expect((await repo.getLogById('old'))!.responseBody, 'OLD');
  });
}
