# Changelog

## 1.0.3

### ✨ Added
- Optional remote performance telemetry (`POST /api/v1/performance`).
- `enablePerformanceMonitoring` configuration on `ApiStudio.initialize()`, defaulting to `false`.
- Performance metrics remain locally collected by the existing `PerformanceMonitor` — nothing new to configure.
- Aggregated performance data is uploaded at most once per hour, using an internal `PerformanceTelemetryUploader`.
- The last-upload timestamp is persisted (via Hive) so the one-hour interval survives app restarts.
- Uses the existing API key and base URL already configured for API logging — no second API key, no second base URL.
- Performance upload failures are isolated and do not affect normal API requests.