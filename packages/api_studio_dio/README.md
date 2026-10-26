# api_studio_dio

[Dio](https://pub.dev/packages/dio) integration for [API Studio](https://pub.dev/packages/api_studio). One line captures every Dio request into the API Studio in-app inspector (and, optionally, the API Studio cloud dashboard).

```dart
import 'package:api_studio/api_studio.dart';
import 'package:api_studio_dio/api_studio_dio.dart';

await ApiStudio.initialize();
dio.interceptors.add(ApiStudioDioInterceptor());
// anywhere:
ApiStudio.showNavigation(context);
```

## What is captured

URL, method, request headers, query parameters, request body (multipart `FormData` fields plus file name/size, never file bytes), status code, response headers, response body, duration, and on failure the error and stack trace.

- **Cancelled** requests (`CancelToken`) get the `cancelled` status.
- **Timeouts** are labelled, for example `Timeout (receiveTimeout)`.
- **Binary** responses (`ResponseType.bytes`) are stored as a size placeholder.
- **Large** bodies over `maxBodyBytes` (1 MB by default) are truncated and flagged.
- **Sensitive data** is redacted before anything is stored or uploaded. See `RedactionConfig` in `api_studio`.

The interceptor is passive. It never changes, delays or fails a request. When API Studio is disabled (the default in release builds), it does nothing.

## Options

```dart
ApiStudioDioInterceptor(
  captureRequestBody: true,
  captureResponseBody: true,
  filter: (options) => !options.path.startsWith('/health'),
);
```

Add the interceptor **last**, so the captured headers include anything earlier interceptors added (for example auth).

## Name clashes

`package:api_studio` also exports `CancelToken` and `ProgressCallback`, which clash with Dio's. If you import both libraries in the same file, hide them:

```dart
import 'package:api_studio/api_studio.dart' hide CancelToken, ProgressCallback;
```
