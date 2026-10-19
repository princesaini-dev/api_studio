import 'package:flutter_test/flutter_test.dart';
import 'package:api_studio/src/core/utils/json_formatter.dart';

void main() {
  group('JsonFormatter', () {
    test('pretty prints valid JSON', () {
      const raw = '{"name":"Alice","age":30}';
      final result = JsonFormatter.prettyPrint(raw);
      expect(result, contains('"name"'));
      expect(result, contains('"Alice"'));
      expect(result.split('\n').length, greaterThan(1));
    });

    test('returns raw string for invalid JSON', () {
      const raw = 'not-json';
      final result = JsonFormatter.prettyPrint(raw);
      expect(result, equals('not-json'));
    });

    test('returns empty string for null', () {
      final result = JsonFormatter.prettyPrint(null);
      expect(result, isEmpty);
    });

    test('isValidJson returns true for valid JSON', () {
      expect(JsonFormatter.isValidJson('{"a":1}'), isTrue);
      expect(JsonFormatter.isValidJson('[1,2,3]'), isTrue);
    });

    test('isValidJson returns false for invalid', () {
      expect(JsonFormatter.isValidJson('not json'), isFalse);
      expect(JsonFormatter.isValidJson(null), isFalse);
    });

    test('format parses and pretty prints in single pass', () {
      final valid = JsonFormatter.format('{"key":"value"}');
      expect(valid.isValid, isTrue);
      expect(valid.formatted, contains('  "key": "value"'));

      final invalid = JsonFormatter.format('plain text');
      expect(invalid.isValid, isFalse);
      expect(invalid.formatted, equals('plain text'));

      final empty = JsonFormatter.format(null);
      expect(empty.isValid, isFalse);
      expect(empty.formatted, isEmpty);
    });
  });
}
