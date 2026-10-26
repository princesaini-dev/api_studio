import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:api_studio/api_studio.dart' show ApiStudio;
import 'package:http/http.dart' as http;

/// Decides whether a request should be captured. Return `false` to skip it.
typedef ApiStudioHttpFilter = bool Function(http.BaseRequest request);

/// A `package:http` client that captures every request into API Studio.
///
/// Wrap your existing client (or let it create a default one):
///
/// ```dart
/// final client = ApiStudioHttpClient(inner: http.Client());
/// final res = await client.get(Uri.parse('https://api.example.com/users'));
/// ```
///
/// Records URL, method, request headers, query parameters, body (including
/// multipart fields and file descriptors), status code, response headers,
/// response body, duration and — on failure — the error and stack trace.
/// Requests aborted via `abortTrigger` are recorded as cancelled; timeouts
/// thrown by the inner client are labelled as such.
///
/// Everything flows through the same pipeline as `ApiStudio.log`, so
/// redaction, body truncation, local storage and optional cloud upload all
/// apply.
///
/// The response stream is forwarded chunk-by-chunk (it is never fully
/// buffered); at most `ApiStudio.maxBodyBytes + 1` bytes are copied for the
/// inspector. The log is written once the body has been fully read (or the
/// caller cancels the stream). When API Studio is disabled, requests are
/// passed straight to the inner client.
class ApiStudioHttpClient extends http.BaseClient {
  final http.Client _inner;

  /// Whether request bodies are captured. Defaults to `true`.
  final bool captureRequestBody;

  /// Whether response bodies are captured. Defaults to `true`.
  final bool captureResponseBody;

  /// Optional filter; return `false` to skip capturing a request.
  final ApiStudioHttpFilter? filter;

