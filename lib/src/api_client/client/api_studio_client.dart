import 'dart:async' hide TimeoutException;

import 'package:uuid/uuid.dart';

import '../adapters/http_adapter.dart';
import '../cache/cache_store.dart';
import '../cookie/cookie_jar.dart';
import '../core/client_config.dart';
import '../core/inspector_logger.dart';
import '../enums/duplicate_strategy_enum.dart';
import '../enums/http_method_enum.dart';
import '../enums/response_type_enum.dart';
import '../exceptions/api_exceptions.dart';
import '../interceptors/api_interceptor.dart';
import '../interceptors/interceptor_chain.dart';
import '../models/api_response.dart';
import '../request/api_request_options.dart';
import '../request/cancel_token.dart';
import '../request/multipart_file.dart';

export '../adapters/http_adapter.dart' show ProgressCallback;
export '../auth/auth_config.dart';
export '../cache/cache_store.dart';
export '../cookie/cookie_jar.dart';
export '../core/client_config.dart';
export '../enums/auth_type_enum.dart';
export '../enums/duplicate_strategy_enum.dart';
export '../enums/http_method_enum.dart';
export '../enums/response_type_enum.dart';
export '../exceptions/api_exceptions.dart';
export '../interceptors/api_interceptor.dart';
export '../models/api_response.dart';
export '../proxy/proxy_config.dart';
export '../request/api_request_options.dart';
export '../request/cancel_token.dart';
export '../request/multipart_file.dart';
export '../retry/retry_config.dart';
export '../ssl/ssl_config.dart';

/// Production-grade HTTP client for Flutter applications.
///
/// ## Initialization
/// ```dart
/// await ApiStudio.init(...);
/// ApiStudioClient.initialize(baseUrl: 'https://api.example.com');
/// ```
///
/// ## Usage
/// ```dart
/// final res = await ApiStudioClient.instance.get<Map<String, dynamic>>('/users');
/// ```
///
/// Every request is automatically logged to the API Studio Inspector.
class ApiStudioClient {
  static ApiStudioClient? _instance;
  static InspectorLogger? _logger;

  final ClientConfig _config;
  final HttpAdapter _adapter;
  final MemoryCacheStore _cache;
  final ApiCookieJar _cookieJar;
  final List<ApiInterceptor> _interceptors = [];
  final _uuid = const Uuid();

  // Duplicate request tracking: key → in-flight CancelToken
  final Map<String, CancelToken> _inFlight = {};

  ApiStudioClient._({
    required ClientConfig config,
    required InspectorLogger? logger,
  })  : _config = config,
        _cache = MemoryCacheStore(),
        _cookieJar = ApiCookieJar(),
        _adapter = HttpAdapter(
          config: config,
          cacheStore: MemoryCacheStore(),
          cookieJar: ApiCookieJar(),
        ) {
    if (logger != null) _logger = logger;
  }

  // Intentionally store the outer cookie/cache in the adapter via factory
  factory ApiStudioClient._create(
          ClientConfig config, InspectorLogger? logger) =>
      ApiStudioClient._(config: config, logger: logger);

  /// Returns the singleton [ApiStudioClient] instance.
  ///
  /// Call [initialize] before accessing [instance].
  static ApiStudioClient get instance {
    assert(
      _instance != null,
      'ApiStudioClient.initialize() must be called before using instance.',
    );
    return _instance!;
  }

  /// Initialises (or re-initialises) the singleton client.
  ///
  /// [logger] is injected by [ApiStudio.init]; you normally do not need to
  /// provide it directly.
  static void initialize({
    required String baseUrl,
    Duration timeout = const Duration(seconds: 30),
    Map<String, String> defaultHeaders = const {},
    InspectorLogger? logger,
    ClientConfig? config,
  }) {
    final effective = config ??
        ClientConfig(
          baseUrl: baseUrl,
          defaultHeaders: defaultHeaders,
          connectTimeout: timeout,
          receiveTimeout: timeout,
          sendTimeout: timeout,
        );
    _instance = ApiStudioClient._create(effective, logger ?? _logger);
  }

  /// Attach [logger] after the fact (called internally by [ApiStudio.init]).
  static void attachLogger(InspectorLogger logger) {
    _logger = logger;
  }

  // ───────────────────────────── Interceptors ──────────────────────────────

  /// The list of registered interceptors. Mutate freely before making calls.
  List<ApiInterceptor> get interceptors => _interceptors;

  // ─────────────────────────────── HTTP API ────────────────────────────────

