import 'package:flutter/foundation.dart';

class ProductionConfig {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  
  // Debug logging - only log in debug mode
  static void log(String message) {
    if (!isProduction) {
      debugPrint(message);
    }
  }
  
  // Error logging - always log errors in production
  static void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!isProduction) {
      debugPrint('ERROR: $message');
      if (error != null) debugPrint('Error details: $error');
      if (stackTrace != null) debugPrint('Stack trace: $stackTrace');
    }
    // In production, you might want to send this to a logging service
    // like Firebase Crashlytics
  }
  
  // Check if we're in production mode
  static bool get isDebugMode => !isProduction;
  
  // Production-specific settings
  static const int maxRetryAttempts = 3;
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration cacheTimeout = Duration(hours: 1);
} 