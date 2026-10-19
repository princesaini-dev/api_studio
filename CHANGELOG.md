# Changelog

## 1.0.7

### 🚀 Cloud Sync & Web Portal Upgrades
- **Near Real-time Sync**: Automatic debounced upload (1.5s debounce, immediate on error) ensures logs appear on the API Studio Cloud Dashboard (`https://apistudio.cloud/`) instantly instead of waiting up to 5 minutes.
- **Queue Poison-Pill Resilience**: If the cloud backend returns a 4xx client error (e.g. malformed or rejected payload), the payload is discarded so subsequent logs continue to upload without stalling the entire queue.
- **Manual Flush API**: Added `ApiStudio.flush()` and `ApiStudioRemoteLogger.uploadNow()` to immediately push all pending logs to the cloud on demand.
- **Auto-Flush on App Backgrounding**: Automatically flushes pending logs via `AppLifecycleListener` when the app is paused, hidden, or detached so no logs are lost on app exit.

### ✨ Universal Logging Support (Dio, Http, GraphQL, etc.)
- Added `ApiStudio.log(...)`: A universal logging API enabling any HTTP client (Dio, `package:http`, Chopper, GraphQL, Supabase, Firebase, etc.) to log directly into both the in-app Inspector and the API Studio Cloud Dashboard.

### ⚡ Performance & Memory Optimization
- **O(1) Hive Log Eviction**: Replaced full-database scan and deserialization (`values.reduce(...)`) with O(1) `deleteAt(0)` eviction, eliminating memory spikes and garbage collection pauses when reaching `maxStoredLogs`.
- **Smooth, Flicker-Free Real-time UI**: Background log updates now update the list silently in-place without flashing loading shimmers or resetting scroll position. Added a 150ms debounce for high-frequency bursts.
- **Debounced Search**: Added a 250ms debounce to `SearchBarWidget` to eliminate database query thrashing on every keystroke.
- **Single-Pass JSON Formatter**: Optimized `JsonFormatter.format()` to decode and format payloads in a single pass instead of double-decoding.
- **One-Tap JSON Copy**: Added a floating copy button directly in the `JsonViewer` for quick copying.
- **Shared Cache & Cookie Store**: Fixed `ApiStudioClient` to share the exact same `MemoryCacheStore` and `ApiCookieJar` instances with `HttpAdapter`.

### 🎯 Accuracy & Cross-Platform Reliability
- **POSIX-Compliant cURL Generator**: Fixed single-quote escaping (`'\''`) so copied cURL commands paste and execute cleanly in Terminal/Bash/Zsh without quote syntax errors. Query parameters now merge cleanly via `Uri` without duplicating `?`.
- **Cross-Platform Edit & Run**: Refactored `RunRequestUseCase` to use `HttpAdapter`, removing unconditional `dart:io` imports and enabling Edit & Run across mobile, desktop, and web.
- **Zero Analyzer Warnings**: Migrated all example screens to `ApiStudio.initialize(...)`, achieving a clean 0-warning `flutter analyze` score.