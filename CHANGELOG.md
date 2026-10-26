# Changelog

## 1.1.0

### ⚠️ Behavior changes — please read
- **API Studio is now disabled in release builds by default.** `ApiStudio.initialize()` has a new `enabled` master switch that defaults to `kDebugMode`. When it is off, every API is a no-op: no local storage, no timers, no frame callbacks, no network calls, no UI. To keep using API Studio in QA/profile/release builds, pass `enabled: true`.
- **Sensitive data is now redacted before it is stored locally**, not just before upload, and also in cURL and every export. Values are replaced with `***REDACTED***`. Because headers like `Authorization` are now stored redacted, *Edit & Run* shows a warning and you must re-enter those values before replaying.
- **Remote upload** now replaces sensitive headers with `***REDACTED***` instead of dropping them, and also redacts JSON body keys and query parameters.
- **Retention:** the default `maxStoredLogs` dropped from 10,000 to **500**. Logs older than **7 days** (`logRetention`) are pruned automatically, and total stored body size is capped at ~50 MB.
- **Body limit:** the per-body limit went from 64 K characters to **1 MB** (`maxBodyBytes`). Truncated bodies are flagged and end with an explicit marker.
- The minimum SDK is now **Dart 3.6 / Flutter 3.27**. These were already required in practice by `url_launcher ^6.3.2`; the old constraints were inaccurate.
- `show`, `showNavigation`, `showFileExplorer` and `showPerformanceInspector` are no-ops until `initialize()` has completed successfully. Previously they could open screens that crashed on uninitialized storage.

### ✨ Added
- **First-class Dio and http support** via two optional companion packages, so `dio`/`http` are never forced on users who don't need them:
  - [`api_studio_dio`](https://pub.dev/packages/api_studio_dio): `dio.interceptors.add(ApiStudioDioInterceptor());`
  - [`api_studio_http`](https://pub.dev/packages/api_studio_http): `ApiStudioHttpClient(inner: http.Client())`
  - Both capture URL, method, headers, query, body (incl. multipart descriptors), status, response headers/body, duration, error and stack trace. They handle cancelled requests, timeouts, and binary or oversized bodies, and use the same pipeline as `ApiStudio.log`.
- `RedactionConfig` (`redactHeaders`, `redactBodyKeys`, `includeDefaults`, `redactor` hook) via `ApiStudio.initialize(redaction: ...)`. Body keys are matched recursively and case-insensitively, ignoring `_`/`-`.
- `ApiStudio.initialize(enabled:, logRetention:, maxBodyBytes:, redaction:, navigatorKey:)`.
- `ApiStudio.isEnabled`, `ApiStudio.redaction`, `ApiStudio.maxBodyBytes`.
- `ApiStudio.log(...)` gained `formData`, `isMultipart`, `cancelled`, `requestSizeBytes`, `responseSizeBytes`.
- `ApiStudio.navigatorKey` and `ApiStudio.open()`, to open API Studio without a `BuildContext`.
- `ApiStudio.showFloatingButton([context])` / `hideFloatingButton()`: a draggable debug button.
- **HAR 1.2** and **Postman Collection v2.1** exports, alongside JSON and TXT.
- `ApiLogEntity.isTruncated`.
- `SECURITY.md`, and a README "Privacy and data" section.

### 🔧 Changed
- **Storage moved from the unmaintained `hive`/`hive_flutter` 2.x to `hive_ce`**. The on-disk format is compatible, and existing logs are migrated automatically: logs from ≤ 1.0.7 are re-redacted in place on first launch. Unreadable or corrupt boxes are cleared instead of crashing the app. API Studio no longer calls the global `Hive.init`, so a host app's own Hive home directory is left alone.
- Every capture path (`ApiStudio.log`, interceptors, `ApiStudioClient`, Edit & Run) now goes through one pipeline: redact → truncate → store → notify → upload.
- `ApiStudioClient` is now documented as an *optional* client for manual testing. Interceptors are the recommended path.
- *Edit & Run* now works for requests captured by any integration. It preserves repeated query keys, flattens multi-value headers, and drops stale `Content-Length`/`Host` headers. It also warns when the captured request had redacted values, multipart files or a truncated body.
- Export file names changed from `api_inspector_logs.*` to `api_studio_logs.*`.
- Stricter static analysis (`strict-casts`, `strict-inference`, `strict-raw-types`, and more), with internal widgets now fully typed.
- Removed the `hive_generator` and `build_runner` dev dependencies. The Hive adapter is now hand-written and tolerant of missing or mistyped fields.

### 🗑️ Deprecated
- `ApiStudio.init(...)`: use `ApiStudio.initialize(...)`. It still works and now delegates to `initialize`. Will be removed in 2.0.0.
- `ApiStudio.initClient(...)` (deprecated since 1.0.6): use `ApiStudio.initialize(baseUrl: ...)`.

### 🐛 Fixed
- Log eviction removed the entry with the lexicographically-first UUID key, not the oldest log. Eviction is now by timestamp.
- Install snippet in the README referenced `^1.0.6`.
- Broken emoji in the README "Export Logs" heading.
- The package description claimed built-in Dio interception that didn't exist.
- Tests no longer make real network calls to the API Studio backend.