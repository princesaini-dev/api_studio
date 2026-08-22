# Changelog

## Unreleased

### ✨ Added
- `ApiStudio.showNavigation(context)` — a single entry point that opens a unified `ApiStudioNavigationScreen` container with **API Logs**, **Performance** and **File Explorer** accessible through a floating bottom navigation bar.
- `baseUrl` and `enableApiClient` parameters on `ApiStudio.initialize()`, so the built-in API Client is configured through the same unified call instead of a separate `initClient()` step.
- `ApiStudio.isInitialized`, `ApiStudio.isApiClientEnabled` and `ApiStudio.configuredBaseUrl` for introspection.

### 🔄 Changed
- `DiService.init()` now accepts `enableApiClient` and skips creating the `InspectorLogger`/attaching it to `ApiStudioClient` entirely when the API Client is disabled.

### ⚠️ Deprecated
- `ApiStudio.initClient()` is now `@Deprecated`. Use `ApiStudio.initialize(baseUrl: ..., enableApiClient: true)` instead. The old method still works and delegates to the same underlying setup.

## 1.0.3

### ✨ Added
- Optional remote performance telemetry (`POST /api/v1/performance`).
- `enablePerformanceMonitoring` configuration on `ApiStudio.initialize()`, defaulting to `false`.
- Performance metrics remain locally collected by the existing `PerformanceMonitor` — nothing new to configure.
- Aggregated performance data is uploaded at most once per hour, using an internal `PerformanceTelemetryUploader`.
- The last-upload timestamp is persisted (via Hive) so the one-hour interval survives app restarts.
- Uses the existing API key and base URL already configured for API logging — no second API key, no second base URL.
- Performance upload failures are isolated and do not affect normal API requests.