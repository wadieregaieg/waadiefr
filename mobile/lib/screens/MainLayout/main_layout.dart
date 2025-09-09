import 'package:freshk/extensions/localized_context.dart';
import 'package:freshk/providers/products_provider.dart';
import 'package:freshk/screens/MainLayout/cartScreen/cart_screen.dart';
import 'package:freshk/screens/MainLayout/historyScreen/history_screen.dart';
import 'package:freshk/screens/MainLayout/profile/profile_screen.dart';
import 'package:freshk/screens/MainLayout/widgets/bottom_nav.dart';
import 'package:freshk/screens/MainLayout/widgets/custom_app_bar.dart';
import 'package:freshk/services/retailer_profile_service.dart';
import 'package:freshk/utils/freshk_utils.dart';
import 'package:flutter/material.dart';
import 'package:freshk/constants.dart';
import 'package:freshk/providers/user_provider.dart';
import 'package:freshk/routes.dart';
import 'package:freshk/screens/MainLayout/homeScreen/home_content.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:freshk/utils/navigation_service.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  DateTime? _lastBackPressed;

  void _handleNavigation(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Remove fetch logic here, let screens handle their own fetching
  }

  void _showRetailerProfileRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.store,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.loc.retailerProfileRequired,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            context.loc.retailerProfileRequiredMessage,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                NavigationService.popRoute(); // Close dialog
                NavigationService.pushNamedAndRemoveUntil(
                  AppRoutes.retailerProfiles,
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                context.loc.createProfile,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showUserProfileRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.loc.profileRequired,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            context.loc.profileRequiredMessage,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                NavigationService.popRoute(); // Close dialog
                NavigationService.pushNamed(AppRoutes.manageProfile);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                context.loc.completeProfile,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  final listOfScreens = [
    HomeContent(),
    HistoryScreen(),
    CartScreen(),
    ProfileScreen()
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await RetailerProfileService.getRetailerProfiles().then((profiles) {
        if (profiles.isEmpty) {
          _showRetailerProfileRequiredDialog();
        }
      });
      final user = Provider.of<UserProvider>(context, listen: false);
      await user.getUserAddresses();
      if (user.currentUser!.firstName == null ||
          user.currentUser!.lastName == null ||
          user.currentUser!.email == null) {
        _showUserProfileRequiredDialog();
        return;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          final now = DateTime.now();
          if (_lastBackPressed == null ||
              now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
            _lastBackPressed = now;
            FreshkUtils.showInfoSnackbar(
              context,
              context.loc.pressBackAgainToExit,
              duration: const Duration(seconds: 2),
            );
          } else {
            // Exit the app
            SystemNavigator.pop();
          }
        }
      },
      child: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          return Stack(
            children: [
              Scaffold(
                appBar: CustomAppBar(
                  selectedIndex: _selectedIndex,
                ),
                body: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: listOfScreens[_selectedIndex],
                ),
                bottomNavigationBar: BottomNav(
                    selectedIndex: _selectedIndex, onTap: _handleNavigation),
              ),
            ],
          );
        },
      ),
    );
  }
}
