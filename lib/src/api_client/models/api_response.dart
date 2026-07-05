import '../request/api_request_options.dart';

/// Generic HTTP response returned by [ApiStudioClient].
class ApiResponse<T> {
  /// Parsed or raw response data.
  final T? data;

  /// HTTP status code (e.g. 200, 404).
  final int statusCode;

  /// Response headers.
  final Map<String, String> headers;

  /// Original request options that produced this response.
  final ApiRequestOptions requestOptions;

  /// Whether the response is considered successful (2xx).
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Whether the response body is null.
  bool get hasData => data != null;

  const ApiResponse({
    required this.data,
    required this.statusCode,
    required this.headers,
    required this.requestOptions,
  });

  @override
  String toString() =>
      'ApiResponse(statusCode: $statusCode, hasData: $hasData)';
}
