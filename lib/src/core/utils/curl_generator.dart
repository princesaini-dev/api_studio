import '../../domain/entities/api_log_entity.dart';

class CurlGenerator {
  CurlGenerator._();

  static String generate(ApiLogEntity log) {
    final buffer = StringBuffer('curl -X ${log.methodLabel}');

    final uri = _buildUri(log);
    buffer.write(" '$uri'");

    log.requestHeaders.forEach((key, value) {
      final sanitized = _escapeSingleQuote(value.toString());
      buffer.write(" \\\n  -H '$key: $sanitized'");
    });

    if (log.requestBody != null && log.requestBody!.isNotEmpty) {
      final body = _escapeSingleQuote(log.requestBody!);
      buffer.write(" \\\n  -d '$body'");
    }

    if (log.formData != null && log.formData!.isNotEmpty) {
      log.formData!.forEach((key, value) {
        final sanitizedVal = _escapeSingleQuote(value.toString());
        buffer.write(" \\\n  -F '$key=$sanitizedVal'");
      });
    }

    return buffer.toString();
  }

  static String _escapeSingleQuote(String value) {
    return value.replaceAll("'", r"'\''");
  }

  static String _buildUri(ApiLogEntity log) {
    final baseUri = Uri.tryParse(log.url);
    if (baseUri == null || log.queryParams.isEmpty) {
      return log.url;
    }
    final merged = Map<String, dynamic>.from(baseUri.queryParameters)
      ..addAll(log.queryParams);
    return baseUri
        .replace(
          queryParameters: merged.map((k, v) => MapEntry(k, v.toString())),
        )
        .toString();
  }
}
