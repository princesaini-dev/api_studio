import 'dart:convert';

import 'package:api_studio/api_studio.dart';
import 'package:api_studio/src/services/export_formats.dart';
import 'package:flutter_test/flutter_test.dart';

const _r = RedactionConfig.placeholder;

final _logs = [
  ApiLogEntity(
    id: '1',
    url: 'https://api.example.com/v1/users?page=2&token=abc',
    method: HttpMethod.post,
    requestHeaders: {
      'Authorization': 'Bearer secret-token',
      'Content-Type': 'application/json',
      'Accept': ['application/json', 'text/plain'],
    },
    queryParams: {'page': '2', 'token': 'abc'},
    requestBody: '{"name":"n","password":"pw"}',
    timestamp: DateTime.utc(2026, 10, 26, 10),
    durationMs: 120,
    statusCode: 201,
    responseBody: '{"id":7,"access_token":"at"}',
    responseHeaders: {
      'content-type': 'application/json',
      'set-cookie': 'sid=1'
    },
    requestSizeBytes: 28,
    responseSizeBytes: 30,
    status: LogStatus.success,
  ),
  ApiLogEntity(
    id: '2',
    url: 'https://api.example.com:8443/upload',
    method: HttpMethod.put,
    requestHeaders: const {},
    queryParams: const {},
    formData: {'title': 'doc', 'file': '[file: a.pdf, 10 bytes]', 'cvv': '1'},
    isMultipart: true,
    timestamp: DateTime.utc(2026, 10, 26, 11),
    errorMessage: 'Timeout (receiveTimeout)',
    responseHeaders: const {},
    status: LogStatus.error,
  ),
];

void expectNoSecrets(String out) {
  for (final secret in ['secret-token', '"pw"', 'token=abc', '"at"', 'sid=1']) {
    expect(out, isNot(contains(secret)), reason: 'leaked $secret');
  }
}

void main() {
  test('JSON export is redacted and includes truncation/form data', () {
    final out = ExportFormats.toJson(_logs);
    expectNoSecrets(out);
    final list = jsonDecode(out) as List<dynamic>;
    expect(list, hasLength(2));
    expect(list[0]['requestHeaders']['Authorization'], _r);
    expect(list[0]['isTruncated'], isFalse);
    expect(list[1]['formData']['cvv'], _r);
  });

  test('TXT export is redacted', () {
    final out = ExportFormats.toTxt(_logs, generatedAt: DateTime(2026));
    expectNoSecrets(out);
    expect(out, contains('API Studio — Export'));
    expect(out, contains('Total: 2 requests'));
    expect(out, contains('POST https://api.example.com/v1/users'));
    expect(out, contains('Error: Timeout (receiveTimeout)'));
  });

  test('HAR export follows the HAR 1.2 structure and is redacted', () {
    final out = ExportFormats.toHar(_logs);
    expectNoSecrets(out);
    final har = jsonDecode(out) as Map<String, dynamic>;
    final log = har['log'] as Map<String, dynamic>;
    expect(log['version'], '1.2');
    expect(log['creator']['name'], 'API Studio');
    expect(log['creator']['version'], AppConstants.packageVersion);

    final entries = log['entries'] as List<dynamic>;
    expect(entries, hasLength(2));

    final first = entries[0] as Map<String, dynamic>;
    expect(first['startedDateTime'], '2026-10-26T10:00:00.000Z');
    expect(first['time'], 120);
    expect(first['timings'], {'send': 0, 'wait': 120, 'receive': 0});
    final req = first['request'] as Map<String, dynamic>;
    expect(req['method'], 'POST');
    expect(req['httpVersion'], 'HTTP/1.1');
    expect(req['headers'],
        contains(equals({'name': 'Authorization', 'value': _r})));
    expect(
        req['headers'],
        contains(equals(
            {'name': 'Accept', 'value': 'application/json, text/plain'})));
    expect(
        req['queryString'], contains(equals({'name': 'page', 'value': '2'})));
    expect(
        req['queryString'], contains(equals({'name': 'token', 'value': _r})));
    expect(req['postData']['mimeType'], 'application/json');
    expect(jsonDecode(req['postData']['text'] as String),
        {'name': 'n', 'password': _r});
    final res = first['response'] as Map<String, dynamic>;
    expect(res['status'], 201);
    expect(res['content']['mimeType'], 'application/json');
    expect(res['content']['size'], 30);
    for (final key in ['cookies', 'headersSize', 'bodySize', 'redirectURL']) {
      expect(res.containsKey(key), isTrue, reason: 'response.$key required');
    }

    final second = entries[1] as Map<String, dynamic>;
    expect(second['request']['postData']['mimeType'], 'multipart/form-data');
    expect(second['request']['postData']['params'],
        contains(equals({'name': 'cvv', 'value': _r})));
    expect(second['response']['status'], 0);
    expect(second['comment'], 'Timeout (receiveTimeout)');
  });

  test('Postman export is a v2.1 collection and is redacted', () {
    final out = ExportFormats.toPostman(_logs, generatedAt: DateTime(2026));
    expectNoSecrets(out);
    final col = jsonDecode(out) as Map<String, dynamic>;
    expect(col['info']['schema'],
        'https://schema.getpostman.com/json/collection/v2.1.0/collection.json');

    final items = col['item'] as List<dynamic>;
    expect(items, hasLength(2));

    final first = items[0]['request'] as Map<String, dynamic>;
    expect(items[0]['name'], 'POST /v1/users');
    expect(first['method'], 'POST');
    expect(first['header'],
        contains(equals({'key': 'Authorization', 'value': _r})));
    expect(first['url']['protocol'], 'https');
    expect(first['url']['host'], ['api', 'example', 'com']);
    expect(first['url']['path'], ['v1', 'users']);
    expect(
        first['url']['query'], contains(equals({'key': 'token', 'value': _r})));
    expect(first['body']['mode'], 'raw');
    expect(first['body']['options']['raw']['language'], 'json');

    final second = items[1]['request'] as Map<String, dynamic>;
    expect(second['url']['port'], '8443');
    expect(second['body']['mode'], 'formdata');
    expect(second['body']['formdata'],
        contains(equals({'key': 'cvv', 'value': _r, 'type': 'text'})));
  });
}