  /// Wraps [inner] (defaults to a new [http.Client]).
  ApiStudioHttpClient({
    http.Client? inner,
    this.captureRequestBody = true,
    this.captureResponseBody = true,
    this.filter,
  }) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!_shouldCapture(request)) return _inner.send(request);

    final timestamp = DateTime.now();
    final stopwatch = Stopwatch()..start();
    final capture = _RequestCapture.from(request, captureRequestBody);

    final http.StreamedResponse response;
    try {
      response = await _inner.send(request);
    } catch (e, st) {
      stopwatch.stop();
      _log(request, capture, timestamp, stopwatch, error: e, stackTrace: st);
      rethrow;
    }

    final limit = ApiStudio.maxBodyBytes + 1;
    final captured = BytesBuilder(copy: false);
    var total = 0;
    var finished = false;
    StreamSubscription<List<int>>? sub;
    late final StreamController<List<int>> controller;

    void finish({Object? error, StackTrace? stackTrace}) {
      if (finished) return;
      finished = true;
      stopwatch.stop();
      _log(
        request,
        capture,
        timestamp,
        stopwatch,
        response: response,
        body: captureResponseBody ? captured.takeBytes() : null,
        totalBytes: total,
        error: error,
        stackTrace: stackTrace,
      );
    }

    controller = StreamController<List<int>>(
      sync: true,
      onListen: () {
        sub = response.stream.listen(
          (chunk) {
            total += chunk.length;
            final room = limit - captured.length;
            if (captureResponseBody && room > 0) {
              captured
                  .add(chunk.length <= room ? chunk : chunk.sublist(0, room));
            }
            controller.add(chunk);
          },
          onError: (Object e, StackTrace st) {
            finish(error: e, stackTrace: st);
            controller.addError(e, st);
          },
          onDone: () {
            finish();
            controller.close();
          },
          cancelOnError: true,
        );
      },
      onPause: () => sub?.pause(),
      onResume: () => sub?.resume(),
      onCancel: () {
        finish();
        return sub?.cancel();
      },
    );

    return _TappedStreamedResponse(
      http.ByteStream(controller.stream),
      response,
    );
  }

  bool _shouldCapture(http.BaseRequest request) {
    try {
      return ApiStudio.isEnabled && (filter?.call(request) ?? true);
    } catch (_) {
      return false;
    }
  }

  void _log(
    http.BaseRequest request,
    _RequestCapture capture,
    DateTime timestamp,
    Stopwatch stopwatch, {
    http.StreamedResponse? response,
    Uint8List? body,
    int? totalBytes,
    Object? error,
    StackTrace? stackTrace,
  }) {
    try {
      final headers = response?.headers ?? const <String, String>{};
      unawaited(ApiStudio.log(
        url: request.url.toString(),
        method: request.method,
        statusCode: response?.statusCode,
        durationMs: stopwatch.elapsedMilliseconds,
        timestamp: timestamp,
        requestHeaders: Map<String, dynamic>.from(request.headers),
        queryParameters: {
          for (final e in request.url.queryParametersAll.entries)
            e.key: e.value.length == 1 ? e.value.first : e.value,
        },
        requestBody: capture.body,
        formData: capture.formData,
        isMultipart: capture.formData != null,
        requestSizeBytes: request.contentLength,
        responseHeaders: Map<String, dynamic>.from(headers),
        responseBody: body == null ? null : _decodeBody(body, headers),
        responseSizeBytes: totalBytes,
        errorMessage: error == null ? null : _describeError(error),
        stackTrace: stackTrace,
        cancelled: error is http.RequestAbortedException,
      ));
    } catch (_) {
      // Capturing must never affect the host app's request.
    }
  }

  static dynamic _decodeBody(Uint8List bytes, Map<String, String> headers) {
    if (bytes.isEmpty) return null;
    final type = (headers['content-type'] ?? '').toLowerCase();
    final textual = type.isEmpty ||
        type.startsWith('text/') ||
        type.contains('json') ||
        type.contains('xml') ||
        type.contains('javascript') ||
        type.contains('x-www-form-urlencoded') ||
        type.contains('graphql');
    if (!textual) return bytes;
    try {
      return utf8.decode(bytes);
    } on FormatException {
      // Either binary, or a multi-byte character was cut at the capture
      // limit; decode leniently if it looks like text.
      return type.isEmpty ? bytes : utf8.decode(bytes, allowMalformed: true);
    }
  }

  static String _describeError(Object e) {
    if (e is TimeoutException) return 'Timeout: ${e.message ?? e}';
    if (e is http.RequestAbortedException) return 'Request cancelled';
    if (e is http.ClientException) return e.message;
    return e.toString();
  }

  @override
  void close() => _inner.close();
}

class _RequestCapture {
  final dynamic body;
  final Map<String, dynamic>? formData;

  const _RequestCapture(this.body, this.formData);

  factory _RequestCapture.from(http.BaseRequest request, bool captureBody) {
    if (!captureBody) return const _RequestCapture(null, null);
    if (request is http.Request) {
      final bytes = request.bodyBytes;
      if (bytes.isEmpty) return const _RequestCapture(null, null);
      try {
        return _RequestCapture(request.body, null);
      } catch (_) {
        return _RequestCapture(bytes, null);
      }
    }
    if (request is http.MultipartRequest) {
      final form = <String, dynamic>{...request.fields};
      for (final f in request.files) {
        form[f.field] = '[file: ${f.filename ?? 'unnamed'}, ${f.length} bytes'
            '${f.contentType.mimeType.isEmpty ? '' : ', ${f.contentType.mimeType}'}]';
      }
      return _RequestCapture(null, form);
    }
    return const _RequestCapture('[streamed body]', null);
  }
}

class _TappedStreamedResponse extends http.StreamedResponse
    implements http.BaseResponseWithUrl {
  @override
  final Uri url;

  _TappedStreamedResponse(http.ByteStream stream, http.StreamedResponse source)
      : url = source is http.BaseResponseWithUrl
            ? (source as http.BaseResponseWithUrl).url
            : (source.request?.url ?? Uri()),
        super(
          stream,
          source.statusCode,
          contentLength: source.contentLength,
          request: source.request,
          headers: source.headers,
          isRedirect: source.isRedirect,
          persistentConnection: source.persistentConnection,
          reasonPhrase: source.reasonPhrase,
        );
}
