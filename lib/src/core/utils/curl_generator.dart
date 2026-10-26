import '../../domain/entities/api_log_entity.dart';
import '../runtime/api_studio_runtime.dart';
import 'url_utils.dart';

/// Generates POSIX-shell-safe cURL commands from captured logs.
class CurlGenerator {
  CurlGenerator._();

  /// Returns a cURL command reproducing [log].
  ///
  /// The active redaction rules are applied first, so secrets never end up
  /// in copied commands — even for logs stored before redaction existed.
  static String generate(ApiLogEntity log) {
    final safe = ApiStudioRuntime.redactor.redact(log);
    final buffer = StringBuffer('curl -X ${safe.methodLabel}');

    final uri =
        UrlUtils.mergeQuery(safe.url, safe.queryParams)?.toString() ?? safe.url;
    buffer.write(" '${_escapeSingleQuote(uri)}'");

    safe.requestHeaders.forEach((key, value) {
      final sanitized = _escapeSingleQuote(UrlUtils.headerValue(value));
      buffer.write(" \\\n  -H '$key: $sanitized'");
    });

    if (safe.requestBody != null && safe.requestBody!.isNotEmpty) {
      final body = _escapeSingleQuote(safe.requestBody!);
      buffer.write(" \\\n  -d '$body'");
    }

    if (safe.formData != null && safe.formData!.isNotEmpty) {
      safe.formData!.forEach((key, value) {
        final sanitizedVal = _escapeSingleQuote(value.toString());
        buffer.write(" \\\n  -F '$key=$sanitizedVal'");
      });
    }

    return buffer.toString();
  }

  static String _escapeSingleQuote(String value) {
    return value.replaceAll("'", r"'\''");
  }
}
