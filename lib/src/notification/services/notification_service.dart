import 'dart:async';
import 'dart:io';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/api_log_entity.dart';
import '../../services/connectivity_service.dart';
import '../config/notification_config.dart';
import '../models/api_log_notification_model.dart';
import '../providers/notification_provider.dart';
import '../providers/slack_provider.dart';
import '../utils/sensitive_data_masker.dart';

class NotificationService {
  /// Configuration for the notification system
  final NotificationConfig config;

  /// List of registered notification providers
  final List<NotificationProvider> _providers = [];

  /// Application version for notification context
  final String? appVersion;

  /// Device information cache
  String _deviceName = 'Unknown';
  String _osVersion = 'Unknown';
  String _platform = 'Unknown';

  /// Whether the service has been initialized
  bool _initialized = false;

  /// {@macro notification_service}
  NotificationService({required this.config, this.appVersion});

  /// Whether the service has any active notification providers
  bool get hasProviders => _providers.isNotEmpty || config.isCallbackEnabled;

  /// Initializes the notification service.
  ///
  /// This method must be called before [notifyApiFailed]. It:
  /// 1. Gathers device and app information
  /// 2. Registers providers based on configuration
  /// 3. Prepares the service for operation
  ///
  /// This method is idempotent - calling it multiple times is safe.
  Future<void> initialize() async {
    if (_initialized) return;

    await _gatherDeviceInfo();
    await _gatherAppInfo();
    _registerProviders();

    _initialized = true;
  }

  /// Dispatches a notification for a failed API request.
  ///
  /// This method:
  /// 1. Transforms [ApiLogEntity] to [ApiLogNotificationModel]
  /// 2. Masks sensitive data
  /// 3. Invokes the callback if configured
  /// 4. Dispatches to all registered providers asynchronously
  ///
  /// This method is fire-and-forget. It returns immediately and
  /// notifications are sent in the background.
  ///
  /// [log] the failed API log entity
  Future<void> notifyApiFailed(ApiLogEntity log) async {
    if (!_initialized) {
      await initialize();
    }

    // Transform entity to notification model
    final notificationModel = await _transformLog(log);

    // Execute callback first (if configured)
    _executeCallback(notificationModel);

    // Send to all providers asynchronously (non-blocking)
    if (_providers.isNotEmpty) {
      _dispatchToProviders(notificationModel);
    }
  }

  /// Gathers device information for inclusion in notifications.
  Future<void> _gatherDeviceInfo() async {
    try {
      _platform = Platform.operatingSystem;
      _osVersion = Platform.operatingSystemVersion;

      // Attempt to get a more readable device name
      if (Platform.isAndroid) {
        _deviceName = 'Android Device';
      } else if (Platform.isIOS) {
        _deviceName = 'iOS Device';
      } else if (Platform.isMacOS) {
        _deviceName = 'macOS';
      } else if (Platform.isWindows) {
        _deviceName = 'Windows';
      } else if (Platform.isLinux) {
        _deviceName = 'Linux';
      } else {
        _deviceName = 'Unknown Device';
      }
    } catch (_) {
      // Use defaults if platform info is unavailable
    }
  }

  /// Gathers app information for inclusion in notifications.
  Future<void> _gatherAppInfo() async {
    // App version is now passed via constructor or uses fallback
    // No async work needed here anymore
  }

  /// Registers notification providers based on configuration.
  void _registerProviders() {
    _providers.clear();

    // Register Slack provider if webhook is configured
    if (config.isSlackEnabled) {
      _providers.add(SlackProvider(webhookUrl: config.slackWebhook!));
    }
  }

  /// Transforms [ApiLogEntity] to [ApiLogNotificationModel].
  Future<ApiLogNotificationModel> _transformLog(ApiLogEntity log) async {
    final effectiveAppVersion = appVersion ?? AppConstants.packageVersion;
    final isConnected = ConnectivityService.instance.isConnected;

    // Determine error type
    final isTimeout = _isTimeoutError(log);
    final isCancelled = _isCancelledError(log);

    // Mask sensitive data
    final maskedRequestHeaders =
        SensitiveDataMasker.maskHeaders(log.requestHeaders);
    final maskedResponseHeaders =
        SensitiveDataMasker.maskHeaders(log.responseHeaders);
    final maskedRequestBody = SensitiveDataMasker.maskBody(log.requestBody);
    final maskedResponseBody = SensitiveDataMasker.maskBody(log.responseBody);

    return ApiLogNotificationModel(
      method: log.method.name.toUpperCase(),
      url: log.url,
      statusCode: log.statusCode,
      requestHeaders: maskedRequestHeaders,
      responseHeaders: maskedResponseHeaders,
      requestBody: maskedRequestBody,
      responseBody: maskedResponseBody,
      errorMessage: log.errorMessage,
      duration: log.durationMs,
      timestamp: log.timestamp,
      internetAvailable: isConnected,
      appVersion: effectiveAppVersion,
      platform: _platform,
      deviceName: _deviceName,
      osVersion: _osVersion,
      isTimeout: isTimeout,
      isCancelled: isCancelled,
    );
  }

  /// Executes the user-provided callback if configured.
  void _executeCallback(ApiLogNotificationModel log) {
    final callback = config.onApiFailed;
    if (callback != null) {
      try {
        callback(log);
      } catch (_) {
        // Callback errors should not affect notification flow
      }
    }
  }

  /// Dispatches the notification to all registered providers.
  ///
  /// This method runs all provider notifications concurrently and
  /// ignores any failures.
  void _dispatchToProviders(ApiLogNotificationModel log) {
    for (final provider in _providers) {
      // Fire and forget - never await, never block
      _sendToProvider(provider, log);
    }
  }

  /// Sends notification to a single provider.
  ///
  /// Wrapped in a zone and try-catch to ensure absolutely no errors
  /// propagate to the caller.
  void _sendToProvider(
      NotificationProvider provider, ApiLogNotificationModel log) {
    // Use unawaited to ensure we don't block
    unawaited(
      _safeSend(provider, log),
    );
  }

  /// Safely sends notification to a provider, catching all errors.
  Future<void> _safeSend(
      NotificationProvider provider, ApiLogNotificationModel log) async {
    try {
      await provider.send(log);
    } catch (_) {
      // All provider errors are silently ignored
    }
  }

  /// Determines if the error was a timeout.
  bool _isTimeoutError(ApiLogEntity log) {
    final errorMsg = log.errorMessage?.toLowerCase() ?? '';
    return errorMsg.contains('timeout') ||
        errorMsg.contains('timed out') ||
        errorMsg.contains('deadline exceeded');
  }

  /// Determines if the error was a cancellation.
  bool _isCancelledError(ApiLogEntity log) {
    final errorMsg = log.errorMessage?.toLowerCase() ?? '';
    return errorMsg.contains('cancel') ||
        errorMsg.contains('cancelled') ||
        errorMsg.contains('aborted');
  }

  /// Disposes the service and cleans up resources.
  void dispose() {
    _providers.clear();
    _initialized = false;
  }
}
