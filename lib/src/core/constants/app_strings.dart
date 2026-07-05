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
}
