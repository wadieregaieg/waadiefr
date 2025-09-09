import 'package:freshk/constants.dart';
import 'package:flutter/material.dart';

class AppThemeData {
  static ThemeData themeData = ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.primary.withOpacity(0.4),
      selectionHandleColor: AppColors.primary,
    ),
  );
}
