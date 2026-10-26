import 'dart:convert';

import 'package:api_studio/api_studio.dart';
import 'package:api_studio/src/core/redaction/redactor.dart';
import 'package:flutter_test/flutter_test.dart';

const _r = RedactionConfig.placeholder;

ApiLogEntity _log({
  String url = 'https://api.example.com/x',
  Map<String, dynamic> requestHeaders = const {},
  Map<String, dynamic> responseHeaders = const {},
  Map<String, dynamic> queryParams = const {},
  String? requestBody,
  String? responseBody,
  Map<String, dynamic>? formData,
}) =>
    ApiLogEntity(
      id: '1',
      url: url,
      method: HttpMethod.post,
      requestHeaders: requestHeaders,
      responseHeaders: responseHeaders,
      queryParams: queryParams,
      requestBody: requestBody,
      responseBody: responseBody,
      formData: formData,
      timestamp: DateTime(2026),
      status: LogStatus.success,
    );

void main() {
  group('headers', () {
    test('redacts the default headers case-insensitively', () {
      final out = Redactor(const RedactionConfig()).redact(_log(
        requestHeaders: {
          'authorization': 'Bearer a',
          'COOKIE': 'c=1',
          'X-Api-Key': 'k',
          'Proxy-Authorization': 'p',
          'Accept': 'application/json',
        },
        responseHeaders: {'Set-Cookie': 's=1', 'Content-Type': 'text/plain'},
      ));
      expect(out.requestHeaders, {
        'authorization': _r,
        'COOKIE': _r,
        'X-Api-Key': _r,
        'Proxy-Authorization': _r,
        'Accept': 'application/json',
      });
      expect(out.responseHeaders,
          {'Set-Cookie': _r, 'Content-Type': 'text/plain'});
    });

    test('user additions extend the defaults', () {
      final out = Redactor(const RedactionConfig(redactHeaders: ['X-Session']))
          .redact(
              _log(requestHeaders: {'x-session': 's', 'Authorization': 'a'}));
      expect(out.requestHeaders, {'x-session': _r, 'Authorization': _r});
    });

    test('includeDefaults: false only applies user lists', () {
      final out = Redactor(const RedactionConfig(
        includeDefaults: false,
        redactHeaders: ['X-Only'],
      )).redact(_log(
        requestHeaders: {'Authorization': 'a', 'X-Only': 'o'},
        requestBody: '{"password":"p"}',
      ));
      expect(out.requestHeaders, {'Authorization': 'a', 'X-Only': _r});
      expect(out.requestBody, '{"password":"p"}');
    });
  });

  group('JSON bodies', () {
    test('redacts default keys recursively in maps and lists', () {
      final body = jsonEncode({
        'user': {'name': 'n', 'password': 'p', 'card_number': '4111'},
        'items': [
          {'token': 't', 'id': 1},
          {'cvv': '123'},
        ],
        'secret': {'nested': 'whole subtree hidden'},
      });
      final out =
          Redactor(const RedactionConfig()).redact(_log(requestBody: body));
      expect(jsonDecode(out.requestBody!), {
        'user': {'name': 'n', 'password': _r, 'card_number': _r},
        'items': [
          {'token': _r, 'id': 1},
          {'cvv': _r},
        ],
        'secret': _r,
      });
    });

    test('matches keys case-insensitively and across _ / - / camelCase', () {
      final out = Redactor(const RedactionConfig()).redact(_log(
        responseBody: jsonEncode({
          'accessToken': 'a',
          'Refresh-Token': 'r',
          'API_KEY': 'k',
          'Password': 'p',
          'username': 'u',
        }),
      ));
      expect(jsonDecode(out.responseBody!), {
        'accessToken': _r,
        'Refresh-Token': _r,
        'API_KEY': _r,
        'Password': _r,
        'username': 'u',
      });
    });

    test('leaves bodies without sensitive keys byte-for-byte untouched', () {
      const pretty = '{\n  "id": 1,\n  "name": "x"\n}';
      final out =
          Redactor(const RedactionConfig()).redact(_log(responseBody: pretty));
      expect(out.responseBody, pretty);
    });

    test('scrubs invalid / truncated JSON with a pattern fallback', () {
      const truncated = '{"user":"u","password":"hunter2","token": 12345, "da';
      final out = Redactor(const RedactionConfig())
          .redact(_log(requestBody: truncated));
      expect(out.requestBody, isNot(contains('hunter2')));
      expect(out.requestBody, isNot(contains('12345')));
      expect(out.requestBody, contains('"user":"u"'));
    });

    test('leaves plain text bodies alone', () {
      const text = 'hello password world';
      final out =
          Redactor(const RedactionConfig()).redact(_log(responseBody: text));
      expect(out.responseBody, text);
    });
  });

  group('query parameters and form data', () {
    test('redacts query params in the map and inside the URL', () {
      final out = Redactor(const RedactionConfig()).redact(_log(
        url: 'https://api.example.com/x?page=2&access_token=abc%20d&q=1#frag',
        queryParams: {'page': '2', 'Access_Token': 'abc d'},
      ));
      expect(out.url,
          'https://api.example.com/x?page=2&access_token=$_r&q=1#frag');
      expect(out.queryParams, {'page': '2', 'Access_Token': _r});
    });

    test('URLs without sensitive params are returned unchanged', () {
      const url = 'https://api.example.com/x?a=%2F&b=1';
      final out = Redactor(const RedactionConfig()).redact(_log(url: url));
      expect(out.url, url);
    });

    test('redacts form-urlencoded bodies', () {
      final out = Redactor(const RedactionConfig()).redact(
          _log(requestBody: 'username=me&password=s3cret&grant_type=password'));
      expect(out.requestBody, 'username=me&password=$_r&grant_type=password');
    });

    test('redacts multipart form fields', () {
      final out =
          Redactor(const RedactionConfig(redactBodyKeys: ['ssn'])).redact(
        _log(formData: {'name': 'n', 'SSN': '123', 'password': 'p'}),
      );
      expect(out.formData, {'name': 'n', 'SSN': _r, 'password': _r});
    });
  });

  group('custom redactor hook', () {
    test('runs after built-in redaction', () {
      ApiLogEntity? seen;
      final out = Redactor(RedactionConfig(redactor: (log) {
        seen = log;
        return log.copyWith(url: log.url.replaceAll(RegExp(r'\d+'), '#'));
      })).redact(_log(
        url: 'https://api.example.com/users/42',
        requestHeaders: {'Authorization': 'a'},
      ));
      expect(seen!.requestHeaders['Authorization'], _r);
      expect(out.url, 'https://api.example.com/users/#');
    });

    test('a throwing hook falls back to the built-in result', () {
      final out =
          Redactor(RedactionConfig(redactor: (_) => throw StateError('x')))
              .redact(_log(requestHeaders: {'Authorization': 'a'}));
      expect(out.requestHeaders['Authorization'], _r);
    });
  });

  test('default lists match the documented values', () {
    expect(RedactionConfig.defaultRedactHeaders, [
      'authorization',
      'cookie',
      'set-cookie',
      'x-api-key',
      'proxy-authorization',
    ]);
    expect(RedactionConfig.defaultRedactBodyKeys, [
      'password',
      'token',
      'access_token',
      'refresh_token',
      'secret',
      'api_key',
      'authorization',
      'card_number',
      'cvv',
    ]);
  });
}
