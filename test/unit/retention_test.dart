import 'dart:typed_data';

import 'package:api_studio/api_studio.dart';
import 'package:api_studio/src/data/datasources/hive_datasource.dart';
import 'package:api_studio/src/data/datasources/hive_storage.dart';
import 'package:api_studio/src/data/models/api_log_hive_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  var boxCounter = 0;
  late DateTime now;

  setUpAll(ApiStudioHive.registerAdapters);

  Future<Box<ApiLogHiveModel>> memoryBox() =>
      Hive.openBox<ApiLogHiveModel>('retention_${boxCounter++}',
          bytes: Uint8List(0));

  ApiLogHiveModel model(String id, DateTime timestamp, {int bodyChars = 0}) =>
      ApiLogHiveModel.fromEntity(ApiLogEntity(
        id: id,
        url: 'https://a.b/$id',
        method: HttpMethod.get,
        requestHeaders: const {},
        queryParams: const {},
        responseHeaders: const {},
        responseBody: bodyChars == 0 ? null : 'x' * bodyChars,
        timestamp: timestamp,
        status: LogStatus.success,
      ));

  setUp(() => now = DateTime(2026, 10, 26, 12));

  test('maxStoredLogs keeps the newest logs (not the first keys)', () async {
    final box = await memoryBox();
    final ds = HiveApiLogDataSource(box,
        maxStoredLogs: 3, retention: Duration.zero, clock: () => now);

    // Keys deliberately sort opposite to age: "z…" is the oldest.
    final ids = ['z', 'y', 'x', 'w', 'v'];
    for (var i = 0; i < ids.length; i++) {
      await ds.saveLog(model(ids[i], now.add(Duration(minutes: i))));
    }

    expect(box.length, 3);
    expect(box.keys.toSet(), {'x', 'w', 'v'});
  });

  test('logRetention prunes logs older than the window', () async {
    final box = await memoryBox();
    await box.put('old', model('old', now.subtract(const Duration(days: 8))));
    await box.put('edge', model('edge', now.subtract(const Duration(days: 6))));
    await box.put('new', model('new', now));

    final ds = HiveApiLogDataSource(box,
        retention: const Duration(days: 7), clock: () => now);
    final removed = await ds.prune();

    expect(removed, 1);
    expect(box.keys.toSet(), {'edge', 'new'});
  });

  test('age-based pruning also runs on save once the interval passes',
      () async {
    final box = await memoryBox();
    final ds = HiveApiLogDataSource(box,
        retention: const Duration(days: 7), clock: () => now);
    await ds.saveLog(model('a', now));

    now = now.add(const Duration(days: 8));
    await ds.saveLog(model('b', now));

    expect(box.keys.toSet(), {'b'});
  });

  test('maxStorageBytes evicts oldest logs when large bodies pile up',
      () async {
    final box = await memoryBox();
    final ds = HiveApiLogDataSource(box,
        retention: Duration.zero, maxStorageBytes: 25000, clock: () => now);

    for (var i = 0; i < 5; i++) {
      await ds.saveLog(
          model('big$i', now.add(Duration(seconds: i)), bodyChars: 10000));
    }

    expect(box.keys.toSet(), {'big3', 'big4'});
    final total = box.values.fold<int>(0, (s, m) => s + m.approximateSizeBytes);
    expect(total, lessThanOrEqualTo(25000));
  });

  test('defaults: 500 logs, 7 days, 1 MB bodies', () {
    expect(AppConstants.maxStoredLogs, 500);
    expect(AppConstants.logRetention, const Duration(days: 7));
    expect(AppConstants.defaultMaxBodyBytes, 1024 * 1024);
  });
}
