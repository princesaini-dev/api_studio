import '../models/api_log_notification_model.dart';

abstract class NotificationProvider {
  Future<void> send(ApiLogNotificationModel log);
}
