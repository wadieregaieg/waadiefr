import 'package:flutter/material.dart';
import 'package:freshk/constants.dart';
import 'package:freshk/extensions/localized_context.dart';
import 'package:freshk/providers/notification_provider.dart';
import 'package:freshk/providers/user_provider.dart';
import 'package:freshk/routes.dart';
import 'package:freshk/utils/navigation_service.dart';
import 'package:provider/provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.selectedIndex,
  });

  final int selectedIndex;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<UserProvider>(context).currentUser;
    final notifications = currentUser != null
        ? Provider.of<NotificationProvider>(context)
            .notificationsForUser(currentUser.id.toString())
        : [];
    final hasNotifications =
        notifications.any((notification) => !notification.isRead);

    late Widget title;
    late Widget subtitle;

    if (selectedIndex == 0) {
      title = Text(
        context.loc.welcomeUser(currentUser?.firstName ?? 'User'),
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      );
      subtitle = Text(
        context.loc.home,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      );
    } else if (selectedIndex == 1) {
      title = Text(
        context.loc.orderHistory,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      );
      subtitle = Text(
        context.loc.history,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      );
    } else if (selectedIndex == 2) {
      title = Text(
        context.loc.shoppingCart,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      );
      subtitle = Text(
        context.loc.cart,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      );
    } else if (selectedIndex == 3) {
      title = Text(
        context.loc.profile,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      );
      subtitle = Text(
        context.loc.profile,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      );
    } else {
      title = Text(
        context.loc.error,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      );
      subtitle = const SizedBox.shrink();
    }

    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Container(
          key: ValueKey(selectedIndex),
          width: 250, // Fixed width to prevent layout shifts
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              title,
              const SizedBox(height: 2),
              subtitle,
            ],
          ),
        ),
      ),
      actions: [
        // User Avatar
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              ((currentUser?.firstName != null &&
                          currentUser!.firstName!.isNotEmpty)
                      ? currentUser.firstName![0]
                      : 'U')
                  .toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        // Notifications
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => _showNotifications(context),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                if (hasNotifications)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showNotifications(BuildContext context) {
    NavigationService.pushNamed(AppRoutes.notifications);
  }
}
