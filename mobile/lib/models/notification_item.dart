import 'order.dart';

class NotificationItem {
  final String id;
  final String message;
  final DateTime date;
  final Order order;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.message,
    required this.date,
    required this.order,
    this.isRead = false,
  });
}
