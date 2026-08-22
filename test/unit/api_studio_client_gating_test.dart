import 'dart:io';

import 'package:api_studio/api_studio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers/fake_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    tempDir = installFakePathProvider();
  });

  tearDownAll(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('ApiStudio.initialize — enableApiClient gating', () {
    test(
      'enableApiClient: false never initializes ApiStudioClient',
      () async {
        await ApiStudio.initialize(
          baseUrl: 'https://api.example.com',
          enableApiClient: false,
        );

        expect(ApiStudio.isApiClientEnabled, isFalse);
        // Accessing the client before it was ever initialized must fail —
        // proving no client controller/network service was created.
        expect(() => ApiStudioClient.instance, throwsA(isA<AssertionError>()));
      },
    );

    test(
      'enableApiClient: true with a baseUrl initializes ApiStudioClient',
      () async {
        await ApiStudio.initialize(
          baseUrl: 'https://api.example.com',
          enableApiClient: true,
        );

        expect(ApiStudio.isApiClientEnabled, isTrue);
        expect(() => ApiStudioClient.instance, returnsNormally);
        expect(ApiStudioClient.instance.config.baseUrl,
            'https://api.example.com');
      },
    );
  });
}
