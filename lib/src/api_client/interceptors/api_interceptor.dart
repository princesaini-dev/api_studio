import '../models/api_response.dart';
import '../request/api_request_options.dart';
import '../exceptions/api_exceptions.dart';

/// Handler forwarded to request interceptors.
class RequestInterceptorHandler {
  ApiRequestOptions _options;
  bool _resolved = false;
  ApiResponse<dynamic>? _resolvedResponse;
  ApiStudioException? _rejectedError;

  RequestInterceptorHandler(this._options);

  /// Pass modified (or original) options to the next interceptor / adapter.
  void next(ApiRequestOptions options) {
    _options = options;
    _resolved = false;
  }

  /// Short-circuit the chain and resolve with [response] immediately.
  void resolve(ApiResponse<dynamic> response) {
    _resolvedResponse = response;
    _resolved = true;
  }

  /// Short-circuit the chain and reject with [error].
  void reject(ApiStudioException error) {
    _rejectedError = error;
    _resolved = true;
  }

  ApiRequestOptions get options => _options;
  bool get isResolved => _resolved;
  ApiResponse<dynamic>? get resolvedResponse => _resolvedResponse;
  ApiStudioException? get rejectedError => _rejectedError;
}

/// Handler forwarded to response interceptors.
class ResponseInterceptorHandler<T> {
  ApiResponse<T> _response;
  bool _resolved = false;
  ApiStudioException? _rejectedError;

  ResponseInterceptorHandler(this._response);

  void next(ApiResponse<T> response) {
    _response = response;
    _resolved = false;
  }

  void reject(ApiStudioException error) {
    _rejectedError = error;
    _resolved = true;
  }

  ApiResponse<T> get response => _response;
  bool get isRejected => _resolved;
  ApiStudioException? get rejectedError => _rejectedError;
}

/// Handler forwarded to error interceptors.
class ErrorInterceptorHandler {
  ApiStudioException _error;
  bool _resolved = false;
  ApiResponse<dynamic>? _resolvedResponse;

  ErrorInterceptorHandler(this._error);

  void next(ApiStudioException error) {
    _error = error;
    _resolved = false;
  }

  /// Resolve the error as a successful response.
  void resolve(ApiResponse<dynamic> response) {
    _resolvedResponse = response;
    _resolved = true;
  }

  ApiStudioException get error => _error;
  bool get isResolved => _resolved;
  ApiResponse<dynamic>? get resolvedResponse => _resolvedResponse;
}

/// Base class for [ApiStudioClient] interceptors.
///
/// Override any combination of [onRequest], [onResponse], [onError].
abstract class ApiInterceptor {
  const ApiInterceptor();

  void onRequest(
    ApiRequestOptions options,
    RequestInterceptorHandler handler,
  ) =>
      handler.next(options);

  void onResponse<T>(
    ApiResponse<T> response,
    ResponseInterceptorHandler<T> handler,
  ) =>
      handler.next(response);

  void onError(
    ApiStudioException error,
    ErrorInterceptorHandler handler,
  ) =>
      handler.next(error);
}
