import 'dart:async' as async;
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

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

/// Low-level HTTP adapter for web builds backed by `dart:html` HttpRequest.
///
/// Uses `dart:html` [html.HttpRequest] (XMLHttpRequest) so it can run on
/// `dart:html` without `dart:io` or `package:http`. SSL pinning, proxy and
/// cookie-jar management are not supported on the web (those features are
/// controlled by the browser / CORS).
class HttpAdapter {
  final ClientConfig config;
  final MemoryCacheStore cacheStore;
  final ApiCookieJar cookieJar;

  HttpAdapter({
    required this.config,
    required this.cacheStore,
    required this.cookieJar,
  });

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

    // Build body
    final isMultipart = files.isNotEmpty || formFields.isNotEmpty;
    final bodyBytes = isMultipart
        ? _buildMultipartBody(options, files, formFields)
        : _buildBody(options);

    if (onSendProgress != null) {
      onSendProgress(0, bodyBytes.length);
    }

    final completer = async.Completer<html.HttpRequest>();
    final request = html.HttpRequest();

    request.open(options.method.value, uri.toString());
    request.responseType = 'arraybuffer';

    // Apply default headers
    for (final e in config.defaultHeaders.entries) {
      request.setRequestHeader(e.key, e.value);
    }
    // Apply per-request headers
    for (final e in options.headers.entries) {
      request.setRequestHeader(e.key, e.value.toString());
    }

    // Set multipart Content-Type if needed
    if (isMultipart) {
      final boundary = 'boundary${DateTime.now().millisecondsSinceEpoch}';
      final hasContentType =
          options.headers.keys.any((k) => k.toLowerCase() == 'content-type');
      if (!hasContentType) {
        request.setRequestHeader(
            'Content-Type', 'multipart/form-data; boundary=$boundary');
      }
    }

    // Cancellation wiring
    if (cancelToken != null) {
      cancelToken.whenCancel.then((_) {
        if (!completer.isCompleted) {
          request.abort();
          completer
              .completeError(exc.CancelledException(requestOptions: options));
        }
      });
    }

    // Receive progress
    if (onReceiveProgress != null) {
      request.onProgress.listen((html.ProgressEvent e) {
        if (e.loaded != null && e.total != null) {
          onReceiveProgress(e.loaded!, e.total!);
        }
      });
    }

    request.onLoad.listen((_) {
      completer.complete(request);
    });

    request.onError.listen((_) {
      if (!completer.isCompleted) {
        completer.completeError(exc.NetworkException(
          message: 'Network error: request failed',
          requestOptions: options,
        ));
      }
    });

    // Send the request
    try {
      request.send(bodyBytes);
    } catch (e) {
      throw exc.NetworkException(
        message: 'Network error: $e',
        requestOptions: options,
      );
    }

    final html.HttpRequest response;
    try {
      final timeout = options.receiveTimeout ?? config.receiveTimeout;
      response = await completer.future.timeout(timeout);
    } on async.TimeoutException {
      request.abort();
      throw exc.TimeoutException(requestOptions: options);
    }

    if (cancelToken != null && cancelToken.isCancelled) {
      throw exc.CancelledException(requestOptions: options);
    }

    if (onSendProgress != null) {
      onSendProgress(bodyBytes.length, bodyBytes.length);
    }

    final statusCode = response.status ?? 0;

    // Parse response headers
    final responseHeaders = <String, String>{};
    final headersStr = response.getAllResponseHeaders();
    if (headersStr.isNotEmpty) {
      for (final line in headersStr.split('\r\n')) {
        final idx = line.indexOf(': ');
        if (idx > 0) {
          responseHeaders[line.substring(0, idx).toLowerCase()] =
              line.substring(idx + 2);
        }
      }
    }

    // Get response body bytes
    final rawResponse = response.response;
    Uint8List responseBodyBytes;
    if (rawResponse is ByteBuffer) {
      responseBodyBytes = Uint8List.view(rawResponse);
    } else if (rawResponse is List<int>) {
      responseBodyBytes = Uint8List.fromList(rawResponse);
    } else {
      responseBodyBytes = Uint8List(0);
    }

    if (onReceiveProgress != null) {
      onReceiveProgress(responseBodyBytes.length, responseBodyBytes.length);
    }

    final T? data = await _parseResponse<T>(
      options.responseType,
      responseBodyBytes,
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

  List<int> _buildBody(ApiRequestOptions options) {
    if (options.data == null) return [];

    if (options.data is String) {
      return utf8.encode(options.data as String);
    } else if (options.data is List<int>) {
      return options.data as List<int>;
    } else {
      return utf8.encode(jsonEncode(options.data));
    }
  }

  List<int> _buildMultipartBody(
    ApiRequestOptions options,
    List<ApiMultipartFile> files,
    Map<String, String> formFields,
  ) {
    final boundary = 'boundary${DateTime.now().millisecondsSinceEpoch}';
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
    return body;
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

  void close({bool force = false}) {}
}
