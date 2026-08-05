import 'dart:async' hide TimeoutException;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../cache/cache_store.dart';
import '../cookie/cookie_jar.dart';
import '../core/client_config.dart';
import '../enums/response_type_enum.dart';
import '../exceptions/api_exceptions.dart';
import '../models/api_response.dart';
import '../proxy/proxy_config.dart';
import '../request/api_request_options.dart';
import '../request/cancel_token.dart';
import '../request/multipart_file.dart';
import '../ssl/ssl_config.dart';

typedef ProgressCallback = void Function(int count, int total);

/// Low-level HTTP adapter backed by [dart:io] [HttpClient].
///
/// Handles the raw TCP/TLS connection, multipart encoding, progress
/// callbacks, response buffering and parsing. Everything above this layer
/// (interceptors, retry, auth, cache) lives in [ApiStudioClient].
class HttpAdapter {
  final ClientConfig config;
  final MemoryCacheStore cacheStore;
  final ApiCookieJar cookieJar;

  late final HttpClient _client;

  HttpAdapter({
    required this.config,
    required this.cacheStore,
    required this.cookieJar,
  }) {
    _client = _buildHttpClient(config.ssl, config.proxy);
    _client.connectionTimeout = config.connectTimeout;
  }

  HttpClient _buildHttpClient(SslConfig ssl, ProxyConfig? proxy) {
    SecurityContext? ctx = ssl.securityContext;

    if (ssl.pinnedCertificates != null && ssl.pinnedCertificates!.isNotEmpty) {
      ctx ??= SecurityContext(withTrustedRoots: true);
      for (final cert in ssl.pinnedCertificates!) {
        ctx.setTrustedCertificatesBytes(cert);
      }
    }

    final client = ctx != null ? HttpClient(context: ctx) : HttpClient();

    if (ssl.ignoreSsl) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    }

    if (proxy != null) {
      client.findProxy = (uri) => proxy.proxyUrl;
      if (proxy.username != null && proxy.password != null) {
        client.addProxyCredentials(
          proxy.host,
          proxy.port,
          'Basic',
          HttpClientBasicCredentials(proxy.username!, proxy.password!),
        );
      }
    }

    return client;
  }

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

    // Build the dart:io request
    final HttpClientRequest ioRequest;
    try {
      ioRequest = await _client
          .openUrl(options.method.value, uri)
          .timeout(options.connectTimeout ?? config.connectTimeout);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Socket error: ${e.message}',
        requestOptions: options,
      );
    } on HandshakeException catch (e) {
      throw SslException(
        message: 'SSL handshake failed: ${e.message}',
        requestOptions: options,
      );
    } on TimeoutException {
      throw TimeoutException(requestOptions: options);
    }

    ioRequest.followRedirects = options.followRedirects;

    // Default headers
    for (final e in config.defaultHeaders.entries) {
      ioRequest.headers.set(e.key, e.value);
    }

    // Per-request headers
    for (final e in options.headers.entries) {
      ioRequest.headers.set(e.key, e.value.toString());
    }

    // Cookie header
    if (config.enableCookies) {
      final cookieHeader = cookieJar.buildHeader(uri.host);
      if (cookieHeader != null) {
        ioRequest.headers.set(HttpHeaders.cookieHeader, cookieHeader);
      }
    }

    // Cancellation wiring
    if (cancelToken != null && cancelToken.isCancelled) {
      ioRequest.abort();
      throw CancelledException(requestOptions: options);
    }

    // Body / multipart
    if (files.isNotEmpty || formFields.isNotEmpty) {
      await _writeMultipart(
        ioRequest,
        files: files,
        formFields: formFields,
        onProgress: onSendProgress,
      );
    } else if (options.data != null) {
      await _writeBody(ioRequest, options.data!, onSendProgress);
    }

    // Fire request — with cancel and timeout
    final HttpClientResponse ioResponse;
    try {
      final responseFuture = ioRequest.close();
      if (cancelToken != null) {
        ioResponse = await Future.any([
          responseFuture,
          cancelToken.whenCancel.then((_) {
            ioRequest.abort();
            throw CancelledException(requestOptions: options);
          }),
        ]);
      } else {
        ioResponse = await responseFuture
            .timeout(options.receiveTimeout ?? config.receiveTimeout);
      }
    } on CancelledException {
      rethrow;
    } on TimeoutException {
      throw TimeoutException(requestOptions: options);
    } on SocketException catch (e) {
      throw NetworkException(
        message: 'Network error: ${e.message}',
        requestOptions: options,
      );
    }

    // Parse response headers
    final responseHeaders = <String, String>{};
    ioResponse.headers.forEach((name, values) {
      responseHeaders[name] = values.join(', ');
    });

    // Cookies
    if (config.enableCookies) {
      final setCookies = ioResponse.headers[HttpHeaders.setCookieHeader];
      if (setCookies != null) {
        cookieJar.parseAndSave(uri.host, setCookies);
      }
    }

    // Read body
    final bodyBytes = await _readBody(
      ioResponse,
      onReceiveProgress,
      cancelToken,
      options,
    );

    final statusCode = ioResponse.statusCode;
    final T? data = await _parseResponse<T>(
      options.responseType,
      bodyBytes,
      statusCode,
      options,
    );

    final response = ApiResponse<T>(
      data: data,
      statusCode: statusCode,
      headers: responseHeaders,
      requestOptions: options,
    );

    // Cache store
    if (cachePolicy != null && cachePolicy.enabled && statusCode < 300) {
      cacheStore.put(cacheKey, response, cachePolicy.ttl);
    }

    return response;
  }

  Future<void> _writeBody(
    HttpClientRequest request,
    dynamic data,
    ProgressCallback? onProgress,
  ) async {
    late final List<int> bytes;
    if (data is String) {
      bytes = utf8.encode(data);
    } else if (data is List<int>) {
      bytes = data;
    } else {
      final json = jsonEncode(data);
      bytes = utf8.encode(json);
      if (request.headers.value(HttpHeaders.contentTypeHeader) == null) {
        request.headers.contentType =
            ContentType('application', 'json', charset: 'utf-8');
      }
    }
    request.contentLength = bytes.length;
    if (onProgress != null) onProgress(0, bytes.length);
    request.add(bytes);
    if (onProgress != null) onProgress(bytes.length, bytes.length);
  }

  Future<void> _writeMultipart(
    HttpClientRequest request, {
    required List<ApiMultipartFile> files,
    required Map<String, String> formFields,
    ProgressCallback? onProgress,
  }) async {
    final boundary = 'boundary${DateTime.now().millisecondsSinceEpoch}';
    request.headers.contentType = ContentType(
      'multipart',
      'form-data',
      parameters: {'boundary': boundary},
    );

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

    request.contentLength = body.length;
    if (onProgress != null) onProgress(0, body.length);
    request.add(body);
    if (onProgress != null) onProgress(body.length, body.length);
  }

  Future<Uint8List> _readBody(
    HttpClientResponse response,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
    ApiRequestOptions options,
  ) async {
    final chunks = <int>[];
    final contentLength = response.contentLength;
    int received = 0;

    await for (final chunk in response) {
      if (cancelToken != null && cancelToken.isCancelled) {
        throw CancelledException(requestOptions: options);
      }
      chunks.addAll(chunk);
      received += chunk.length;
      if (onProgress != null) onProgress(received, contentLength);
    }

    return Uint8List.fromList(chunks);
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

  void close({bool force = false}) => _client.close(force: force);
}
