import 'dart:ui';

import 'package:freshk/constants.dart';
import 'package:freshk/firebase_options.dart';
import 'package:freshk/l10n/l10n.dart';
import 'package:freshk/models/apiResponses/checkout_response.dart';
import 'package:freshk/models/order.dart';
import 'package:freshk/models/product.dart';
import 'package:freshk/providers/cart_provider.dart';
import 'package:freshk/providers/language_provider.dart';
import 'package:freshk/providers/network_proivder.dart';
import 'package:freshk/providers/notification_provider.dart';
import 'package:freshk/providers/order_provider.dart';
import 'package:freshk/providers/products_provider.dart';
import 'package:freshk/providers/user_provider.dart';
import 'package:freshk/routes.dart';
import 'package:freshk/screens/add_new_address_screen.dart';
import 'package:freshk/screens/address_screen.dart';
import 'package:freshk/screens/forgot_password_screen.dart';
import 'package:freshk/screens/login_screen/login_screen.dart';
import 'package:freshk/screens/MainLayout/main_layout.dart';
import 'package:freshk/screens/no_network_screen.dart';
import 'package:freshk/screens/notifications_screen.dart';
import 'package:freshk/screens/order_summary_screen.dart';
import 'package:freshk/screens/otp_verification_screen.dart';
import 'package:freshk/screens/password_reset_success_screen.dart';
import 'package:freshk/screens/paymentScreen/payment_screen.dart';
import 'package:freshk/screens/payment_success_screen.dart';
import 'package:freshk/screens/productDetailScreen/product_detail_screen.dart';
import 'package:freshk/screens/reset_otp_screen.dart';
import 'package:freshk/screens/reset_password_screen.dart';
import 'package:freshk/screens/retailer_profile/create_edit_retailer_profile_screen.dart';
import 'package:freshk/screens/setting/change_password_screen.dart';
import 'package:freshk/screens/setting/language_selection_screen.dart';
import 'package:freshk/screens/setting/manage_profile_screen.dart';
import 'package:freshk/screens/setting/notification_settings_screen.dart';
import 'package:freshk/screens/setting/support_center_screen.dart';
import 'package:freshk/screens/setting/terms_conditions_screen.dart';
import 'package:freshk/screens/setting/theme_selection_screen.dart';
import 'package:freshk/screens/settings_screen.dart';
import 'package:freshk/screens/signup_screen/signup_screen.dart';
import 'package:freshk/screens/splash_screen.dart';
import 'package:freshk/screens/success_screen.dart';
import 'package:freshk/screens/order_detail_screen/order_detail_screen.dart';
import 'package:freshk/utils/app_theme.dart';
import 'package:freshk/utils/navigation_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => NetworkProvider()),
      ],
      child: DevicePreview(
        enabled: false,
        builder: (context) => const MyApp(), // Wrap your app
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<NetworkProvider, LanguageProvider>(
      builder:
          (BuildContext context, network, languageProvider, Widget? child) =>
              ScreenUtilInit(
        designSize: const Size(360, 640),
        minTextAdapt: true,
        builder: (context, child) {
          return MaterialApp(
              navigatorKey: NavigationService.navigatorKey,
              title: 'Freshk App',
              debugShowCheckedModeBanner: false,
              color: AppColors.primary,
              theme: AppThemeData.themeData,
              initialRoute: AppRoutes.splash,
              supportedLocales: L10n.all,
              locale: languageProvider.locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) {
                if (child == null) {
                  return CircularProgressIndicator(
                    color: AppColors.primary,
                  );
                }
                return DevicePreview.appBuilder(
                    context, child);
              },
              onUnknownRoute: (settings) {
                // Handle unknown routes to prevent black screens
                return MaterialPageRoute(
                  builder: (context) => const SplashScreen(),
                  settings: settings,
                );
              },
              routes: {
                AppRoutes.main: (context) {
                  final initialIndex =
                      ModalRoute.of(context)!.settings.arguments as int? ?? 0;
                  return MainLayout(initialIndex: initialIndex);
                },
                AppRoutes.noNetwork: (context) => const NoNetworkScreen(),
                AppRoutes.splash: (context) => const SplashScreen(),
                AppRoutes.notifications: (context) =>
                    const NotificationsScreen(),
                AppRoutes.login: (context) => const LoginScreen(),
                AppRoutes.signup: (context) => const SignUpScreen(),
                AppRoutes.otp: (context) => const OTPVerificationScreen(),
                AppRoutes.success: (context) => const SuccessScreen(),
                AppRoutes.forgotPassword: (context) =>
                    const ForgotPasswordScreen(),
                AppRoutes.resetOtp: (context) => const ResetOtpScreen(),
                AppRoutes.resetPassword: (context) =>
                    const ResetPasswordScreen(),
                AppRoutes.passwordResetSuccess: (context) =>
                    const PasswordResetSuccessScreen(),
                AppRoutes.productDetail: (context) {
                  final product =
                      ModalRoute.of(context)!.settings.arguments as Product;
                  return ProductDetailScreen(product: product);
                },
                AppRoutes.orderSummary: (context) => const OrderSummaryScreen(),
                AppRoutes.payment: (context) => const PaymentScreen(),
                AppRoutes.paymentSuccess: (context) {
                  final order = ModalRoute.of(context)!.settings.arguments
                      as CheckoutResponse;
                  return PaymentSuccessScreen(order: order);
                },
                AppRoutes.addressScreen: (context) => const AddressScreen(),
                AppRoutes.addNewAddress: (context) =>
                    const AddNewAddressScreen(),
                AppRoutes.settings: (context) => const SettingsScreen(),
                AppRoutes.changePassword: (context) =>
                    const ChangePasswordScreen(),
                AppRoutes.manageProfile: (context) =>
                    const ManageProfileScreen(),
                AppRoutes.languageSelection: (context) =>
                    const LanguageSelectionScreen(),
                AppRoutes.themeSelection: (context) =>
                    const ThemeSelectionScreen(),
                AppRoutes.notificationSettings: (context) =>
                    const NotificationSettingsScreen(),
                AppRoutes.supportCenter: (context) =>
                    const SupportCenterScreen(),
                AppRoutes.termsConditions: (context) =>
                    const TermsConditionsScreen(),
                AppRoutes.orderDetails: (context) {
                  final order =
                      ModalRoute.of(context)!.settings.arguments as Order;
                  return OrderDetailScreen(order: order);
                }, // Retailer profile routes
                AppRoutes.retailerProfiles: (context) =>
                    const CreateEditRetailerProfileScreen(),
                AppRoutes.trackOrder: (context) {
                  final order =
                      ModalRoute.of(context)!.settings.arguments as Order;
                  return OrderDetailScreen(order: order);
                },
              });
        },
      ),
    );
  }
}
