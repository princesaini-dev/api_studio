import '../exceptions/api_exceptions.dart';
import '../models/api_response.dart';
import '../request/api_request_options.dart';
import 'api_interceptor.dart';

/// Runs all registered [ApiInterceptor]s in sequence for request / response /
/// error phases. Mirrors the Dio interceptor chain behaviour.
class InterceptorChain {
  final List<ApiInterceptor> interceptors;

  const InterceptorChain(this.interceptors);

  /// Runs [onRequest] for every interceptor.
  /// Returns the (possibly modified) [ApiRequestOptions] or throws if any
  /// interceptor rejects.
  Future<ApiRequestOptions> runRequest(ApiRequestOptions options) async {
    var current = options;
    for (final interceptor in interceptors) {
      final handler = RequestInterceptorHandler(current);
      interceptor.onRequest(current, handler);
      if (handler.isResolved) {
        if (handler.rejectedError != null) throw handler.rejectedError!;
        break;
      }
      current = handler.options;
    }
    return current;
  }

  /// Runs [onResponse] for every interceptor.
  Future<ApiResponse<T>> runResponse<T>(ApiResponse<T> response) async {
    var current = response;
    for (final interceptor in interceptors) {
      final handler = ResponseInterceptorHandler<T>(current);
      interceptor.onResponse<T>(current, handler);
      if (handler.isRejected) {
        throw handler.rejectedError!;
      }
      current = handler.response;
    }
    return current;
  }

  /// Runs [onError] for every interceptor.
  /// An interceptor may resolve the error into a response.
  Future<ApiStudioException> runError(ApiStudioException error) async {
    var current = error;
    for (final interceptor in interceptors) {
      final handler = ErrorInterceptorHandler(current);
      interceptor.onError(current, handler);
      if (handler.isResolved) {
        return current; // resolved — caller should re-check
      }
      current = handler.error;
    }
    return current;
  }
}
