import 'dart:convert';

import 'package:api_studio/src/api_client/core/simple_http_client.dart';

/// Records every request API Studio's own backend client would send,
/// without touching the network.
class RecordingSimpleHttpClient extends SimpleHttpClient {
  final List<({Uri url, Map<String, String> headers, Object? body})> requests =
      [];
  int statusCode;

  RecordingSimpleHttpClient({this.statusCode = 201});

  @override
  Future<SimpleHttpResponse> post(
    Uri url, {
    required Map<String, String> headers,
    required String body,
    Duration? timeout,
  }) async {
    requests.add((url: url, headers: headers, body: jsonDecode(body)));
    return SimpleHttpResponse(statusCode: statusCode, body: '{}');
  }

  @override
  void close() {}
}
