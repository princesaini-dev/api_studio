import '../enums/http_method_enum.dart';
import '../enums/response_type_enum.dart';

/// Encapsulates every configurable aspect of a single HTTP request.
class ApiRequestOptions {
  final ApiHttpMethod method;
  final String baseUrl;
  final String path;
  final Map<String, dynamic> queryParameters;
  final Map<String, dynamic> headers;
  final dynamic data;
  final ApiResponseType responseType;
  final Duration? connectTimeout;
  final Duration? receiveTimeout;
  final Duration? sendTimeout;
  final bool followRedirects;
  final Map<String, dynamic> extra;
  final String? requestId;

  const ApiRequestOptions({
    required this.method,
    required this.baseUrl,
    required this.path,
    this.queryParameters = const {},
    this.headers = const {},
    this.data,
    this.responseType = ApiResponseType.json,
    this.connectTimeout,
    this.receiveTimeout,
    this.sendTimeout,
    this.followRedirects = true,
    this.extra = const {},
    this.requestId,
  });

  /// Builds the fully-qualified URI string from [baseUrl], [path] and
  /// [queryParameters].
  ///
  /// If [path] is already an absolute URL (starts with `http://` or
  /// `https://`) it is used as-is, ignoring [baseUrl].
  Uri get uri {
    final isAbsolute =
        path.startsWith('http://') || path.startsWith('https://');
    final raw = isAbsolute
        ? path
        : baseUrl.endsWith('/')
            ? baseUrl + (path.startsWith('/') ? path.substring(1) : path)
            : path.isEmpty
                ? baseUrl
                : '$baseUrl${path.startsWith('/') ? '' : '/'}$path';
    final uri = Uri.parse(raw);
    if (queryParameters.isEmpty) return uri;
    final existing = Map<String, dynamic>.from(uri.queryParameters);
    existing.addAll(queryParameters);
    return uri.replace(
      queryParameters: existing.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  ApiRequestOptions copyWith({
    ApiHttpMethod? method,
    String? baseUrl,
    String? path,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    dynamic data,
    ApiResponseType? responseType,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    bool? followRedirects,
    Map<String, dynamic>? extra,
    String? requestId,
  }) {
    return ApiRequestOptions(
      method: method ?? this.method,
      baseUrl: baseUrl ?? this.baseUrl,
      path: path ?? this.path,
      queryParameters: queryParameters ?? this.queryParameters,
      headers: headers ?? this.headers,
      data: data ?? this.data,
      responseType: responseType ?? this.responseType,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      followRedirects: followRedirects ?? this.followRedirects,
      extra: extra ?? this.extra,
      requestId: requestId ?? this.requestId,
    );
  }
}
