import 'package:equatable/equatable.dart';

class ApiLogNotificationModel extends Equatable {
  /// HTTP method used for the request (GET, POST, PUT, DELETE, etc.)
  final String method;

  /// Complete URL of the API endpoint
  final String url;

  /// HTTP status code returned by the server (null if request failed to reach server)
  final int? statusCode;

  /// Request headers sent with the API call
  /// Note: Sensitive headers are automatically masked by the notification system
  final Map<String, dynamic> requestHeaders;

  /// Response headers received from the server
  final Map<String, dynamic> responseHeaders;

  /// Request body sent to the server (null for GET requests or if empty)
  final String? requestBody;

  /// Response body received from the server (null if request failed)
  final String? responseBody;

  /// Error message describing why the API call failed
  final String? errorMessage;

  /// Duration of the API request in milliseconds
  final int? duration;

  /// Timestamp when the API request was made
  final DateTime timestamp;

  /// Whether internet was available at the time of the request
  final bool internetAvailable;

  /// Application version string
  final String appVersion;

  /// Platform identifier (iOS, Android, macOS, Windows, Linux, Web)
  final String platform;

  /// Device name or model
  final String deviceName;

  /// Operating system version
  final String osVersion;

  /// Whether the error was due to a timeout
  final bool isTimeout;

  /// Whether the request was cancelled by the user
  final bool isCancelled;

  /// {@macro api_log_notification_model}
  const ApiLogNotificationModel({
    required this.method,
    required this.url,
    this.statusCode,
    required this.requestHeaders,
    required this.responseHeaders,
    this.requestBody,
    this.responseBody,
    this.errorMessage,
    this.duration,
    required this.timestamp,
    required this.internetAvailable,
    required this.appVersion,
    required this.platform,
    required this.deviceName,
    required this.osVersion,
    required this.isTimeout,
    required this.isCancelled,
  });

  /// Creates a copy of this [ApiLogNotificationModel] with the given fields
  /// replaced with the new values.
  ApiLogNotificationModel copyWith({
    String? method,
    String? url,
    int? statusCode,
    Map<String, dynamic>? requestHeaders,
    Map<String, dynamic>? responseHeaders,
    String? requestBody,
    String? responseBody,
    String? errorMessage,
    int? duration,
    DateTime? timestamp,
    bool? internetAvailable,
    String? appVersion,
    String? platform,
    String? deviceName,
    String? osVersion,
    bool? isTimeout,
    bool? isCancelled,
  }) {
    return ApiLogNotificationModel(
      method: method ?? this.method,
      url: url ?? this.url,
      statusCode: statusCode ?? this.statusCode,
      requestHeaders: requestHeaders ?? this.requestHeaders,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      requestBody: requestBody ?? this.requestBody,
      responseBody: responseBody ?? this.responseBody,
      errorMessage: errorMessage ?? this.errorMessage,
      duration: duration ?? this.duration,
      timestamp: timestamp ?? this.timestamp,
      internetAvailable: internetAvailable ?? this.internetAvailable,
      appVersion: appVersion ?? this.appVersion,
      platform: platform ?? this.platform,
      deviceName: deviceName ?? this.deviceName,
      osVersion: osVersion ?? this.osVersion,
      isTimeout: isTimeout ?? this.isTimeout,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }

  /// Converts this [ApiLogNotificationModel] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'method': method,
      'url': url,
      'statusCode': statusCode,
      'requestHeaders': requestHeaders,
      'responseHeaders': responseHeaders,
      'requestBody': requestBody,
      'responseBody': responseBody,
      'errorMessage': errorMessage,
      'duration': duration,
      'timestamp': timestamp.toIso8601String(),
      'internetAvailable': internetAvailable,
      'appVersion': appVersion,
      'platform': platform,
      'deviceName': deviceName,
      'osVersion': osVersion,
      'isTimeout': isTimeout,
      'isCancelled': isCancelled,
    };
  }

  @override
  List<Object?> get props => [
        method,
        url,
        statusCode,
        requestHeaders,
        responseHeaders,
        requestBody,
        responseBody,
        errorMessage,
        duration,
        timestamp,
        internetAvailable,
        appVersion,
        platform,
        deviceName,
        osVersion,
        isTimeout,
        isCancelled,
      ];
}
