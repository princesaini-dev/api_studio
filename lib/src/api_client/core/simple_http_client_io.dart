import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A minimal HTTP response returned by [SimpleHttpClient].
class SimpleHttpResponse {
  final int statusCode;
  final String body;

  const SimpleHttpResponse({required this.statusCode, required this.body});
}

/// Minimal HTTP client used by API Studio's own backend calls.
///
/// Native implementation backed by `dart:io` [HttpClient]. On web, a
/// `dart:html`-based implementation is used instead (see
/// `simple_http_client_web.dart`).
class SimpleHttpClient {
  late final HttpClient _client;

  SimpleHttpClient() {
    _client = HttpClient();
  }

  /// Sends a POST request and returns the response.
  Future<SimpleHttpResponse> post(
    Uri url, {
    required Map<String, String> headers,
    required String body,
    Duration? timeout,
  }) async {
    final completer = Completer<SimpleHttpResponse>();

    _client.postUrl(url).then((ioRequest) {
      for (final e in headers.entries) {
        ioRequest.headers.set(e.key, e.value);
      }
      ioRequest.contentLength = utf8.encode(body).length;
      ioRequest.write(body);

      ioRequest.close().then((ioResponse) {
        final sb = StringBuffer();
        ioResponse.transform(utf8.decoder).listen(
          (chunk) => sb.write(chunk),
          onDone: () {
            completer.complete(SimpleHttpResponse(
              statusCode: ioResponse.statusCode,
              body: sb.toString(),
            ));
          },
          onError: (e) {
            completer.completeError(e);
          },
        );
      }).catchError((e) {
        completer.completeError(e);
      });
    }).catchError((e) {
      completer.completeError(e);
    });

    try {
      if (timeout != null) {
        return await completer.future.timeout(timeout);
      }
      return await completer.future;
    } on TimeoutException {
      rethrow;
    }
  }

  void close() => _client.close(force: true);
}
