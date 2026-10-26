import 'dart:io';

import 'package:api_studio/api_studio.dart';
import 'package:api_studio/src/services/di_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers/fake_path_provider.dart';

/// An unreadable log box (corruption, unknown type ids written by some
/// other adapter) must never crash startup: it is cleared and recreated.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    tempDir = installFakePathProvider();
    final dir = Directory('${tempDir.path}/${HiveConstants.hiveSubDir}')
      ..createSync(recursive: true);
    // A frame referencing an unregistered type id (200): hive_ce refuses
    // to open the box.
    File('${dir.path}/${HiveConstants.apiLogBoxName}.hive').writeAsBytesSync(
      [12, 0, 0, 0, 1, 1, 0x6B, 200, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    );
  });

  tearDownAll(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('initialize() recovers from an unreadable box', () async {
    await expectLater(ApiStudio.initialize(enabled: true), completes);
    expect(DiService.isInitialized, isTrue);
    expect(await DiService.repository.getTotalCount(), 0);

    await ApiStudio.log(url: 'https://a.b/c', method: 'GET', statusCode: 200);
    expect(await DiService.repository.getTotalCount(), 1);
  });
}
