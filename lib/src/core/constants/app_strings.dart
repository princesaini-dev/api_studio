class AppStrings {
  AppStrings._();

  // App
  static const String appTitle = 'API Inspector';
  static const String packageName = 'API Studio';

  // AppBar actions
  static const String clearAllLogs = 'Clear all logs';
  static const String exportLogs = 'Export';
  static const String exportAsJson = 'Export as JSON';
  static const String exportAsTxt = 'Export as TXT';

  // Search
  static const String searchHint = 'Search by URL or endpoint…';
  static const String searchEndpoint = 'Search endpoint';

  // Filters
  static const String allMethods = 'All Methods';
  static const String allStatus = 'All Status';
  static const String filterMethod = 'Method';
  static const String filterStatus = 'Status';
  static const String filterSort = 'Sort';
  static const String sortNewest = 'Newest';
  static const String sortOldest = 'Oldest';
  static const String sortDuration = 'Duration';
  static const String sortStatusCode = 'Status Code';
  static const String statusSuccess = 'Success';
  static const String statusError = 'Error';

  // Empty states
  static const String noLogsTitle = 'No requests captured';
  static const String noLogsSubtitle = 'Make API calls to see them here';
  static const String noSearchResults = 'No results found';
  static const String noSearchResultsSubtitle =
      'Try adjusting your search or filters';
  static const String noErrors = 'No errors';
  static const String noErrorsSubtitle = 'This request completed successfully';
  static const String noResponse = 'No response';
  static const String noResponseSubtitle =
      'The server did not return a response body';
  static const String noHeaders = 'No headers';
  static const String noCookies = 'No cookies';
  static const String noContent = 'No content';
  static const String noBody = 'No body';
  static const String noFormData = 'No form data';
  static const String noQueryParams = 'No query parameters';

  // Dialogs
  static const String confirmDeleteTitle = 'Delete Request';
  static const String confirmDeleteMessage =
      'Are you sure you want to delete this request log? This cannot be undone.';
  static const String confirmClearTitle = 'Clear all logs?';
  static const String confirmClearMessage = 'This action cannot be undone.';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String clear = 'Clear';

  // Snackbars
  static const String curlCopied = 'cURL copied to clipboard';
  static const String copied = 'Copied!';
  static const String copyFailed = 'Failed to copy';
  static const String exportFailed = 'Export failed';

  // Detail screen tabs
  static const String tabOverview = 'Overview';
  static const String tabRequest = 'Request';
  static const String tabResponse = 'Response';
  static const String tabError = 'Error';

  // Overview tab
  static const String labelUrl = 'URL';
  static const String labelMethod = 'Method';
  static const String labelStatus = 'Status';
  static const String labelDuration = 'Duration';
  static const String labelTimestamp = 'Timestamp';
  static const String labelRequestSize = 'Request Size';
  static const String labelResponseSize = 'Response Size';
  static const String labelHost = 'Host';
  static const String labelPath = 'Path';
  static const String labelContentType = 'Content Type';
  static const String labelProtocol = 'Protocol';
  static const String labelRequestId = 'Request ID';
  static const String labelNotAvailable = 'N/A';

  // Request tab sections
  static const String sectionHeaders = 'Headers';
  static const String sectionQueryParams = 'Query Params';
  static const String sectionBody = 'Body';
  static const String sectionFormData = 'Form Data';
  static const String sectionResponseHeaders = 'Response Headers';
  static const String sectionResponseBody = 'Response Body';
  static const String sectionErrorMessage = 'Error';
  static const String sectionStackTrace = 'Stack Trace';
  static const String sectionErrorSummary = 'Error Summary';

  // Show more/less
  static const String showLess = 'Show less';
  static String showMoreHeaders(int count) =>
      'Show $count more header${count > 1 ? 's' : ''}';

  // Actions
  static const String copyCurl = 'Copy cURL';
  static const String copy = 'Copy';
  static const String editAndRun = 'Edit & Run';
  static const String run = 'RUN';
  static const String deleteLog = 'Delete';
  static const String replay = 'Replay';
  static const String retry = 'Retry';

  // CURL sheet
  static const String curlCommand = 'cURL Command';
  static const String curlDescription =
      'Use this command to replay the request in your terminal';

  // Edit & Run screen
  static const String editRunTitle = 'Edit & Run';
  static const String labelEditMethod = 'Method';
  static const String labelEditUrl = 'URL';
  static const String labelEditHeaders = 'Headers';
  static const String labelEditQueryParams = 'Query Params';
  static const String labelEditBody = 'Body (JSON)';
  static const String urlHint = 'https://api.example.com/endpoint';
  static const String bodyHint = '{"key": "value"}';
  static const String addHeader = 'Add';
  static const String keyHint = 'Key';
  static const String valueHint = 'Value';

  // Badges
  static const String editedBadge = 'EDITED';
  static const String multipartBadge = 'MULTIPART';

  // Loading
  static const String loading = 'Loading…';
  static const String waitingForData = 'Waiting for data…';

  // Units
  static String bytes(int n) => '$n B';
  static String kilobytes(double n) => '${n.toStringAsFixed(1)} KB';
  static String megabytes(double n) => '${n.toStringAsFixed(2)} MB';
  static String milliseconds(int ms) => '${ms}ms';
  static String seconds(double s) => '${s.toStringAsFixed(2)}s';

  static String formatBytes(int? bytes) {
    if (bytes == null) return labelNotAvailable;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  static String formatDuration(int? ms) {
    if (ms == null) return labelNotAvailable;
    if (ms < 1000) return '${ms}ms';
    return '${(ms / 1000).toStringAsFixed(2)}s';
  }

  // File Explorer
  static const String fileExplorer = 'File Explorer';
  static const String openFileExplorer = 'Open File Explorer';
  static const String filesRoot = 'Files';
  static const String back = 'Back';
  static const String refresh = 'Refresh';
  static const String emptyFolder = 'Empty folder';
  static const String emptyFolderSubtitle = 'No files or subfolders here';
  static const String folderLoadFailed = 'Unable to load folder contents';
  static String itemCount(int n) => '$n item${n == 1 ? '' : 's'}';

  // File Actions
  static const String open = 'Open';
  static const String download = 'Download';
  static const String openExternally = 'Open externally';
  static const String unableToOpenExternally =
      'Unable to open this file externally.';
  static const String openExternallySubtitle =
      'You can download the file and open it manually.';
  static const String downloadFailed = 'Download failed';
  static const String downloadSuccess = 'File successfully downloaded.';
  static const String downloadConfirmation = 'Download file?';
  static String downloadConfirmationSubtitle(String name) =>
      'Save $name to your device.';

  // Performance Inspector - Header
  static const String performanceInspector = 'Performance Inspector';
  static const String recording = 'Recording';
  static const String monitoringActive = 'Monitoring active';
  static const String monitoringInactive = 'Monitoring inactive';
  static const String startMonitoring = 'Start monitoring';
  static const String stopMonitoring = 'Stop monitoring';
  static const String clearSession = 'Clear session';

  // Performance Inspector - Overview
  static const String fps = 'FPS';
  static const String fpsTooltip =
      'Frames per second - measures rendering smoothness';
  static const String averageFps = 'Avg FPS';
  static const String minFps = 'Min FPS';
  static const String maxFps = 'Max FPS';
  static const String currentFps = 'Current FPS';
  static const String frameTime = 'Frame Time';
  static const String jankyFrames = 'Janky Frames';
  static const String jankRate = 'Jank Rate';
  static const String uiTime = 'UI Time';
  static const String rasterTime = 'Raster Time';
  static const String memoryUsage = 'Memory Usage';
  static const String peakMemory = 'Peak Memory';
  static const String appStartupTime = 'App Startup Time';
  static const String sessionDuration = 'Session Duration';

  // Performance Inspector - Frame Performance
  static const String framePerformance = 'Frame Performance';
  static const String fpsGraph = 'FPS over time';
  static const String frameTimeGraph = 'Frame time over time';
  static const String avgFrameTime = 'Avg Frame Time';
  static const String slowFrames = 'Slow Frames';
  static const String jankPercentage = 'Jank %';
  static const String uiThreadTime = 'UI Thread Time';
  static const String rasterThreadTime = 'Raster Thread Time';
  static const String totalProcessingTime = 'Total Processing Time';

  // Performance Inspector - Jank
  static const String jankDetection = 'Jank Detection';
  static const String totalFrames = 'Total Frames';
  static const String noJankDetected = 'No jank detected';
  static const String recentSlowFrames = 'Recent Slow Frames';
  static const String worstFrame = 'Worst Frame';
  static const String jank = 'jank';
  static String frameDuration(double ms) => '${ms.toStringAsFixed(1)} ms';

  // Performance Inspector - Memory
  static const String memory = 'Memory';
  static const String memoryNotAvailable =
      'Memory usage is not available on this platform';
  static const String memoryGraph = 'Memory usage over time';
  static const String currentMemory = 'Current Memory';
  static const String minMemory = 'Min Memory';
  static const String memoryGrowth = 'Memory Growth';
  static const String memoryTrend = 'Memory Trend';
  static const String sessionMemoryChange = 'Session Memory Change';
  static const String memoryTrendStable = 'Stable';
  static const String memoryTrendGrowing = 'Growing';
  static const String memoryTrendDecreasing = 'Decreasing';
  static const String memoryTrendUnknown = 'Unknown';

  // Performance Inspector - Startup
  static const String startupPerformance = 'App Startup Performance';
  static const String startupNotAvailable =
      'Startup timing data is not available';
  static const String totalStartupDuration = 'Total Startup Duration';

  // Performance Inspector - Screen
  static const String screenPerformance = 'Screen Performance';
  static const String noScreensTracked = 'No screens are being tracked';
  static const String good = 'Good';
  static const String warning = 'Warning';
  static const String critical = 'Critical';
  static const String unavailable = 'Unavailable';
  static const String active = 'Active';
  static const String notAvailableOnPlatform = 'Not available on this platform';

  // Performance Inspector - Network
  static const String networkPerformance = 'Network Performance';
  static const String noNetworkData = 'No network requests recorded';
  static const String totalRequests = 'Total Requests';
  static const String successfulRequests = 'Successful';
  static const String failedRequests = 'Failed';
  static const String timeouts = 'Timeouts';
  static const String avgResponseTime = 'Avg Response Time';
  static const String slowestRequest = 'Slowest Request';
  static const String fastestRequest = 'Fastest Request';

  // Performance Inspector - Connectivity
  static const String connectivityPerformance = 'Connectivity Performance';
  static const String connected = 'Connected';
  static const String disconnected = 'Disconnected';
  static const String connectivityChanges = 'Connectivity Changes';
  static const String timeOffline = 'Time Offline';
  static const String failedRequestsOffline = 'Failed Requests (Offline)';

  // Performance Inspector - Timeline
  static const String performanceTimeline = 'Performance Timeline';
  static const String noTimelineEvents = 'No events recorded yet';

  // Performance Inspector - Score
  static const String performanceHealth = 'Performance Health';
  static const String performanceScoreDisclaimer =
      'API Studio Performance Score - based on available metrics only';
  static const String gradeExcellent = 'Excellent';
  static const String gradeGood = 'Good';
  static const String gradeFair = 'Fair';
  static const String gradePoor = 'Poor';
  static const String gradeInsufficientData = 'Insufficient Data';
}
