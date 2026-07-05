import '../exceptions/api_exceptions.dart';

/// Controls how [ApiStudioClient] retries failed requests.
class RetryConfig {
  /// Maximum number of retry attempts (not counting the first attempt).
  final int maxAttempts;

  /// Delay between retry attempts.
  final Duration delay;

  /// Optional predicate; returning `true` means the error is retryable.
  /// Defaults to retrying on [NetworkException] and [TimeoutException].
  final bool Function(ApiStudioException)? retryOn;

  const RetryConfig({
    this.maxAttempts = 3,
    this.delay = const Duration(seconds: 1),
    this.retryOn,
  });

  bool shouldRetry(ApiStudioException error) {
    if (retryOn != null) return retryOn!(error);
    return error is NetworkException || error is TimeoutException;
  }
}
