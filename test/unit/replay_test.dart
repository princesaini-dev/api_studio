import 'dart:convert';
import 'dart:io';

import 'package:api_studio/api_studio.dart';
import 'package:api_studio/src/core/runtime/api_studio_runtime.dart';
import 'package:api_studio/src/core/utils/url_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ApiLogRepository {}

class _FakeLog extends Fake implements ApiLogEntity {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeLog()));

  group('UrlUtils.mergeQuery', () {
    test('preserves repeated keys and list values', () {
      final uri = UrlUtils.mergeQuery(
        'https://a.b/items?id=1&id=2',
        {
          'tag': ['x', 'y'],
          'page': 3,
        },
      )!;
      expect(uri.queryParametersAll, {
        'id': ['1', '2'],
        'tag': ['x', 'y'],
        'page': ['3'],
      });
    });

    test('is idempotent when params mirror the URL query', () {
      final uri = UrlUtils.mergeQuery('https://a.b/x?page=1', {'page': '1'})!;
      expect(uri.toString(), 'https://a.b/x?page=1');
    });
  });

  test('replayHeaders drops transport headers and flattens lists', () {
    final headers = RunRequestUseCase.replayHeaders({
      'Content-Length': '999',
      'host': 'old.example.com',
      'Accept': ['application/json', 'text/plain'],
      'X-Trace': 't',
    });
    expect(headers, {
      'Accept': 'application/json, text/plain',
      'X-Trace': 't',
    });
  });

  test('Edit & Run replays a Dio-captured log correctly over the wire',
      () async {
    ApiStudioRuntime.enabled = true;
    addTearDown(ApiStudioRuntime.debugReset);

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    late Uri receivedUri;
    late HttpHeaders receivedHeaders;
    late String receivedBody;
    server.listen((req) async {
      receivedUri = req.uri;
      receivedHeaders = req.headers;
      receivedBody = await utf8.decodeStream(req);
      req.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write('{"ok":true,"token":"server-token"}');
      await req.response.close();
    });

    final base = 'http://127.0.0.1:${server.port}';
    final captured = ApiLogEntity(
      id: 'orig',
      url: '$base/items?id=1&id=2',
      method: HttpMethod.post,
      requestHeaders: {
        'content-type': 'application/json',
        'content-length': '3',
        'accept': ['application/json', 'text/plain'],
      },
      queryParams: {
        'id': ['1', '2'],
      },
      requestBody: '{"a":1}',
      timestamp: DateTime(2026),
      responseHeaders: const {},
      status: LogStatus.success,
    );

    final repo = _MockRepo();
    when(() => repo.saveLog(any())).thenAnswer((_) async {});

    final edited = '{"a":1,"b":"a much longer edited body"}';
    final result = await RunRequestUseCase(repo)(RunRequestParams(
      originalLog: captured,
      url: captured.url,
      method: captured.method,
      headers: captured.requestHeaders,
      queryParams: captured.queryParams,
      body: edited,
      newId: 'replay',
    ));

    // Server received the real request: repeated query keys intact, stale
    // Content-Length dropped (so the longer body is not cut off), and
    // multi-value headers flattened.
    expect(receivedUri.queryParametersAll['id'], ['1', '2']);
    expect(receivedBody, edited);
    expect(receivedHeaders.value('accept'), 'application/json, text/plain');

    expect(result.statusCode, 200);
    expect(result.isEdited, isTrue);
    expect(result.parentId, 'orig');
    // The replay result is redacted before being stored.
    expect(result.responseBody, contains(RedactionConfig.placeholder));
    final stored = verify(() => repo.saveLog(captureAny())).captured.single
        as ApiLogEntity;
    expect(stored.responseBody, isNot(contains('server-token')));
  });
}