  /// Sends a GET request.
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ApiResponseType responseType = ApiResponseType.json,
    CancelToken? cancelToken,
    CachePolicy? cachePolicy,
    Duration? receiveTimeout,
  }) =>
      _request<T>(
        ApiHttpMethod.get,
        path,
        queryParameters: queryParameters,
        headers: headers,
        responseType: responseType,
        cancelToken: cancelToken,
        cachePolicy: cachePolicy,
        receiveTimeout: receiveTimeout,
      );

  /// Sends a POST request.
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ApiResponseType responseType = ApiResponseType.json,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    List<ApiMultipartFile> files = const [],
    Map<String, String> formFields = const {},
  }) =>
      _request<T>(
        ApiHttpMethod.post,
        path,
        data: data,
        queryParameters: queryParameters,
        headers: headers,
        responseType: responseType,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        files: files,
        formFields: formFields,
      );

  /// Sends a PUT request.
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ApiResponseType responseType = ApiResponseType.json,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) =>
      _request<T>(
        ApiHttpMethod.put,
        path,
        data: data,
        queryParameters: queryParameters,
        headers: headers,
        responseType: responseType,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );

  /// Sends a PATCH request.
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ApiResponseType responseType = ApiResponseType.json,
    CancelToken? cancelToken,
  }) =>
      _request<T>(
        ApiHttpMethod.patch,
        path,
        data: data,
        queryParameters: queryParameters,
        headers: headers,
        responseType: responseType,
        cancelToken: cancelToken,
      );

  /// Sends a DELETE request.
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ApiResponseType responseType = ApiResponseType.json,
    CancelToken? cancelToken,
  }) =>
      _request<T>(
        ApiHttpMethod.delete,
        path,
        data: data,
        queryParameters: queryParameters,
        headers: headers,
        responseType: responseType,
        cancelToken: cancelToken,
      );

  /// Sends a HEAD request.
  Future<ApiResponse<T>> head<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) =>
      _request<T>(
        ApiHttpMethod.head,
        path,
        queryParameters: queryParameters,
        headers: headers,
        cancelToken: cancelToken,
      );

  /// Sends an OPTIONS request.
  Future<ApiResponse<T>> options<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) =>
      _request<T>(
        ApiHttpMethod.options,
        path,
        queryParameters: queryParameters,
        headers: headers,
        cancelToken: cancelToken,
      );

  /// Downloads a file to [savePath] with progress reporting.
  Future<ApiResponse<List<int>>> download(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) =>
      _request<List<int>>(
        ApiHttpMethod.get,
        path,
        queryParameters: queryParameters,
        headers: headers,
        responseType: ApiResponseType.bytes,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );

  /// Uploads files with progress reporting.
  Future<ApiResponse<T>> upload<T>(
    String path, {
    required List<ApiMultipartFile> files,
    Map<String, String> formFields = const {},
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) =>
      _request<T>(
        ApiHttpMethod.post,
        path,
        headers: headers,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        files: files,
        formFields: formFields,
      );

  // ──────────────────────── Batch / Queue helpers ───────────────────────────

  /// Executes [requests] in parallel and returns all results.
  Future<List<ApiResponse<dynamic>>> parallel(
    List<Future<ApiResponse<dynamic>> Function()> requests,
  ) =>
      Future.wait(requests.map((f) => f()));

  /// Executes [requests] sequentially, passing each result to the next factory.
  Future<List<ApiResponse<dynamic>>> sequential(
    List<Future<ApiResponse<dynamic>> Function()> requests,
  ) async {
    final results = <ApiResponse<dynamic>>[];
    for (final req in requests) {
      results.add(await req());
    }
    return results;
  }

  // ────────────────────────── Cookie API ───────────────────────────────────

  ApiCookieJar get cookies => _cookieJar;

  // ────────────────────────── Cache API ────────────────────────────────────

  MemoryCacheStore get cache => _cache;

  // ─────────────────────────── Core ────────────────────────────────────────

  Future<ApiResponse<T>> _request<T>(
    ApiHttpMethod method,
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ApiResponseType responseType = ApiResponseType.json,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    List<ApiMultipartFile> files = const [],
    Map<String, String> formFields = const {},
    CachePolicy? cachePolicy,
    Duration? receiveTimeout,
  }) async {
    final requestId = _uuid.v4();
    final startTime = DateTime.now();

    // Build initial options
    var options = ApiRequestOptions(
      method: method,
      baseUrl: _config.baseUrl,
      path: path,
      queryParameters: queryParameters ?? {},
      headers: _buildHeaders(headers),
      data: data,
      responseType: responseType,
      connectTimeout: _config.connectTimeout,
      receiveTimeout: receiveTimeout ?? _config.receiveTimeout,
      sendTimeout: _config.sendTimeout,
      requestId: requestId,
    );

    // Duplicate request handling
    final dupKey = '${method.value}:${options.uri}';
    cancelToken = _handleDuplicate(dupKey, cancelToken, options);

    final chain = InterceptorChain(_interceptors);

    try {
      // Interceptor: request phase
      options = await chain.runRequest(options);

      // Retry loop
      final retryConfig = _config.retry;
      int attempt = 0;
      while (true) {
        try {
          final response = await _adapter.send<T>(
            options,
            cancelToken: cancelToken,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress,
            files: files,
            formFields: formFields,
            cachePolicy: cachePolicy,
          );

          // Status code error promotion
          _checkStatus(response, options);

          // Interceptor: response phase
          final finalResponse = await chain.runResponse<T>(response);

          // Log success
          if (_config.enableLogging) {
            unawaited(
              _logger?.logResponse(
                id: requestId,
                options: options,
                response: finalResponse,
                startTime: startTime,
              ),
            );
          }

          _inFlight.remove(dupKey);
          return finalResponse;
        } on ApiStudioException catch (e) {
          if (retryConfig != null &&
              attempt < retryConfig.maxAttempts &&
              retryConfig.shouldRetry(e)) {
            attempt++;
            await Future.delayed(retryConfig.delay);
            continue;
          }

          // Interceptor: error phase
          final handled = await chain.runError(e);
          if (_config.enableLogging) {
            unawaited(_logger?.logError(
              id: requestId,
              options: options,
              error: handled,
              startTime: startTime,
            ));
          }
          _inFlight.remove(dupKey);
          rethrow;
        }
      }
    } on ApiStudioException {
      _inFlight.remove(dupKey);
      rethrow;
    } catch (e) {
      _inFlight.remove(dupKey);
      final wrapped = UnknownException(
        message: e.toString(),
        requestOptions: options,
      );
      if (_config.enableLogging) {
        unawaited(_logger?.logError(
          id: requestId,
          options: options,
          error: wrapped,
          startTime: startTime,
        ));
      }
      throw wrapped;
    }
  }

  Map<String, dynamic> _buildHeaders(Map<String, dynamic>? perRequest) {
    final merged = <String, dynamic>{
      'Content-Type': 'application/json',
      ...config.defaultHeaders,
    };
    if (_config.auth != null) {
      merged.addAll(_config.auth!.buildHeaders());
    }
    if (perRequest != null) merged.addAll(perRequest);
    return merged;
  }

  void _checkStatus(ApiResponse<dynamic> response, ApiRequestOptions options) {
    final code = response.statusCode;
    final headers = Map<String, dynamic>.from(response.headers);
    if (code == 401) {
      throw UnauthorizedException(
          requestOptions: options,
          response: response.data,
          responseHeaders: headers);
    }
    if (code == 403) {
      throw ForbiddenException(
          requestOptions: options,
          response: response.data,
          responseHeaders: headers);
    }
    if (code >= 500) {
      throw ServerException(
        message: 'Server error ($code)',
        statusCode: code,
        requestOptions: options,
        response: response.data,
        responseHeaders: headers,
      );
    }
    if (code >= 400) {
      throw BadResponseException(
        message: 'Bad response ($code)',
        statusCode: code,
        requestOptions: options,
        response: response.data,
        responseHeaders: headers,
      );
    }
  }

  CancelToken? _handleDuplicate(
    String key,
    CancelToken? provided,
    ApiRequestOptions options,
  ) {
    switch (_config.duplicateStrategy) {
      case DuplicateRequestStrategy.allow:
        return provided;
      case DuplicateRequestStrategy.ignore:
        if (_inFlight.containsKey(key)) {
          final dummy = CancelToken();
          dummy.cancel('Duplicate request ignored');
          return dummy;
        }
        final token = provided ?? CancelToken();
        _inFlight[key] = token;
        return token;
      case DuplicateRequestStrategy.cancelPrevious:
      case DuplicateRequestStrategy.latestWins:
        _inFlight[key]?.cancel('Superseded by newer request');
        final token = provided ?? CancelToken();
        _inFlight[key] = token;
        return token;
    }
  }

  ClientConfig get config => _config;

  void close({bool force = false}) => _adapter.close(force: force);
}

// Silence unawaited_futures lint for fire-and-forget logging
void unawaited(Future<void>? future) {}
