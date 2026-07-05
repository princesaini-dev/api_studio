import '../request/api_request_options.dart';

/// Base class for all [ApiStudioClient] exceptions.
abstract class ApiStudioException implements Exception {
  final String message;
  final ApiRequestOptions? requestOptions;
  final int? statusCode;
  final dynamic response;
  final Map<String, dynamic> responseHeaders;

  const ApiStudioException({
    required this.message,
    this.requestOptions,
    this.statusCode,
    this.response,
    this.responseHeaders = const {},
  });

  @override
  String toString() => '$runtimeType: $message';
}

/// No network connectivity when request was fired.
class NoInternetException extends ApiStudioException {
  const NoInternetException({
    super.message = 'No internet connection',
    super.requestOptions,
  });
}

/// Connection timed out before a response was received.
class TimeoutException extends ApiStudioException {
  const TimeoutException({
    super.message = 'Request timed out',
    super.requestOptions,
  });
}

/// Generic network-level error (DNS failure, socket reset, etc.).
class NetworkException extends ApiStudioException {
  const NetworkException({
    required super.message,
    super.requestOptions,
    super.statusCode,
    super.response,
  });
}

/// The server returned a 401 Unauthorized response.
class UnauthorizedException extends ApiStudioException {
  const UnauthorizedException({
    super.message = 'Unauthorized (401)',
    super.requestOptions,
    super.response,
    super.responseHeaders,
  }) : super(statusCode: 401);
}

/// The server returned a 403 Forbidden response.
class ForbiddenException extends ApiStudioException {
  const ForbiddenException({
    super.message = 'Forbidden (403)',
    super.requestOptions,
    super.response,
    super.responseHeaders,
  }) : super(statusCode: 403);
}

/// The server returned a 5xx response.
class ServerException extends ApiStudioException {
  const ServerException({
    required super.message,
    super.requestOptions,
    super.statusCode,
    super.response,
    super.responseHeaders,
  });
}

/// The request was cancelled via a [CancelToken].
class CancelledException extends ApiStudioException {
  const CancelledException({
    super.message = 'Request was cancelled',
    super.requestOptions,
  });
}

/// The server returned an unexpected response that could not be parsed.
class BadResponseException extends ApiStudioException {
  const BadResponseException({
    required super.message,
    super.requestOptions,
    super.statusCode,
    super.response,
    super.responseHeaders,
  });
}

/// SSL/TLS handshake or certificate verification failed.
class SslException extends ApiStudioException {
  const SslException({
    required super.message,
    super.requestOptions,
  });
}

/// Catch-all for unexpected errors.
class UnknownException extends ApiStudioException {
  const UnknownException({
    required super.message,
    super.requestOptions,
  });
}
