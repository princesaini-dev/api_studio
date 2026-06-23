class SensitiveDataMasker {
  SensitiveDataMasker._();

  /// The replacement string used for masked values.
  static const String _maskValue = '***';

  /// List of sensitive header names (case-insensitive).
  static final List<String> _sensitiveHeaders = [
    'authorization',
    'cookie',
    'password',
    'passwd',
    'pwd',
    'otp',
    'api-key',
    'apikey',
    'api_key',
    'x-api-key',
    'secret',
    'secret-key',
    'secretkey',
    'access-token',
    'accesstoken',
    'access_token',
    'refresh-token',
    'refreshtoken',
    'refresh_token',
    'token',
    'bearer',
    'auth',
    'credentials',
    'private-key',
    'privatekey',
    'private_key',
    'session',
    'sessionid',
    'session-id',
    'session_id',
    'jwt',
    'x-auth-token',
    'x-auth',
    'api-secret',
    'apisecret',
    'api_secret',
    'client-secret',
    'clientsecret',
    'client_secret',
    'app-secret',
    'appsecret',
    'app_secret',
  ];

  /// Patterns that indicate sensitive content in values.
  static final List<RegExp> _sensitivePatterns = [
    // Bearer token pattern
    RegExp(r'^[Bb]earer\s+\S+'),
    // Basic auth pattern
    RegExp(r'^[Bb]asic\s+\S+'),
    // API key patterns (common formats)
    RegExp(r'^[A-Za-z0-9]{32,}$'), // Many API keys are 32+ alphanumeric chars
    // JWT pattern (three base64 parts separated by dots)
    RegExp(r'^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$'),
  ];

  /// Masks sensitive values in a map of headers.
  ///
  /// Returns a new map with sensitive header values replaced with '***'.
  /// The original map is not modified.
  ///
  /// [headers] the original headers map to mask
  static Map<String, dynamic> maskHeaders(Map<String, dynamic> headers) {
    final masked = <String, dynamic>{};

    for (final entry in headers.entries) {
      final key = entry.key;
      final value = entry.value;

      if (isSensitiveKey(key) || _isSensitiveValue(value.toString())) {
        masked[key] = _maskValue;
      } else {
        masked[key] = value;
      }
    }

    return masked;
  }

  /// Masks sensitive values in a single header value.
  ///
  /// If the value contains sensitive patterns (like Bearer tokens),
  /// the entire value is masked.
  ///
  /// [key] the header name
  /// [value] the header value to potentially mask
  static String maskHeaderValue(String key, String value) {
    if (isSensitiveKey(key) || _isSensitiveValue(value)) {
      return _maskValue;
    }
    return value;
  }

  /// Checks if a header key indicates sensitive data.
  ///
  /// Comparison is case-insensitive and handles hyphen/underscore variations.
  ///
  /// [key] the header name to check
  static bool isSensitiveKey(String key) {
    final normalizedKey = _normalizeKey(key);
    return _sensitiveHeaders.contains(normalizedKey);
  }

  /// Normalizes a header key for comparison.
  ///
  /// Converts to lowercase and replaces underscores with hyphens
  /// to standardize different naming conventions.
  static String _normalizeKey(String key) {
    return key.toLowerCase().replaceAll('_', '-');
  }

  /// Checks if a value contains sensitive patterns.
  ///
  /// Detects patterns like Bearer tokens, JWTs, and long API keys.
  static bool _isSensitiveValue(String value) {
    // Check if value matches any sensitive pattern
    for (final pattern in _sensitivePatterns) {
      if (pattern.hasMatch(value)) {
        return true;
      }
    }

    // Check for common sensitive keywords in the value itself
    final lowerValue = value.toLowerCase();
    for (final keyword in _sensitiveHeaders) {
      if (lowerValue.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  /// Masks sensitive data in a request or response body.
  ///
  /// If the body is JSON, it attempts to parse and mask sensitive fields.
  /// For non-JSON bodies, it returns the original string.
  ///
  /// [body] the body string to mask
  static String? maskBody(String? body) {
    if (body == null || body.isEmpty) return body;

    // Simple string replacement for common sensitive patterns in JSON
    String masked = body;

    // Mask common JSON patterns for sensitive fields
    final sensitivePatterns = [
      RegExp(r'"password"\s*:\s*"[^"]*"', caseSensitive: false),
      RegExp(r'"passwd"\s*:\s*"[^"]*"', caseSensitive: false),
      RegExp(r'"pwd"\s*:\s*"[^"]*"', caseSensitive: false),
      RegExp(r'"otp"\s*:\s*"[^"]*"', caseSensitive: false),
      RegExp(r'"token"\s*:\s*"[^"]*"', caseSensitive: false),
      RegExp(r'"secret"\s*:\s*"[^"]*"', caseSensitive: false),
      RegExp(r'"apiKey"\s*:\s*"[^"]*"', caseSensitive: false),
      RegExp(r'"api_key"\s*:\s*"[^"]*"', caseSensitive: false),
      RegExp(r'"api-key"\s*:\s*"[^"]*"', caseSensitive: false),
      RegExp(r'"access_token"\s*:\s*"[^"]*"', caseSensitive: false),
      RegExp(r'"refresh_token"\s*:\s*"[^"]*"', caseSensitive: false),
      RegExp(r'"authorization"\s*:\s*"[^"]*"', caseSensitive: false),
    ];

    for (final pattern in sensitivePatterns) {
      masked = masked.replaceAllMapped(pattern, (match) {
        final matched = match.group(0)!;
        final colonIndex = matched.indexOf(':');
        if (colonIndex == -1) return matched;
        final key = matched.substring(0, colonIndex + 1);
        return '$key"$_maskValue"';
      });
    }

    return masked;
  }
}
