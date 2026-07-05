/// Determines how the response body is parsed.
enum ApiResponseType {
  /// Automatic JSON decoding → returns [Map] or [List].
  json,

  /// Plain UTF-8 [String].
  plain,

  /// Raw [List<int>] bytes.
  bytes,

  /// Raw [Stream<List<int>>] — no buffering.
  stream,
}
