import 'package:api_studio/src/api_client/adapters/request_headers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mergeRequestHeaders', () {
    test('a header in both maps appears once, per-request value wins', () {
      final merged = mergeRequestHeaders(
        {'Content-Type': 'application/json'},
        {'Content-Type': 'application/json', 'Authorization': 'Bearer t'},
      );

      expect(merged, {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer t',
      });
    });

    test('names are matched case-insensitively', () {
      final merged = mergeRequestHeaders(
        {'content-type': 'text/plain', 'X-App': 'portal'},
        {'Content-Type': 'application/json'},
      );

      expect(merged, {'X-App': 'portal', 'Content-Type': 'application/json'});
    });

    test('non-string per-request values are stringified', () {
      expect(mergeRequestHeaders({}, {'X-Retry': 2}), {'X-Retry': '2'});
    });
  });
}
