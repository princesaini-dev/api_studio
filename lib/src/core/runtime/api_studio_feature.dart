/// Optional add-ons shown next to API Logs (the core of API Studio).
///
/// Enable them with `ApiStudio.initialize(features: {...})`. Disabled
/// add-ons get no tab in the API Studio screen and do no work.
enum ApiStudioFeature {
  /// Performance tab: FPS, jank, memory, startup and screen timings.
  /// Also enabled by `initialize(enablePerformanceMonitoring: true)`.
  performance,

  /// Files tab: a read-only browser for the app's sandbox (databases,
  /// caches, shared preferences). Can expose sensitive files, so it is
  /// never enabled by default.
  fileExplorer,
}
