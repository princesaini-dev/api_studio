import 'dart:convert';
import 'dart:io';

import '../models/api_log_notification_model.dart';
import 'notification_provider.dart';

class SlackProvider implements NotificationProvider {
  /// Slack Incoming Webhook URL
  final String webhookUrl;

  /// Maximum length for error messages before truncation
  static const int _maxErrorLength = 300;

  /// HTTP client timeout for Slack requests
  static const Duration _timeout = Duration(seconds: 10);

  /// {@macro slack_provider}
  SlackProvider({required this.webhookUrl});

  @override
  Future<void> send(ApiLogNotificationModel log) async {
    try {
      final payload = _buildPayload(log);
      await _sendToSlack(payload);
    } catch (_) {
      // All exceptions are caught to ensure the app never crashes
      // due to notification failures. Failures are silent.
    }
  }

  /// Builds the Slack message payload from the API log.
  Map<String, dynamic> _buildPayload(ApiLogNotificationModel log) {
    final endpoint = _extractEndpoint(log.url);

    return {
      'text': ':rotating_light: API Failure Alert',
      'blocks': [
        {
          'type': 'header',
          'text': {
            'type': 'plain_text',
            'text': ':rotating_light: API Failed',
            'emoji': true,
          },
        },
        {
          'type': 'section',
          'fields': [
            {
              'type': 'mrkdwn',
              'text': '*Method:*\n${log.method}',
            },
            {
              'type': 'mrkdwn',
              'text': '*Endpoint:*\n$endpoint',
            },
          ],
        },
        {
          'type': 'section',
          'fields': [
            {
              'type': 'mrkdwn',
              'text': '*Status:*\n${log.statusCode ?? 'N/A'}',
            },
            {
              'type': 'mrkdwn',
              'text': '*Duration:*\n${_formatDuration(log.duration)}',
            },
          ],
        },
        if (log.errorMessage != null && log.errorMessage!.isNotEmpty)
          {
            'type': 'section',
            'text': {
              'type': 'mrkdwn',
              'text':
                  '*Error:*\n${_truncate(log.errorMessage!, _maxErrorLength)}',
            },
          },
        {
          'type': 'section',
          'fields': [
            {
              'type': 'mrkdwn',
              'text': '*Time:*\n${_formatTimestamp(log.timestamp)}',
            },
            {
              'type': 'mrkdwn',
              'text':
                  '*Internet:*\n${log.internetAvailable ? 'Available' : 'Unavailable'}',
            },
          ],
        },
        {
          'type': 'context',
          'elements': [
            {
              'type': 'mrkdwn',
              'text':
                  'App: ${log.appVersion} | Platform: ${log.platform} | Device: ${log.deviceName}',
            },
          ],
        },
      ],
    };
  }

  /// Sends the payload to Slack webhook.
  Future<void> _sendToSlack(Map<String, dynamic> payload) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(webhookUrl);
      final request = await client.postUrl(uri);

      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload));

      final response = await request.close().timeout(_timeout);

      // Drain the response but don't process it
      await response.drain<void>();
    } finally {
      client.close();
    }
  }

  /// Extracts the endpoint path from a full URL.
  String _extractEndpoint(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.path.isEmpty ? '/' : uri.path;
    } catch (_) {
      return url;
    }
  }

  /// Formats duration in milliseconds to human readable string.
  String _formatDuration(int? durationMs) {
    if (durationMs == null) return 'N/A';
    if (durationMs < 1000) return '${durationMs}ms';
    return '${(durationMs / 1000).toStringAsFixed(2)}s';
  }

  /// Formats timestamp to readable string.
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.year}-${_pad(timestamp.month)}-${_pad(timestamp.day)} '
        '${_pad(timestamp.hour)}:${_pad(timestamp.minute)}:${_pad(timestamp.second)}';
  }

  /// Pads single digit numbers with leading zero.
  String _pad(int number) => number.toString().padLeft(2, '0');

  /// Truncates text if it exceeds maximum length.
  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}... [truncated]';
  }
}
