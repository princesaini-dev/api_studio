import 'package:api_studio/api_studio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CurlGenerator', () {
    ApiLogEntity makeLog({
      String url = 'https://api.example.com/users',
      HttpMethod method = HttpMethod.get,
      Map<String, dynamic> headers = const {},
      Map<String, dynamic> queryParams = const {},
      String? body,
    }) {
      return ApiLogEntity(
        id: '1',
        url: url,
        method: method,
        requestHeaders: headers,
        queryParams: queryParams,
        requestBody: body,
        timestamp: DateTime(2024),
        responseHeaders: {},
        status: LogStatus.success,
      );
    }

    test('generates basic GET curl', () {
      final log = makeLog();
      final curl = CurlGenerator.generate(log);
      expect(curl, contains('curl -X GET'));
      expect(curl, contains("'https://api.example.com/users'"));
    });

    test('includes headers', () {
      final log = makeLog(headers: {'Accept': 'application/json'});
      final curl = CurlGenerator.generate(log);
      expect(curl, contains("-H 'Accept: application/json'"));
    });

    test('redacts sensitive headers, query params and body keys', () {
      final log = makeLog(
        url: 'https://api.example.com/users?token=abc&page=1',
        method: HttpMethod.post,
        headers: {'Authorization': 'Bearer token123', 'Cookie': 'sid=1'},
        queryParams: {'api_key': 'k'},
        body: '{"user":"u","password":"p"}',
      );
      final curl = CurlGenerator.generate(log);
      expect(
          curl, contains("-H 'Authorization: ${RedactionConfig.placeholder}'"));
      expect(curl, contains("-H 'Cookie: ${RedactionConfig.placeholder}'"));
      expect(curl, isNot(contains('token123')));
      expect(curl, isNot(contains('token=abc')));
      expect(curl, isNot(contains('api_key=k')));
      expect(curl, contains('page=1'));
      expect(curl, contains('"user":"u"'));
      expect(curl, isNot(contains('"password":"p"')));
    });

    test('preserves repeated query keys', () {
      final log = makeLog(url: 'https://api.example.com/items?id=1&id=2');
      final curl = CurlGenerator.generate(log);
      expect(curl, contains('id=1&id=2'));
    });

    test('flattens multi-value headers captured from Dio', () {
      final log = makeLog(headers: {
        'Accept': ['application/json', 'text/plain'],
      });
      final curl = CurlGenerator.generate(log);
      expect(curl, contains("-H 'Accept: application/json, text/plain'"));
    });

    test('appends query params to URL', () {
      final log = makeLog(queryParams: {'page': '1', 'limit': '10'});
      final curl = CurlGenerator.generate(log);
      expect(curl, contains('page=1'));
      expect(curl, contains('limit=10'));
    });

    test('includes body for POST', () {
      final log = makeLog(
        method: HttpMethod.post,
        body: '{"name":"test"}',
      );
      final curl = CurlGenerator.generate(log);
      expect(curl, contains('curl -X POST'));
      expect(curl, contains("-d '{\"name\":\"test\"}'"));
    });

    test('escapes single quotes using POSIX convention', () {
      final log = makeLog(
        headers: {'X-Custom': "It's a test"},
        body: '{"key": "value\'s test"}',
      );
      final curl = CurlGenerator.generate(log);
      expect(curl, contains(r"-H 'X-Custom: It'\''s a test'"));
      expect(curl, contains(r"value'\''s test"));
    });

    test('merges query params with existing URL query params cleanly', () {
      final log = makeLog(
        url: 'https://api.example.com/users?page=1',
        queryParams: {'limit': '10'},
      );
      final curl = CurlGenerator.generate(log);
      expect(curl, contains("https://api.example.com/users?page=1&limit=10"));
      expect(curl.contains('??'), isFalse);
    });
  });
}
