import 'dart:convert';

import 'package:api_studio/src/api_client/core/simple_http_client.dart';

/// Records every request API Studio's own backend client would send,
/// without touching the network.
class RecordingSimpleHttpClient extends SimpleHttpClient {
  final List<({Uri url, Map<String, String> headers, Object? body, bool gzip})>
      requests = [];
  int statusCode;

  RecordingSimpleHttpClient({this.statusCode = 201});

  @override
  Future<SimpleHttpResponse> post(
    Uri url, {
    required Map<String, String> headers,
    required String body,
    Duration? timeout,
    bool gzip = false,
  }) async {
    requests
        .add((url: url, headers: headers, body: jsonDecode(body), gzip: gzip));
    return SimpleHttpResponse(statusCode: statusCode, body: '{}');
  }

  /// Every log uploaded so far, flattened across batch and single requests.
  List<Map<String, dynamic>> get uploadedLogs => [
        for (final r in requests)
          if (r.body is Map && (r.body! as Map).containsKey('logs'))
            for (final l in (r.body! as Map)['logs'] as List)
              l as Map<String, dynamic>
          else if (r.body is Map<String, dynamic>)
            r.body! as Map<String, dynamic>,
      ];

  @override
  void close() {}
}
