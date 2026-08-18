# Changelog

## 1.0.2

### ✨ Added
- Performance Inspector — a full-screen performance monitoring tool.
- Real-time FPS, frame time, jank detection, and memory usage tracking.
- App startup phase timing with visual progress bars.
- Per-screen performance tracking with status badges.
- Network and connectivity performance summary sections in the Performance Inspector.
- Performance timeline with event history and severity icons.
- Performance health score with a descriptive grade and progress bar.
- Recording controls to capture and clear performance sessions.
- Platform-aware memory metrics (native via `ProcessInfo`; unavailable on web).
- Public API: `ApiStudio.showPerformanceInspector(context)`.
- Programmatic monitoring API: `ApiStudio.startPerformanceMonitoring()` / `stopPerformanceMonitoring()`.
- Performance snapshot stream for custom integrations.

### 🚀 Improved
- All Performance Inspector strings centralized in `AppStrings`.
- Performance widgets use `RepaintBoundary` for minimal overhead.
- UI updates throttled to 500ms intervals to avoid unnecessary rebuilds.

### 🐛 Fixed
- Screen performance tracking now correctly attributes live frame and memory samples to the currently active screen (previously always reported 0 FPS / 0 janky frames regardless of real performance).
- `file_download_service_io.dart`: the Android download fallback now correctly `await`s the copy step inside its `try` block, so a failed write is actually caught and the next candidate directory is tried.

### 🔧 Changed
- Updated `flutter_bloc` and `bloc` to the v9 major release.
- Updated `bloc_test` to the v10 major release.
- Updated `share_plus` to v12.
- Updated `intl` to v0.20.
- Updated `flutter_lints` to v6.