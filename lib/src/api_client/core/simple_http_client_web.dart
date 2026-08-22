import 'dart:async';
import 'dart:html' as html;

/// A minimal HTTP response returned by [SimpleHttpClient].
class SimpleHttpResponse {
  final int statusCode;
  final String body;

  const SimpleHttpResponse({required this.statusCode, required this.body});
}

/// Minimal HTTP client used by API Studio's own backend calls.
///
/// Web implementation backed by `dart:html` [html.HttpRequest]
/// (XMLHttpRequest). On native platforms, a `dart:io`-based implementation
/// is used instead (see `simple_http_client_io.dart`).
class SimpleHttpClient {
  SimpleHttpClient();

  /// Sends a POST request and returns the response.
  Future<SimpleHttpResponse> post(
    Uri url, {
    required Map<String, String> headers,
    required String body,
    Duration? timeout,
  }) async {
    final completer = Completer<SimpleHttpResponse>();

    final request = html.HttpRequest();
    request.open('POST', url.toString());

    for (final e in headers.entries) {
      request.setRequestHeader(e.key, e.value);
    }

    request.onLoad.listen((_) {
      completer.complete(SimpleHttpResponse(
        statusCode: request.status ?? 0,
        body: request.responseText ?? '',
      ));
    });

    request.onError.listen((_) {
      completer.completeError(NetworkException('Request to $url failed'));
    });

    request.send(body);

    try {
      if (timeout != null) {
        return await completer.future.timeout(timeout);
      }
      return await completer.future;
    } on TimeoutException {
      request.abort();
      rethrow;
    }
  }

  void close() {}
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}
