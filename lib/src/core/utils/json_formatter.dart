import 'dart:convert';

class JsonFormatter {
  JsonFormatter._();

  static String prettyPrint(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    try {
      final decoded = jsonDecode(raw);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (_) {
      return raw;
    }
  }

  static bool isValidJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) return false;
    try {
      jsonDecode(raw);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Parses and pretty-prints JSON in a single decode pass.
  static ({bool isValid, String formatted}) format(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return (isValid: false, formatted: '');
    }
    try {
      final decoded = jsonDecode(raw);
      const encoder = JsonEncoder.withIndent('  ');
      return (isValid: true, formatted: encoder.convert(decoded));
    } catch (_) {
      return (isValid: false, formatted: raw);
    }
  }

  static String safeEncode(Object? value) {
    try {
      return jsonEncode(value);
    } catch (_) {
      return value?.toString() ?? '';
    }
  }
}
