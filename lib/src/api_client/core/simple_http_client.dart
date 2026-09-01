/// Minimal HTTP client abstraction used by API Studio's own fire-and-forget
/// backend calls (remote logging + performance telemetry).
///
/// Replaces `package:http` to avoid the extra dependency. The native
/// implementation uses `dart:io HttpClient`; the web implementation uses
/// `package:web XMLHttpRequest`.
library;

export 'simple_http_client_io.dart'
    if (dart.library.js_interop) 'simple_http_client_web.dart';
