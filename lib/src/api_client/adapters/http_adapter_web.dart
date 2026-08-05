import 'dart:async' as async;
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../cache/cache_store.dart';
import '../cookie/cookie_jar.dart';
import '../core/client_config.dart';
import '../enums/response_type_enum.dart';
import '../exceptions/api_exceptions.dart' as exc;
import '../models/api_response.dart';
import '../request/api_request_options.dart';
import '../request/cancel_token.dart';
import '../request/multipart_file.dart';

typedef ProgressCallback = void Function(int count, int total);

/// Low-level HTTP adapter for web builds backed by `package:http`.
///
/// Uses `package:http` / `BrowserClient` so it can run on `dart:html` without
/// `dart:io`. SSL pinning, proxy and cookie-jar management are not supported
/// on the web (those features are controlled by the browser / CORS).
class HttpAdapter {
  final ClientConfig config;
  final MemoryCacheStore cacheStore;
  final ApiCookieJar cookieJar;

  final http.Client _client;

  HttpAdapter({
    required this.config,
    required this.cacheStore,
    required this.cookieJar,
  }) : _client = http.Client();

  /// Performs the HTTP request described by [options].
  Future<ApiResponse<T>> send<T>(
    ApiRequestOptions options, {
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    List<ApiMultipartFile> files = const [],
    Map<String, String> formFields = const {},
    CachePolicy? cachePolicy,
  }) async {
    final uri = options.uri;
    final cacheKey = '${options.method.value}:$uri';

    // Cache hit
    if (cachePolicy != null &&
        cachePolicy.enabled &&
        !cachePolicy.forceRefresh) {
      final cached = cacheStore.get(cacheKey);
      if (cached != null) {
        return ApiResponse<T>(
          data: cached.data as T?,
          statusCode: cached.statusCode,
          headers: cached.headers,
          requestOptions: options,
        );
      }
    }

    if (cancelToken != null && cancelToken.isCancelled) {
      throw exc.CancelledException(requestOptions: options);
    }

    final request = files.isNotEmpty || formFields.isNotEmpty
        ? _buildMultipartRequest(options, files, formFields)
        : _buildRequest(options);

    // Apply headers
    for (final e in config.defaultHeaders.entries) {
      request.headers[e.key] = e.value;
    }
    for (final e in options.headers.entries) {
      request.headers[e.key] = e.value.toString();
    }

    if (onSendProgress != null) {
      final body = request.bodyBytes;
      onSendProgress(0, body.length);
    }

    http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await _client
          .send(request)
          .timeout(options.connectTimeout ?? config.connectTimeout);
    } on async.TimeoutException {
      throw exc.TimeoutException(requestOptions: options);
    } on http.ClientException catch (e) {
      throw exc.NetworkException(
        message: 'Network error: ${e.message}',
        requestOptions: options,
      );
    } on Exception catch (e) {
      throw exc.NetworkException(
        message: 'Network error: $e',
        requestOptions: options,
      );
    }

    if (cancelToken != null && cancelToken.isCancelled) {
      throw exc.CancelledException(requestOptions: options);
    }

    http.Response response;
    try {
      response = await http.Response.fromStream(streamedResponse)
          .timeout(options.receiveTimeout ?? config.receiveTimeout);
    } on async.TimeoutException {
      throw exc.TimeoutException(requestOptions: options);
    } on http.ClientException catch (e) {
      throw exc.NetworkException(
        message: 'Network error: ${e.message}',
        requestOptions: options,
      );
    }

    if (onSendProgress != null) {
      final total = request.bodyBytes.length;
      onSendProgress(total, total);
    }

    final statusCode = response.statusCode;
    final responseHeaders = Map<String, String>.from(response.headers);
    final bodyBytes = response.bodyBytes;

    if (onReceiveProgress != null) {
      onReceiveProgress(bodyBytes.length, bodyBytes.length);
    }

    final T? data = await _parseResponse<T>(
      options.responseType,
      Uint8List.fromList(bodyBytes),
      statusCode,
      options,
    );

    final apiResponse = ApiResponse<T>(
      data: data,
      statusCode: statusCode,
      headers: responseHeaders,
      requestOptions: options,
    );

    if (cachePolicy != null && cachePolicy.enabled && statusCode < 300) {
      cacheStore.put(cacheKey, apiResponse, cachePolicy.ttl);
    }

    return apiResponse;
  }

  http.Request _buildRequest(ApiRequestOptions options) {
    final request = http.Request(options.method.value, options.uri);

    if (options.data != null) {
      if (options.data is String) {
        request.body = options.data as String;
      } else if (options.data is List<int>) {
        request.bodyBytes = options.data as List<int>;
      } else {
        request.body = jsonEncode(options.data);
        if (request.headers['Content-Type'] == null) {
          request.headers['Content-Type'] = 'application/json; charset=utf-8';
        }
      }
    }

    return request;
  }

  http.Request _buildMultipartRequest(
    ApiRequestOptions options,
    List<ApiMultipartFile> files,
    Map<String, String> formFields,
  ) {
    final request = http.Request(options.method.value, options.uri);

    final boundary = 'boundary${DateTime.now().millisecondsSinceEpoch}';
    request.headers['Content-Type'] = 'multipart/form-data; boundary=$boundary';

    final body = <int>[];
    final boundaryBytes = utf8.encode('--$boundary\r\n');
    final finalBoundary = utf8.encode('--$boundary--\r\n');

    for (final field in formFields.entries) {
      body.addAll(boundaryBytes);
      body.addAll(utf8.encode(
          'Content-Disposition: form-data; name="${field.key}"\r\n\r\n'));
      body.addAll(utf8.encode('${field.value}\r\n'));
    }

    for (final file in files) {
      body.addAll(boundaryBytes);
      body.addAll(utf8.encode(
        'Content-Disposition: form-data; name="${file.field}"; filename="${file.filename}"\r\n',
      ));
      body.addAll(utf8.encode('Content-Type: ${file.contentType}\r\n\r\n'));
      body.addAll(file.bytes);
      body.addAll(utf8.encode('\r\n'));
    }

    body.addAll(finalBoundary);
    request.bodyBytes = body;

    return request;
  }

  Future<T?> _parseResponse<T>(
    ApiResponseType responseType,
    Uint8List bytes,
    int statusCode,
    ApiRequestOptions options,
  ) async {
    switch (responseType) {
      case ApiResponseType.bytes:
        return bytes as T?;
      case ApiResponseType.plain:
        return utf8.decode(bytes, allowMalformed: true) as T?;
      case ApiResponseType.stream:
        return Stream.value(bytes) as T?;
      case ApiResponseType.json:
        if (bytes.isEmpty) return null;
        final str = utf8.decode(bytes, allowMalformed: true);
        try {
          return jsonDecode(str) as T?;
        } catch (_) {
          return str as T?;
        }
    }
  }

  void close({bool force = false}) => _client.close();
}
