import '../models/api_log_notification_model.dart';

class NotificationConfig {
  final String? slackWebhook;

  final void Function(ApiLogNotificationModel log)? onApiFailed;

  /// {@macro notification_config}
  const NotificationConfig({
    this.slackWebhook,
    this.onApiFailed,
  });

  /// Whether Slack notifications are enabled (webhook URL is provided).
  bool get isSlackEnabled => slackWebhook != null && slackWebhook!.isNotEmpty;

  /// Whether custom callback is enabled.
  bool get isCallbackEnabled => onApiFailed != null;

  /// Whether any notification is configured.
  bool get hasAnyNotification => isSlackEnabled || isCallbackEnabled;
}
