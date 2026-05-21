import '../models/app_notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> fetchNotifications(String userId);

  Future<void> markAsRead(String notificationId);

  Future<void> markAllAsRead(String userId);
}
