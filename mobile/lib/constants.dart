import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1AB560);
  static const Color primaryLight =
      Color(0xFFE8F5E9); // Added primaryLight color
  static const Color textPrimary = Color(0xFF212A37);
  static const Color error = Colors.red;
  static const Color timelineActive = Color(0xFF4CAF50);
  static const Color timelineInactive = Color(0xFF9E9E9E);
  static const Color textSecondary = Color(0xFF939393);
  static const Color background = Color.fromARGB(255, 255, 255, 255);
}

class AppDimensions {
  static const double padding = 16.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 16.0;
}

class AppContacts {
  static const String whatsappNumber = '+216 26 399 011';
  static const String supportEmail = 'support@freshk.tn';
  static const String mediatorPhone = '71 123 456'; // Médiateur agricole (UTAP)

  // Formatted versions for display
  static const String whatsappDisplay = '+216 26 399 011';
  static const String supportEmailDisplay = 'support@freshk.tn';
  static const String mediatorPhoneDisplay = '71 123 456';

  // URLs for actions
  static String get whatsappUrl => 'https://wa.me/21626399011';
  static String get emailUrl => 'mailto:$supportEmail';
  static String get phoneUrl => 'tel:$mediatorPhone';
}

class AppBusinessRules {
  // Delivery settings
  static const String deliveryStartTime = '06:00';
  static const String deliveryEndTime = '11:00';
  static const List<String> deliveryDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  // Quality and complaints
  static const int qualityComplaintHours = 12;
  static const int qualityBonusThreshold =
      90; // Quality rating > 90/100 gets +5% bonus
  static const double qualityBonusPercent = 5.0;

  // Payment terms
  static const int farmerPaymentHours = 48;
  static const int latePaymentSuspensionDays = 14;
  static const int farmerExitDelayHours = 48;

  // Pricing
  static const double maxPriceIncreasePercent = 15.0;
  static const double logisticIssueDiscountPercent = 20.0;

  // Delivery charge
  static const double deliveryCharge = 0.00;
}

class TextStyles {
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle secondaryText = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  static const TextStyle appBarTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  static const TextStyle drawerHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
}
