import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class ProductionLogger {
  static const bool _isProduction = bool.fromEnvironment('dart.vm.product');
  
  /// Log debug information (only in debug mode)
  static void debug(String message) {
    if (!_isProduction) {
      debugPrint('🐛 DEBUG: $message');
    }
  }
  
  /// Log info messages (always logged)
  static void info(String message) {
    if (!_isProduction) {
      debugPrint('ℹ️ INFO: $message');
    }
    // In production, you might want to send to analytics
  }
  
  /// Log warnings (always logged)
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isProduction) {
      debugPrint('⚠️ WARNING: $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('Stack: $stackTrace');
    }
    
    // In production, send to crashlytics
    if (_isProduction && error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'Warning: $message',
      );
    }
  }
  
  /// Log errors (always logged and sent to crashlytics in production)
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isProduction) {
      debugPrint('❌ ERROR: $message');
      if (error != null) debugPrint('Error details: $error');
      if (stackTrace != null) debugPrint('Stack trace: $stackTrace');
    }
    
    // Always send to crashlytics in production
    if (_isProduction) {
      FirebaseCrashlytics.instance.recordError(
        error ?? Exception(message),
        stackTrace,
        reason: message,
      );
    }
  }
  
  /// Log network errors specifically
  static void networkError(String endpoint, dynamic error, [StackTrace? stackTrace]) {
    final message = 'Network error for $endpoint';
    error(message, error, stackTrace);
  }
  
  /// Log authentication errors
  static void authError(String operation, dynamic error, [StackTrace? stackTrace]) {
    final message = 'Authentication error during $operation';
    error(message, error, stackTrace);
  }
  
  /// Log user actions for analytics
  static void userAction(String action, {Map<String, dynamic>? parameters}) {
    if (!_isProduction) {
      debugPrint('👤 USER ACTION: $action');
      if (parameters != null) {
        debugPrint('Parameters: $parameters');
      }
    }
    // In production, send to analytics service
  }
  
  /// Check if we're in production mode
  static bool get isProduction => _isProduction;
  
  /// Check if we're in debug mode
  static bool get isDebugMode => !_isProduction;
} 