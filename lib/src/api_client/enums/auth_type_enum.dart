/// Authentication strategy used by [ApiStudioClient].
enum AuthType {
  /// No authentication.
  none,

  /// Bearer token — adds `Authorization: Bearer <token>`.
  bearer,

  /// API Key — adds the key to a configurable header.
  apiKey,

  /// Basic Auth — Base-64 encoded `username:password`.
  basic,

  /// Raw JWT attached as Bearer token.
  jwt,
}
