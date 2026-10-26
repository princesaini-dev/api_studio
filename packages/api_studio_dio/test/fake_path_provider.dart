import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  final Directory dir;
  _FakePathProvider(this.dir);

  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;

  @override
  Future<String?> getTemporaryPath() async => dir.path;
}

/// Points path_provider at a temp directory so `ApiStudio.initialize()` can
/// open its local storage in plain `flutter test`.
Directory installFakePathProvider() {
  final dir = Directory.systemTemp.createTempSync('api_studio_dio_test_');
  PathProviderPlatform.instance = _FakePathProvider(dir);
  return dir;
}
