import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:api_studio/api_studio.dart' hide TimeoutException;
import 'package:api_studio_http/api_studio_http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fake_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  final logs = <ApiLogEntity>[];

  Future<ApiLogEntity> lastLog() async {
    await pumpEventQueue();
    expect(logs, isNotEmpty, reason: 'expected a captured log');
    return logs.last;
  }

  setUpAll(() async {
    tempDir = installFakePathProvider();
    await ApiStudio.initialize(enabled: true);
    ApiStudio.debugLogListener = logs.add;
  });

  tearDownAll(() {
    ApiStudio.debugLogListener = null;
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  setUp(logs.clear);

  test('captures a GET with headers, query params and redaction', () async {
    final client = ApiStudioHttpClient(
      inner: MockClient((req) async => http.Response(
            jsonEncode({'id': 1, 'access_token': 'tok'}),
            200,
            headers: {
              'content-type': 'application/json',
              'set-cookie': 'sid=1',
            },
          )),
    );

    final res = await client.get(
      Uri.parse('https://api.example.com/users?page=1&token=t-1'),
      headers: {'Authorization': 'Bearer x', 'Accept': 'application/json'},
    );
    expect(jsonDecode(res.body)['access_token'], 'tok',
        reason: 'the caller must receive the original, unredacted body');

    final log = await lastLog();
    expect(log.method, HttpMethod.get);
    expect(log.url,
        'https://api.example.com/users?page=1&token=${RedactionConfig.placeholder}');
    expect(
        log.queryParams, {'page': '1', 'token': RedactionConfig.placeholder});
    expect(log.requestHeaders['Authorization'], RedactionConfig.placeholder);
    expect(log.requestHeaders['Accept'], 'application/json');
    expect(log.statusCode, 200);
    expect(log.responseHeaders['set-cookie'], RedactionConfig.placeholder);
    expect(jsonDecode(log.responseBody!)['access_token'],
        RedactionConfig.placeholder);
    expect(log.durationMs, greaterThanOrEqualTo(0));
  });

  test('captures and redacts a JSON POST body', () async {
    final client = ApiStudioHttpClient(
      inner: MockClient((req) async => http.Response('{"ok":true}', 201,
          headers: {'content-type': 'application/json'})),
    );

    await client.post(
      Uri.parse('https://api.example.com/login'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'user': 'u', 'password': 'p@ss', 'cvv': '123'}),
    );

    final log = await lastLog();
    final body = jsonDecode(log.requestBody!) as Map<String, dynamic>;
    expect(body['user'], 'u');
    expect(body['password'], RedactionConfig.placeholder);
    expect(body['cvv'], RedactionConfig.placeholder);
    expect(log.statusCode, 201);
  });

  test('redacts form-urlencoded bodies', () async {
    final client = ApiStudioHttpClient(
      inner: MockClient((req) async => http.Response('', 204)),
    );

    await client.post(
      Uri.parse('https://api.example.com/oauth'),
      body: {'grant_type': 'password', 'password': 'secret', 'username': 'me'},
    );

    final log = await lastLog();
    expect(log.requestBody, contains('grant_type=password'));
    expect(
        log.requestBody, contains('password=${RedactionConfig.placeholder}'));
    expect(log.requestBody, isNot(contains('secret')));
  });

  test('describes multipart requests', () async {
    final client = ApiStudioHttpClient(
      inner: MockClient.streaming((req, body) async {
        await body.drain<void>();
        return http.StreamedResponse(Stream.value(utf8.encode('ok')), 200);
      }),
    );

    final req = http.MultipartRequest(
        'POST', Uri.parse('https://api.example.com/upload'))
      ..fields['title'] = 'doc'
      ..files.add(http.MultipartFile.fromBytes('file', List.filled(10, 1),
          filename: 'a.pdf'));
    await (await client.send(req)).stream.drain<void>();

    final log = await lastLog();
    expect(log.isMultipart, isTrue);
    expect(log.formData!['title'], 'doc');
    expect(log.formData!['file'], contains('a.pdf'));
    expect(log.formData!['file'], contains('10 bytes'));
  });

  test('records error status codes', () async {
    final client = ApiStudioHttpClient(
      inner: MockClient((req) async => http.Response('{"error":"nope"}', 404,
          headers: {'content-type': 'application/json'})),
    );

    await client.get(Uri.parse('https://api.example.com/missing'));

    final log = await lastLog();
    expect(log.statusCode, 404);
    expect(log.status, LogStatus.error);
    expect(log.responseBody, contains('nope'));
  });

  test('records thrown errors with stack trace and rethrows', () async {
    final client = ApiStudioHttpClient(
      inner: MockClient((req) async => throw http.ClientException('offline')),
    );

    await expectLater(
      client.get(Uri.parse('https://api.example.com/x')),
      throwsA(isA<http.ClientException>()),
    );

    final log = await lastLog();
    expect(log.status, LogStatus.error);
    expect(log.errorMessage, 'offline');
    expect(log.stackTrace, isNotEmpty);
  });

  test('labels timeouts from the inner client', () async {
    final client = ApiStudioHttpClient(
      inner: MockClient((req) async => throw TimeoutException('too slow')),
    );

    await expectLater(
      client.get(Uri.parse('https://api.example.com/slow')),
      throwsA(isA<TimeoutException>()),
    );

    final log = await lastLog();
    expect(log.errorMessage, startsWith('Timeout'));
  });

  test('records aborted requests as cancelled', () async {
    final client = ApiStudioHttpClient(
      inner: MockClient(
          (req) async => throw http.RequestAbortedException(req.url)),
    );

    await expectLater(
      client.get(Uri.parse('https://api.example.com/abort')),
      throwsA(isA<http.RequestAbortedException>()),
    );

    final log = await lastLog();
    expect(log.status, LogStatus.cancelled);
  });

  test('stores binary responses as a size placeholder', () async {
    final client = ApiStudioHttpClient(
      inner: MockClient((req) async => http.Response.bytes(
            Uint8List(3000),
            200,
            headers: {'content-type': 'image/png'},
          )),
    );

    final res = await client.get(Uri.parse('https://api.example.com/img'));
    expect(res.bodyBytes.length, 3000);

    final log = await lastLog();
    expect(log.responseBody, startsWith('[binary data:'));
    expect(log.responseSizeBytes, 3000);
  });

  test('streams large responses through intact and truncates the log',
      () async {
    final chunk = utf8.encode('a' * 64 * 1024);
    const chunks = 20; // 1.25 MB > 1 MB default limit
    final client = ApiStudioHttpClient(
      inner: MockClient.streaming((req, _) async => http.StreamedResponse(
            Stream.fromIterable(List.generate(chunks, (_) => chunk)),
            200,
            headers: {'content-type': 'text/plain'},
          )),
    );

    final res = await client.get(Uri.parse('https://api.example.com/big'));
    expect(res.bodyBytes.length, chunk.length * chunks);

    final log = await lastLog();
    expect(log.isTruncated, isTrue);
    expect(log.responseSizeBytes, chunk.length * chunks);
    expect(log.responseBody, contains('truncated by API Studio'));
  });

  test('passes through without capturing when disabled', () async {
    await ApiStudio.initialize(enabled: false);
    final client = ApiStudioHttpClient(
      inner: MockClient((req) async => http.Response('ok', 200)),
    );

    final res = await client.get(Uri.parse('https://api.example.com/off'));
    expect(res.body, 'ok');
    await pumpEventQueue();
    expect(logs, isEmpty);
  });
}
