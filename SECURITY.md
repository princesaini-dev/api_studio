# Security Policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 1.1.x   | ✅ |
| < 1.1   | ❌ (no master switch, no redaction before local storage) |

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security problems. Report them privately through [GitHub Security Advisories](https://github.com/princesaini-dev/api_studio/security/advisories/new). We aim to acknowledge reports within 3 business days.

## Threat model and safe usage

API Studio is a **debugging tool**. By design, it captures network traffic and can browse your app's private files. Treat it like a debugger.

### 1. Keep it out of end-user builds

- `ApiStudio.initialize()` defaults to `enabled: kDebugMode`. In release builds every API is a no-op: no storage, no timers, no frame callbacks, no network calls, and no UI.
- Pass `enabled: true` only for internal builds (QA, staging, dogfood). Never pass it in builds distributed to end users.
- The interceptors (`api_studio_dio`, `api_studio_http`) check the same switch and pass requests through untouched when it is off.

### 2. Redaction

Redaction runs **before** a log is written to local storage, **before** it is queued for remote upload, and again for every export (cURL, JSON, TXT, HAR, Postman).

- **Headers** (case-insensitive), redacted by default: `Authorization`, `Cookie`, `Set-Cookie`, `X-API-Key`, `Proxy-Authorization`.
- **JSON body keys, form fields and query parameters**, redacted recursively and case-insensitively, ignoring `_`/`-` (so `accessToken` matches `access_token`). Defaults: `password`, `token`, `access_token`, `refresh_token`, `secret`, `api_key`, `authorization`, `card_number`, `cvv`.
- Values are replaced with `***REDACTED***`.
- Extend the lists, or add a custom hook, with `RedactionConfig`:

  ```dart
  await ApiStudio.initialize(
    redaction: RedactionConfig(
      redactHeaders: ['X-Session-Id'],
      redactBodyKeys: ['ssn', 'pin'],
      redactor: (log) => log.copyWith(
        url: log.url.replaceAll(RegExp(r'/users/\d+'), '/users/:id'),
      ),
    ),
  );
  ```

- If a custom `redactor` throws, the built-in redaction result is used. If redaction itself fails, the log is dropped rather than stored unredacted.
- Limitation: redaction is key-based. Secrets embedded in free-form text, non-JSON bodies, error messages or URL path segments are **not** detected. Use the `redactor` hook for those.
- Logs stored by API Studio ≤ 1.0.7 (which did not redact before storage) are re-redacted once, automatically, the first time 1.1.0 opens them.

### 3. Remote upload (apistudio.cloud)

- Off unless you pass an `apiKey` to `ApiStudio.initialize`.
- Uploads only already-redacted logs, over HTTPS, authenticated with your API key.
- Fire-and-forget: failures are swallowed, never retried in a tight loop, and never thrown into your app.
- To disable it, omit `apiKey` (or pass `null`).

### 4. Local storage

- Logs are stored with `hive_ce` in `<app documents>/api_studio` (IndexedDB on web). They are **not encrypted**. On a rooted/jailbroken device, or from a device backup, they are readable.
- Retention defaults: 500 logs, 7 days, 1 MB per body, ~50 MB in total. Older logs are pruned automatically.
- Users can clear logs at any time from the inspector.

### 5. File Explorer

The File Explorer is read-only: it can list, open (via the OS) and share files from your app's sandbox, including databases, caches and persisted tokens. It only works while API Studio is enabled, which is one more reason never to enable API Studio in end-user builds.
