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
      final log = makeLog(headers: {'Authorization': 'Bearer token123'});
      final curl = CurlGenerator.generate(log);
      expect(curl, contains("-H 'Authorization: Bearer token123'"));
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
  });
}
