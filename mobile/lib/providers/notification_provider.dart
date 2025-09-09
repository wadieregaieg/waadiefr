import 'package:flutter/foundation.dart';
import '../models/notification_item.dart';
import '../models/order.dart';
import 'package:uuid/uuid.dart';

class NotificationProvider with ChangeNotifier {
  // Map of userId -> List of notifications for that user.
  final Map<String, List<NotificationItem>> _userNotifications = {};

  List<NotificationItem> notificationsForUser(String userId) {
    return _userNotifications[userId] ?? [];
  }

  void addNotification(String message,
      {required Order order, required String userId}) {
    final newNotification = NotificationItem(
      id: const Uuid().v4(),
      message: message,
      date: DateTime.now(),
      order: order,
      isRead: false,
    );
    if (_userNotifications.containsKey(userId)) {
      _userNotifications[userId]!.insert(0, newNotification);
    } else {
      _userNotifications[userId] = [newNotification];
    }
    notifyListeners();
  }

  // Add the markAllAsRead method here:
  void markAllAsRead(String userId) {
    if (_userNotifications.containsKey(userId)) {
      for (var notification in _userNotifications[userId]!) {
        notification.isRead = true;
      }
      notifyListeners();
    }
  }

  void markAsRead(String notificationId) {
    _userNotifications.forEach((userId, notifications) {
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index].isRead = true;
        notifyListeners();
        return;
      }
    });
  }

  void clearNotifications(String userId) {
    _userNotifications[userId]?.clear();
    notifyListeners();
  }
}
