import 'dart:convert';
import 'dart:io' show Platform;

import 'package:freshk/models/tokens.dart';
import 'package:freshk/models/user.dart';
import 'package:freshk/utils/freshk_expections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FreshkUtils {
  static FlutterSecureStorage _getStorage() {
    if (Platform.isAndroid) {
      return FlutterSecureStorage(
          aOptions: const AndroidOptions(encryptedSharedPreferences: true));
    } else {
      return const FlutterSecureStorage();
    }
  }

  static Future<void> saveAuthTokens(
      String accessToken, String refreshToken) async {
    final storage = _getStorage();

    try {
      await storage.write(key: "acces", value: accessToken);
      await storage.write(key: "refresh", value: refreshToken);
    } catch (e) {
      debugPrint("Error saving auth tokens: $e");
      throw StorageException("Failed to save authentication tokens securely.");
    }
  }

  static Future<void> deleteAuthTokens() async {
    final storage = _getStorage();

    try {
      await storage.delete(key: "acces");
      await storage.delete(key: "refresh");
    } catch (e) {
      debugPrint("Error deleting auth tokens: $e");
      // We don't throw here since this is typically called during cleanup
      // and we don't want to prevent other cleanup operations
    }
  }

  static Future<Tokens?> getTokensFromStorage() async {
    final storage = _getStorage();

    try {
      final futures = [
        storage.read(key: "acces").catchError((e) {
          debugPrint("Error reading access token: $e");
          return null;
        }),
        storage.read(key: "refresh").catchError((e) {
          debugPrint("Error reading refresh token: $e");
          return null;
        })
      ];

      final results = await Future.wait(futures);
      if (results[0] != null && results[1] != null) {
        return Tokens(
          access: results[0]!,
          refresh: results[1]!,
        );
      } else {
        debugPrint(
            "One or more tokens missing: access=${results[0] != null}, refresh=${results[1] != null}");
        return null;
      }
    } catch (e) {
      debugPrint("Error retrieving tokens: $e");
      throw StorageException("Failed to retrieve authentication tokens.");
    }
  }

  static Future<void> saveUserData(User user) async {
    final storage = _getStorage();

    try {
      await storage.write(key: "user", value: jsonEncode(user.toMap()));
    } catch (e) {
      debugPrint("Error saving user data: $e");
      throw StorageException("Failed to save user data securely.");
    }
  }

  static Future<User?> getSavedUserData() async {
    final storage = _getStorage();

    try {
      final userJson = await storage.read(key: "user");
      if (userJson != null) {
        try {
          return User.fromJson(jsonDecode(userJson));
        } catch (parseError) {
          debugPrint("Error parsing user data: $parseError");
          // Data corruption case - clean up and start fresh
          await deleteUserData();
          throw StorageException("User data corrupted. Please login again.");
        }
      } else {
        return null;
      }
    } catch (e) {
      if (e is StorageException) {
        rethrow; // Already handled and wrapped
      }
      debugPrint("Error retrieving user data: $e");
      throw StorageException("Failed to retrieve user data.");
    }
  }

  static Future<void> deleteUserData() async {
    final storage = _getStorage();

    try {
      await storage.delete(key: "user");
    } catch (e) {
      debugPrint("Error deleting user data: $e");
      // We don't throw here since this is typically called during cleanup
    }
  }

  static Future<bool> isUserLoggedIn() async {
    final storage = _getStorage();

    try {
      final futures = [
        storage.read(key: "acces"),
        storage.read(key: "refresh"),
        storage.read(key: "user")
      ];

      final results = await Future.wait(futures);
      final accessToken = results[0];
      final refreshToken = results[1];
      final user = results[2];

      return accessToken != null && refreshToken != null && user != null;
    } catch (e) {
      debugPrint("Error checking login status: $e");
      // If we can't read the storage, consider the user not logged in
      return false;
    }
  }

  static void showErrorSnackbar(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 4)}) {
    // Localize the error message
    String localizedMessage = localizeErrorMessage(context, message);
    IconData icon = Icons.error_outline;
    Color backgroundColor = Colors.red;

    // Enhanced server error handling
    if (message.toLowerCase().contains('server') ||
        message.toLowerCase().contains('500') ||
        message.toLowerCase().contains('502') ||
        message.toLowerCase().contains('503') ||
        message.toLowerCase().contains('504')) {
      if (message.toLowerCase().contains('temporary') ||
          message.toLowerCase().contains('transient') ||
          message.toLowerCase().contains('timeout')) {
        // Transient server error - show retry option
        localizedMessage = AppLocalizations.of(context)?.serverTemporaryError ??
            'Temporary server issue. Please try again.';
        icon = Icons.refresh;
        backgroundColor = Colors.orange;
      } else if (message.toLowerCase().contains('unavailable') ||
          message.toLowerCase().contains('down')) {
        // Persistent server error
        localizedMessage = AppLocalizations.of(context)?.serverDownMessage ??
            'Server is currently unavailable. Please try again later.';
        icon = Icons.cloud_off;
        backgroundColor = Colors.grey.shade800;
      } else {
        // Generic server error
        localizedMessage = AppLocalizations.of(context)?.serverError ??
            'Server error occurred. Please try again later.';
        icon = Icons.cloud_off;
        backgroundColor = Colors.grey.shade800;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  localizedMessage,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        duration: duration,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: _shouldShowRetryAction(message)
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () {
                  // This will be handled by the calling code
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              )
            : null,
        onVisible: () {
          // Optional: Add any logic when snackbar becomes visible
        },
      ),
    );
  }

  /// Determines if a retry action should be shown for the error
  static bool _shouldShowRetryAction(String message) {
    final lowerMessage = message.toLowerCase();
    return lowerMessage.contains('temporary') ||
        lowerMessage.contains('transient') ||
        lowerMessage.contains('timeout') ||
        lowerMessage.contains('retry');
  }

  /// Shows a server error dialog with retry option
  static void showServerErrorDialog(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    final isTransient = message.toLowerCase().contains('temporary') ||
        message.toLowerCase().contains('transient') ||
        message.toLowerCase().contains('timeout');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isTransient
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isTransient ? Icons.refresh : Icons.cloud_off,
                color: isTransient ? Colors.orange : Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isTransient
                  ? AppLocalizations.of(context)?.temporaryServerIssue ??
                      'Temporary Server Issue'
                  : AppLocalizations.of(context)?.serverUnavailable ??
                      'Server Unavailable',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            if (isTransient) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)?.retrySuggestion ??
                            'This is a temporary issue. You can try again.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (onDismiss != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDismiss();
              },
              child: Text(AppLocalizations.of(context)?.dismiss ?? 'Dismiss'),
            ),
          if (isTransient && onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
            ),
        ],
      ),
    );
  }

  /// Shows a network error dialog with connectivity check
  static void showNetworkErrorDialog(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.wifi_off,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)?.networkError ?? 'Network Error',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)?.checkConnectionSuggestion ??
                          'Please check your internet connection and try again.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)?.ok ?? 'OK'),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
            ),
        ],
      ),
    );
  }

  static void showSuccessSnackbar(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    // Localize the success message
    final localizedMessage = localizeSuccessMessage(context, message);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          child: Text(
            localizedMessage,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        duration: duration,
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showInfoSnackbar(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 3)}) {
    final localizedMessage = message;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          child: Text(
            localizedMessage,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        duration: duration,
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showValidationErrorDialog(BuildContext context, String message) {
    // Localize the message
    final localizedMessage = localizeErrorMessage(context, message);

    // Check if the message contains multiple validation errors (newlines)
    if (localizedMessage.contains('\n')) {
      final errors = localizedMessage
          .split('\n')
          .where((e) => e.trim().isNotEmpty)
          .toList();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.validationErrors),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errors
                .map((error) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(error.trim())),
                        ],
                      ),
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.ok),
            ),
          ],
        ),
      );
    } else {
      // Single error - use snackbar
      showErrorSnackbar(context, localizedMessage);
    }
  }

  /// Localizes error messages that might come from the API
  static String localizeErrorMessage(BuildContext context, String message) {
    final appLocalizations = AppLocalizations.of(context)!;
    final lowerMessage = message.toLowerCase();

    // Handle common API error patterns
    if (lowerMessage.contains('a user with that username already exists')) {
      return appLocalizations.userWithUsernameAlreadyExists;
    }

    if (lowerMessage.contains('user with this email already exists')) {
      return appLocalizations.userWithEmailAlreadyExists;
    }

    if (lowerMessage.contains('this password is too common')) {
      return appLocalizations.passwordTooCommon;
    }

    if (lowerMessage.contains('this password is too short') &&
        lowerMessage.contains('must contain at least 8 characters')) {
      return appLocalizations.passwordTooShort;
    }

    if (lowerMessage.contains('this password is entirely numeric')) {
      return appLocalizations.passwordEntirelyNumeric;
    }

    if (lowerMessage.contains('passwords don\'t match') ||
        lowerMessage.contains('passwords do not match')) {
      return appLocalizations.passwordsDoNotMatchValidation;
    }

    // Handle field-specific errors by localizing field names
    if (message.contains(':')) {
      final parts = message.split(':');
      if (parts.length >= 2) {
        final fieldName = parts[0].trim();
        final errorText = parts.sublist(1).join(':').trim();

        // Localize field name
        String localizedFieldName = fieldName;
        switch (fieldName.toLowerCase()) {
          case 'username':
            localizedFieldName = appLocalizations.fieldUsername;
            break;
          case 'email':
            localizedFieldName = appLocalizations.fieldEmail;
            break;
          case 'password':
            localizedFieldName = appLocalizations.fieldPassword;
            break;
          case 'first_name':
          case 'firstname':
            localizedFieldName = appLocalizations.fieldFirstName;
            break;
          case 'last_name':
          case 'lastname':
            localizedFieldName = appLocalizations.fieldLastName;
            break;
          case 'phone_number':
          case 'phonenumber':
            localizedFieldName = appLocalizations.fieldPhoneNumber;
            break;
        }

        // Recursively localize the error text part
        String localizedErrorText = localizeErrorMessage(context, errorText);
        return '$localizedFieldName: $localizedErrorText';
      }
    }

    // Return original message if no localization found
    return message;
  }

  /// Localizes success messages that might come from the API
  static String localizeSuccessMessage(BuildContext context, String message) {
    final appLocalizations = AppLocalizations.of(context)!;
    final lowerMessage = message.toLowerCase();

    // Handle common API success patterns
    if (lowerMessage.contains('user account created successfully') ||
        lowerMessage.contains('account created successfully') ||
        lowerMessage.contains('registration successful') ||
        lowerMessage.contains('user created successfully')) {
      return appLocalizations.accountCreatedSuccessfully;
    }

    if (lowerMessage.contains('password changed successfully') ||
        lowerMessage.contains('password updated successfully')) {
      return appLocalizations.passwordChangedSuccessfully;
    }

    if (lowerMessage.contains('profile updated successfully') ||
        lowerMessage.contains('profile saved successfully')) {
      return appLocalizations.profileUpdatedSuccessfully;
    }

    // Return original message if no localization found
    return message;
  }

  static String getFallbackImage(String productName) {
    // Example base64 default image (replace with your actual default base64 string)
    const defaultBase64 =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA...'; // TODO: Replace with real default
    // You can add logic to return different base64 images for different products if needed
    return defaultBase64;
  }

  /// Persists a flag that the cart swipe hint has been shown (for onboarding UX)
  static Future<void> setCartSwipeHintShown() async {
    final storage = _getStorage();
    try {
      await storage.write(key: "cart_swipe_hint_shown", value: "true");
    } catch (e) {
      debugPrint("Error saving cart swipe hint flag: $e");
    }
  }

  /// Returns true if the cart swipe hint has already been shown (persistent)
  static Future<bool> isCartSwipeHintShown() async {
    final storage = _getStorage();
    try {
      final value = await storage.read(key: "cart_swipe_hint_shown");
      return value == "true";
    } catch (e) {
      debugPrint("Error reading cart swipe hint flag: $e");
      return false;
    }
  }
}
