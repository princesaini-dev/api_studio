import '../../domain/entities/api_log_entity.dart';

/// Signature of a custom redaction hook.
///
/// Receives a log that has **already** been processed by the built-in
/// header / body-key redaction and must return the (possibly modified) log
/// that will be stored locally, uploaded, and used for exports.
typedef ApiStudioRedactor = ApiLogEntity Function(ApiLogEntity log);

/// Controls how API Studio masks sensitive data.
///
/// Redaction runs **before** a log is written to local storage, **before**
/// it is queued for remote upload, and again whenever a log is exported
/// (cURL, JSON, TXT, HAR, Postman). Masked values are replaced with
/// [placeholder].
///
/// The built-in defaults ([defaultRedactHeaders] and [defaultRedactBodyKeys])
/// are always applied unless [includeDefaults] is `false`; anything passed to
/// [redactHeaders] / [redactBodyKeys] is added on top of them.
///
/// ```dart
/// await ApiStudio.initialize(
///   redaction: RedactionConfig(
///     redactHeaders: ['X-Session-Id'],
///     redactBodyKeys: ['ssn', 'pin'],
///     redactor: (log) => log.copyWith(url: log.url.replaceAll(RegExp(r'\d{16}'), '****')),
///   ),
/// );
/// ```
class RedactionConfig {
  /// Value that replaces every redacted header, query parameter or body
  /// field.
  static const String placeholder = '***REDACTED***';

  /// Header names that are always redacted (case-insensitive) unless
  /// [includeDefaults] is `false`.
  static const List<String> defaultRedactHeaders = [
    'authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'proxy-authorization',
  ];

  /// JSON body keys / query parameter names that are always redacted unless
  /// [includeDefaults] is `false`.
  ///
  /// Matching is case-insensitive and ignores `_` and `-`, so `access_token`
  /// also matches `accessToken` and `Access-Token`.
  static const List<String> defaultRedactBodyKeys = [
    'password',
    'token',
    'access_token',
    'refresh_token',
    'secret',
    'api_key',
    'authorization',
    'card_number',
    'cvv',
  ];

  /// Additional header names to redact (case-insensitive).
  final List<String> redactHeaders;

  /// Additional JSON body keys, form fields and query parameter names to
  /// redact. Applied recursively to nested JSON objects and arrays.
  final List<String> redactBodyKeys;

  /// Whether [defaultRedactHeaders] and [defaultRedactBodyKeys] are applied.
  /// Defaults to `true`; only disable this if you fully replace them with
  /// your own lists.
  final bool includeDefaults;

  /// Optional custom hook that runs after the built-in redaction.
  ///
  /// If the hook throws, the log falls back to the built-in redaction
  /// result — a failing hook never causes unredacted data to be stored.
  final ApiStudioRedactor? redactor;

  /// Creates a redaction configuration.
  const RedactionConfig({
    this.redactHeaders = const [],
    this.redactBodyKeys = const [],
    this.includeDefaults = true,
    this.redactor,
  });

  /// Effective, normalized set of header names to redact.
  Set<String> get effectiveHeaders => {
        if (includeDefaults) ...defaultRedactHeaders,
        ...redactHeaders,
      }.map((h) => h.trim().toLowerCase()).toSet();

  /// Effective, normalized set of body keys to redact.
  Set<String> get effectiveBodyKeys => {
        if (includeDefaults) ...defaultRedactBodyKeys,
        ...redactBodyKeys,
      }.map(normalizeKey).toSet();

  /// Normalizes a key for case/separator-insensitive comparison.
  static String normalizeKey(String key) =>
      key.trim().toLowerCase().replaceAll(RegExp(r'[_\-\s]'), '');
}
