import '../../domain/entities/api_log_entity.dart';

class CurlGenerator {
  CurlGenerator._();

  static String generate(ApiLogEntity log) {
    final buffer = StringBuffer('curl -X ${log.methodLabel}');

    final uri = _buildUri(log);
    buffer.write(" '$uri'");

    log.requestHeaders.forEach((key, value) {
      final sanitized = value.toString().replaceAll("'", r"\'");
      buffer.write(" \\\n  -H '$key: $sanitized'");
    });

    if (log.requestBody != null && log.requestBody!.isNotEmpty) {
      final body = log.requestBody!.replaceAll("'", r"\'");
      buffer.write(" \\\n  -d '$body'");
    }

    if (log.formData != null && log.formData!.isNotEmpty) {
      log.formData!.forEach((key, value) {
        buffer.write(" \\\n  -F '$key=$value'");
      });
    }

    return buffer.toString();
  }

  static String _buildUri(ApiLogEntity log) {
    if (log.queryParams.isEmpty) return log.url;
    final query = log.queryParams.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    return '${log.url}?$query';
  }
}
