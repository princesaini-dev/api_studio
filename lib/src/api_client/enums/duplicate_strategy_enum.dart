/// How the client handles duplicate in-flight requests for the same key.
enum DuplicateRequestStrategy {
  /// Allow all duplicate requests (default).
  allow,

  /// Silently ignore new requests when one is already in-flight.
  ignore,

  /// Cancel the previous in-flight request and let the new one proceed.
  cancelPrevious,

  /// The latest request always wins; it cancels all previous.
  latestWins,
}
