import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../models/notification_item.dart';
import '../providers/user_provider.dart';
import '../extensions/localized_context.dart';
import 'order_detail_screen/order_detail_screen.dart';

/// Formats a [date] to a string like "Yesterday at 4:23" if the date was yesterday,
/// or just "16:10" if the date is today.
String formatNotificationDate(DateTime date, BuildContext context) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final notificationDate = DateTime(date.year, date.month, date.day);

  if (notificationDate == today) {
    return DateFormat('HH:mm').format(date);
  } else if (notificationDate == today.subtract(const Duration(days: 1))) {
    return '${context.loc.yesterday} at ${DateFormat('HH:mm').format(date)}';
  } else {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all notifications as read once the screen has built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser =
          Provider.of<UserProvider>(context, listen: false).currentUser;
      if (currentUser != null) {
        Provider.of<NotificationProvider>(context, listen: false)
            .markAllAsRead(currentUser.id.toString());
      }
    });
  }

  // This helper function returns the proper message based on the order status.
  String buildOrderMessage(String status, BuildContext context) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return context.loc.orderConfirmed;
      case 'packed':
        return context.loc.orderPacked;
      case 'shipped':
        return context.loc.orderShipped;
      case 'delivered':
        return context.loc.orderDelivered;
      default:
        return context.loc.orderStatusUpdated;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Compute a scale factor based on a design width of 375.
    final double scale = MediaQuery.of(context).size.width / 375.0;
    final currentUser = Provider.of<UserProvider>(context).currentUser;
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            context.loc.noUserLoggedIn,
            style: TextStyle(fontSize: 14 * scale),
          ),
        ),
      );
    }

    // Get notifications for the current user.
    final List<NotificationItem> notifications =
        Provider.of<NotificationProvider>(context)
            .notificationsForUser(currentUser.id.toString());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          context.loc.notifications,
          style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_active,
                color: Color(0xFF1AB560), size: 64 * scale),
            SizedBox(height: 24 * scale),
            Text(
              context.loc.comingSoon,
              style: TextStyle(
                fontSize: 22 * scale,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1AB560),
                fontFamily: 'Roboto',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          context.loc.notifications,
          style: TextStyle(fontSize: 16 * scale),
        ),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Text(
                context.loc.noNotifications,
                style: TextStyle(fontSize: 14 * scale),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(8.0 * scale),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final NotificationItem notification = notifications[index];
                return Container(
                  margin: EdgeInsets.symmetric(
                      vertical: 8 * scale, horizontal: 4 * scale),
                  width: double.infinity,
                  child: Card(
                    // Change card background to grey if the notification has been read.
                    color:
                        notification.isRead ? Colors.grey[300] : Colors.white,
                    elevation: 3 * scale,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12 * scale),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12.0 * scale),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Icon and message.
                          Row(
                            children: [
                              Icon(Icons.notifications_active,
                                  color: Colors.green, size: 24 * scale),
                              SizedBox(width: 12 * scale),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.loc.orderUpdate,
                                    style: TextStyle(
                                      color: const Color(0xFF939393),
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11 * scale,
                                    ),
                                  ),
                                  SizedBox(height: 2 * scale),
                                  Text(
                                    buildOrderMessage(
                                        notification.message, context),
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'Roboto',
                                      fontSize: 12 * scale,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Right Column: Date on top, "View Order" below.
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatNotificationDate(
                                    notification.date, context),
                                style: TextStyle(
                                  fontSize: 11 * scale,
                                  color: const Color(0xFF939393),
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              SizedBox(height: 2 * scale),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrderDetailScreen(
                                          order: notification.order),
                                    ),
                                  );
                                },
                                child: Text(
                                  context.loc.viewOrder,
                                  style: TextStyle(
                                    fontSize: 12 * scale,
                                    color: notification.isRead
                                        ? Colors.grey
                                        : const Color(0xFF1AB560),
                                    fontFamily: 'Roboto',
                                    decoration: TextDecoration.underline,
                                    decorationColor: notification.isRead
                                        ? Colors.grey
                                        : const Color(0xFF1AB560),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
