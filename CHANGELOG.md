# Changelog

## 1.0.4

### ✨ Added
- `ApiStudio.showNavigation(context)` as a single entry point for API Logs, Performance, and File Explorer through a unified floating bottom navigation bar.
- `baseUrl` and `enableApiClient` parameters on `ApiStudio.initialize()` for unified API Client configuration.
- `ApiStudio.isInitialized`, `ApiStudio.isApiClientEnabled`, and `ApiStudio.configuredBaseUrl` for configuration introspection.
- Optional aggregated remote performance telemetry through `enablePerformanceMonitoring`, uploaded at most once per hour with a persisted upload timestamp and the existing API logging credentials.
- `enablePerformanceMonitoring` configuration on `ApiStudio.initialize()`, defaulting to `false`.

### 🔄 Changed
- Reduced package dependencies and removed unnecessary runtime integrations to keep API Studio lightweight.
- Performance monitoring is fully opt-in and remains inactive during API logging, automatic log upload, navigation initialization, and API Logs usage.
- Disabling Performance now removes frame callbacks, timers, subscriptions, active state, and retained performance samples.
- Frame and memory histories use bounded retention, with lower-frequency memory sampling and aggregated frame chart samples.
- API request and response payload retention and pending remote-log queues are bounded to prevent avoidable memory growth.
- Performance sections update independently to avoid rebuilding the complete inspector for every metric change.
- `DiService.init()` skips API Client logger infrastructure when `enableApiClient` is disabled.
- Jank history uses a fixed-height, horizontally scrollable bar chart.

### ⚠️ Deprecated
- `ApiStudio.initClient()`. Use `ApiStudio.initialize(baseUrl: ..., enableApiClient: true)` instead. The existing API remains available for backward compatibility.