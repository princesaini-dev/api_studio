# api_studio_http

[`package:http`](https://pub.dev/packages/http) integration for [API Studio](https://pub.dev/packages/api_studio). Wrap your client and every request shows up in the API Studio in-app inspector (and, optionally, the API Studio cloud dashboard).

```dart
import 'package:api_studio/api_studio.dart';
import 'package:api_studio_http/api_studio_http.dart';
import 'package:http/http.dart' as http;

await ApiStudio.initialize();
final client = ApiStudioHttpClient(inner: http.Client());
final res = await client.get(Uri.parse('https://api.example.com/users'));
```

`ApiStudioHttpClient` extends `http.BaseClient`, so you can use it anywhere an `http.Client` is expected.

## What is captured

URL, method, request headers, query parameters, request body (multipart fields plus file name/size), status code, response headers, response body, duration, and on failure the error and stack trace.

- Requests aborted with `abortTrigger` (`http` 1.5+) get the `cancelled` status.
- `TimeoutException`s thrown by the inner client are labelled as timeouts. A `.timeout()` you add *around* a call happens outside the client, so it can't be observed.
- Binary responses are stored as a size placeholder. Text bodies over `maxBodyBytes` (1 MB by default) are truncated and flagged.
- Sensitive data is redacted before anything is stored or uploaded. See `RedactionConfig` in `api_studio`.

The response stream is forwarded to you chunk by chunk and is never fully buffered. At most `maxBodyBytes + 1` bytes are copied for the inspector. A request is logged once you finish reading the body, or when you cancel the stream. When API Studio is disabled (the default in release builds), requests go straight to the inner client.

## Options

```dart
ApiStudioHttpClient(
  inner: http.Client(),
  captureRequestBody: true,
  captureResponseBody: true,
  filter: (request) => request.url.host != 'telemetry.example.com',
);
```

## Name clashes

`package:api_studio` exports its own `TimeoutException`. If you also use `dart:async`'s `TimeoutException` in the same file, hide it:

```dart
import 'package:api_studio/api_studio.dart' hide TimeoutException;
```
