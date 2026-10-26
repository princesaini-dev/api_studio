import 'dart:io';

import 'package:api_studio/api_studio.dart';
import 'package:api_studio/src/api_client/core/api_studio_remote_logger.dart';
import 'package:api_studio/src/api_client/core/simple_http_client.dart';
import 'package:api_studio/src/core/pipeline/log_pipeline.dart';
import 'package:api_studio/src/services/di_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers/fake_path_provider.dart';
import '../test_helpers/fake_simple_http_client.dart';

class _ThrowingClient extends SimpleHttpClient {
  @override
  Future<SimpleHttpResponse> post(Uri url,
          {required Map<String, String> headers,
          required String body,
          Duration? timeout}) =>
      Future.error(const SocketException('offline'));

  @override
  void close() {}
}

const _r = RedactionConfig.placeholder;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late RecordingSimpleHttpClient network;

  setUpAll(() async {
    tempDir = installFakePathProvider();
    network = RecordingSimpleHttpClient();
    ApiStudioRemoteLogger.debugOverride(client: network);
    await ApiStudio.initialize(
      enabled: true,
      apiKey: 'test-key',
      maxBodyBytes: 64,
      redaction: const RedactionConfig(redactHeaders: ['X-Custom-Secret']),
    );
  });

  tearDownAll(() {
    ApiStudioRemoteLogger.debugReset();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('redacts before local storage AND before remote upload', () async {
    await ApiStudio.log(
      url: 'https://api.example.com/login?token=t-1',
      method: 'POST',
      statusCode: 401,
      requestHeaders: {
        'Authorization': 'Bearer live-secret',
        'X-Custom-Secret': 'c',
      },
      requestBody: {'email': 'a@b.c', 'password': 'pw'},
      responseHeaders: {'set-cookie': 'sid=1'},
      responseBody: '{"refresh_token":"rt"}',
    );

    final stored = (await DiService.repository
            .getLogs(const GetLogsParams(searchQuery: 'login')))
        .single;
    expect(stored.url, 'https://api.example.com/login?token=$_r');
    expect(stored.requestHeaders['Authorization'], _r);
    expect(stored.requestHeaders['X-Custom-Secret'], _r);
    expect(stored.requestBody, '{"email":"a@b.c","password":"$_r"}');
    expect(stored.responseHeaders['set-cookie'], _r);
    expect(stored.responseBody, '{"refresh_token":"$_r"}');

    await ApiStudio.flush();
    final uploaded = network.requests.single;
    expect(uploaded.headers['Authorization'], 'Bearer test-key');
    final payload = uploaded.body! as Map<String, dynamic>;
    expect(payload['url'], 'https://api.example.com/login?token=$_r');
    expect(payload['request']['headers']['Authorization'], _r);
    expect(payload['request']['body'], {'email': 'a@b.c', 'password': _r});
    expect(payload['response']['headers']['set-cookie'], _r);
    expect(payload['response']['body'], {'refresh_token': _r});
    expect(payload.toString(), isNot(contains('live-secret')));
    expect(payload.toString(), isNot(contains('pw')));
  });

  test('truncates oversized bodies after redaction and flags them', () async {
    final big = '{"password":"pw","data":"${'x' * 200}"}';
    await ApiStudio.log(
      url: 'https://api.example.com/big',
      method: 'POST',
      statusCode: 200,
      requestBody: big,
    );

    final stored = (await DiService.repository
            .getLogs(const GetLogsParams(searchQuery: '/big')))
        .single;
    expect(stored.isTruncated, isTrue);
    expect(stored.requestSizeBytes, big.length);
    expect(stored.requestBody, startsWith('{"password":"$_r"'));
    expect(stored.requestBody, contains(LogPipeline.truncationMarker));
  });

  test('truncate() respects UTF-8 byte limits', () {
    final res = LogPipeline.truncate('é' * 100, 51);
    expect(res.truncated, isTrue);
    expect(res.value, contains('kept 51 of 200 bytes'));
    expect(LogPipeline.truncate('short', 64).truncated, isFalse);
    expect(LogPipeline.truncate(null, 64).value, isNull);
  });

  test('binary bodies become a placeholder', () async {
    await ApiStudio.log(
      url: 'https://api.example.com/bin',
      method: 'GET',
      statusCode: 200,
      responseBody: List<int>.filled(5000, 1),
    );
    final stored = (await DiService.repository
            .getLogs(const GetLogsParams(searchQuery: '/bin')))
        .single;
    expect(stored.responseBody, '[binary data: 5000 bytes]');
    expect(stored.responseSizeBytes, 5000);
    expect(stored.isTruncated, isFalse);
  });

  test('cancelled requests get the cancelled status', () async {
    await ApiStudio.log(
      url: 'https://api.example.com/cancelled',
      method: 'GET',
      cancelled: true,
      errorMessage: 'Request cancelled',
    );
    final stored = (await DiService.repository
            .getLogs(const GetLogsParams(searchQuery: '/cancelled')))
        .single;
    expect(stored.status, LogStatus.cancelled);
  });

  test('remote upload failures never throw into the host app', () async {
    ApiStudioRemoteLogger.debugOverride(client: _ThrowingClient());
    await expectLater(
      ApiStudio.log(
        url: 'https://api.example.com/err',
        method: 'GET',
        statusCode: 500,
      ),
      completes,
    );
    await expectLater(ApiStudio.flush(), completes);
    ApiStudioRemoteLogger.debugOverride(client: network);
  });
}
