import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Fakes the path_provider plugin so `Hive.initFlutter(...)` (used by
/// `DiService.init` / `ApiStudio.initialize`) can run in plain `flutter_test`
/// without a real platform channel, using a temporary directory instead.
class FakePathProviderPlatform extends PathProviderPlatform {
  final Directory _tempDir;

  FakePathProviderPlatform(this._tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async => _tempDir.path;

  @override
  Future<String?> getApplicationSupportPath() async => _tempDir.path;

  @override
  Future<String?> getTemporaryPath() async => _tempDir.path;

  @override
  Future<String?> getLibraryPath() async => _tempDir.path;
}

/// Installs [FakePathProviderPlatform] and returns the temp directory used,
/// so tests can clean it up in `tearDown`.
Directory installFakePathProvider() {
  final tempDir = Directory.systemTemp.createTempSync('api_studio_test_');
  PathProviderPlatform.instance = FakePathProviderPlatform(tempDir);
  return tempDir;
}
