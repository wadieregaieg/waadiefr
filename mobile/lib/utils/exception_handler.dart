import 'package:freshk/extensions/localized_context.dart';
import 'package:freshk/utils/freshk_expections.dart';
import 'package:freshk/utils/navigation_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';

class ExceptionHandler {
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  /// Handles common network errors and transforms them into specific exceptions
  static Exception handleNetworkException(dynamic e, BuildContext context) {
    final errorString = e.toString().toLowerCase();

    if (errorString.contains("timeout") ||
        errorString.contains("connection") ||
        errorString.contains("connect")) {
      return NetworkException(context.loc.networkErrorException);
    } else if (errorString.contains("500") || errorString.contains("server")) {
      return ServerException(context.loc.serverError);
    } else if (errorString.contains("401") ||
        errorString.contains("unauthorized")) {
      return AuthenticationException(context.loc.authenticationFailed);
    } else if (errorString.contains("404") ||
        errorString.contains("not found")) {
      return NotFoundException("Resource not found.");
    } else if (errorString.contains("failed host lookup") ||
        errorString.contains("server unreachable")) {
      return NetworkException(context.loc.serverUnreachable);
    } else {
      return e is Exception ? e : UnknownException(e.toString());
    }
  }

  /// Handles authentication-specific errors with comprehensive error mapping
  static Exception handleAuthException(dynamic e, BuildContext context) {
    // Handle DioException with status codes first (most reliable)
    if (e is DioException) {
      return _handleDioException(e, context);
    }

    // Handle string-based errors as fallback
    return _handleStringBasedErrors(e, context);
  }

  /// Handles DioException errors with detailed status code mapping
  static Exception _handleDioException(DioException e, BuildContext context) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    // Extract error message from response data
    String? serverMessage;
    if (responseData is Map<String, dynamic>) {
      serverMessage = _extractServerMessage(responseData, context);
    }

    switch (statusCode) {
      case 400:
        return ValidationException(serverMessage ?? context.loc.badRequest);

      case 401:
        final authMessage = _getAuthenticationMessage(serverMessage, context);
        return AuthenticationException(authMessage);

      case 403:
        return PermissionException(
            serverMessage ?? context.loc.permissionDenied);

      case 404:
        return NotFoundException(serverMessage ?? context.loc.resourceNotFound);

      case 422:
        return ValidationException(
            serverMessage ?? context.loc.validationFailed);

      case 429:
        return ValidationException(
            serverMessage ?? context.loc.tooManyRequests);

      case 500:
        return _handle500Error(serverMessage, context, statusCode);
        
      case 502:
      case 503:
        return _handle502_503Error(serverMessage, context, statusCode);
        
      case 504:
        return _handle504Error(serverMessage, context, statusCode);

      default:
        // Handle DioException types without response
        return _handleDioExceptionType(e, context);
    }
  }

  /// Handles 500 Internal Server Error specifically
  static Exception _handle500Error(String? serverMessage, BuildContext context, int? statusCode) {
    final message = serverMessage ?? context.loc.serverError;
    
    // Check if it's a transient error (can be retried)
    if (_isTransient500Error(serverMessage)) {
      return TransientServerException(
        'Temporary server issue. Please try again.',
        statusCode,
        serverMessage,
      );
    }
    
    // Persistent server error
    return PersistentServerException(
      'Server is currently experiencing issues. Please try again later.',
      statusCode,
      serverMessage,
    );
  }

  /// Handles 502 Bad Gateway and 503 Service Unavailable
  static Exception _handle502_503Error(String? serverMessage, BuildContext context, int? statusCode) {
    final message = serverMessage ?? context.loc.serverError;
    
    // These are typically transient errors
    return TransientServerException(
      'Service temporarily unavailable. Please try again.',
      statusCode,
      serverMessage,
    );
  }

  /// Handles 504 Gateway Timeout
  static Exception _handle504Error(String? serverMessage, BuildContext context, int? statusCode) {
    final message = serverMessage ?? context.loc.serverError;
    
    // Gateway timeout is usually transient
    return TransientServerException(
      'Request timeout. Please try again.',
      statusCode,
      serverMessage,
    );
  }

  /// Determines if a 500 error is transient (can be retried)
  static bool _isTransient500Error(String? serverMessage) {
    if (serverMessage == null) return true;
    
    final lowerMessage = serverMessage.toLowerCase();
    
    // Persistent errors that shouldn't be retried
    final persistentPatterns = [
      'database connection failed',
      'configuration error',
      'internal server error',
      'server configuration',
      'permanent error',
    ];
    
    for (final pattern in persistentPatterns) {
      if (lowerMessage.contains(pattern)) {
        return false;
      }
    }
    
    // Default to transient for 500 errors
    return true;
  }

  /// Handles different types of DioException when no response is available
  static Exception _handleDioExceptionType(
      DioException e, BuildContext context) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException();

      case DioExceptionType.connectionError:
        // Check if this is a server connectivity issue vs network issue
        return _handleConnectionError(e, context);

      case DioExceptionType.badCertificate:
        return NetworkException(context.loc.sslCertificateError);

      case DioExceptionType.cancel:
        return ValidationException(context.loc.requestCancelled);

      case DioExceptionType.unknown:
      default:
        return handleNetworkException(e, context);
    }
  }

  /// Handles connection errors by determining if it's a network or server issue
  static Exception _handleConnectionError(DioException e, BuildContext context) {
    final error = e.error;
    final message = e.message?.toLowerCase() ?? '';
    
    // Check for specific network-related errors
    if (error is SocketException) {
      final socketError = error;
      
      // DNS resolution failures are network issues
      if (socketError.osError?.errorCode == 8 || // EAI_NONAME - Name does not resolve
          socketError.osError?.errorCode == 2 || // ENOENT - No such file or directory
          message.contains('failed host lookup') ||
          message.contains('name or service not known')) {
        return NetworkException(context.loc.networkErrorException);
      }
      
      // Connection refused usually means server is down
      if (socketError.osError?.errorCode == 111 || // ECONNREFUSED
          message.contains('connection refused') ||
          message.contains('connection reset') ||
          message.contains('no route to host')) {
        return TransientServerException(
          'Server is currently unavailable. Please try again.',
          null,
          'Connection refused by server',
        );
      }
      
      // Other socket errors are likely network issues
      return NetworkException(context.loc.networkErrorException);
    }
    
    // Check for HTTP-related connection errors
    if (message.contains('connection refused') ||
        message.contains('connection reset') ||
        message.contains('no route to host') ||
        message.contains('server unreachable')) {
      return TransientServerException(
        'Server is currently unavailable. Please try again.',
        null,
        'Server connection error',
      );
    }
    
    // Default to network error for unknown connection issues
    return NetworkException(context.loc.networkErrorException);
  }

  /// Executes a function with retry logic for transient server errors
  static Future<T> executeWithRetry<T>(
    Future<T> Function() function, {
    Function(Exception)? onError,
    int maxRetries = _maxRetries,
    Duration retryDelay = _retryDelay,
  }) async {
    int retryCount = 0;
    
    while (true) {
      try {
        return await function();
      } catch (e) {
        final context = NavigationService.navigatorKey.currentContext;
        if (context == null) {
          throw Exception("Context is null, cannot handle exception.");
        }
        
        var exception = handleAuthException(e, context);
        
        // Check if this is a retryable server error
        if (exception is TransientServerException && 
            retryCount < maxRetries) {
          retryCount++;
          
          debugPrint("Retry attempt $retryCount/$maxRetries for transient server error");
          
          // Wait before retrying
          await Future.delayed(retryDelay * retryCount);
          
          // Update retry count in exception
          exception = TransientServerException(
            exception.message,
            exception.statusCode,
            exception.serverMessage,
            retryCount,
          );
          
          continue; // Retry the request
        }
        
        debugPrint("Exception caught: $e");
        debugPrint("Exception type: ${exception.runtimeType}");
        
        if (onError != null) {
          onError(exception);
          return Future.value(null);
        }

        throw exception;
      }
    }
  }

  /// Maps API field names to localized field names
  static String _localizeFieldName(String fieldName, BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;

    switch (fieldName.toLowerCase()) {
      case 'username':
        return appLocalizations.fieldUsername;
      case 'email':
        return appLocalizations.fieldEmail;
      case 'password':
        return appLocalizations.fieldPassword;
      case 'first_name':
      case 'firstname':
        return appLocalizations.fieldFirstName;
      case 'last_name':
      case 'lastname':
        return appLocalizations.fieldLastName;
      case 'phone_number':
      case 'phonenumber':
        return appLocalizations.fieldPhoneNumber;
      default:
        return fieldName; // Return original if no mapping found
    }
  }

  /// Maps API error messages to localized strings
  static String _localizeApiErrorMessage(
      String apiMessage, BuildContext context) {
    final locale = context.loc.localeName;

    // Only localize if the current locale is not English
    if (locale.startsWith('en')) {
      return apiMessage;
    }

    // Map common API error messages to localized keys
    final lowerMessage = apiMessage.toLowerCase();

    if (lowerMessage.contains('a user with that username already exists')) {
      return AppLocalizations.of(context)!.userWithUsernameAlreadyExists;
    }

    if (lowerMessage.contains('user with this email already exists')) {
      return AppLocalizations.of(context)!.userWithEmailAlreadyExists;
    }

    if (lowerMessage.contains('this password is too common')) {
      return AppLocalizations.of(context)!.passwordTooCommon;
    }

    if (lowerMessage.contains('this password is too short') &&
        lowerMessage.contains('must contain at least 8 characters')) {
      return AppLocalizations.of(context)!.passwordTooShort;
    }

    if (lowerMessage.contains('this password is entirely numeric')) {
      return AppLocalizations.of(context)!.passwordEntirelyNumeric;
    }

    if (lowerMessage.contains('passwords don\'t match') ||
        lowerMessage.contains('passwords do not match')) {
      return AppLocalizations.of(context)!.passwordsDoNotMatchValidation;
    }

    // Return original message if no mapping found
    return apiMessage;
  }

  /// Extracts meaningful error messages from server response
  static String? _extractServerMessage(Map<String, dynamic> data,
      [BuildContext? context]) {
    // Handle Django REST framework validation errors (field-specific errors)
    if (data.isNotEmpty &&
        !data.containsKey('detail') &&
        !data.containsKey('message') &&
        !data.containsKey('error')) {
      // This looks like a validation error response
      List<String> validationErrors = [];

      data.forEach((field, errors) {
        if (errors is List && errors.isNotEmpty) {
          for (var error in errors) {
            String errorMsg = error.toString();
            if (context != null) {
              errorMsg = _localizeApiErrorMessage(errorMsg, context);
            }

            if (field == 'non_field_errors') {
              validationErrors.add(errorMsg);
            } else {
              String fieldName =
                  context != null ? _localizeFieldName(field, context) : field;
              validationErrors.add('$fieldName: $errorMsg');
            }
          }
        } else if (errors is String && errors.isNotEmpty) {
          String errorMsg = errors;
          if (context != null) {
            errorMsg = _localizeApiErrorMessage(errorMsg, context);
          }

          if (field == 'non_field_errors') {
            validationErrors.add(errorMsg);
          } else {
            String fieldName =
                context != null ? _localizeFieldName(field, context) : field;
            validationErrors.add('$fieldName: $errorMsg');
          }
        }
      });

      if (validationErrors.isNotEmpty) {
        return validationErrors.join('\n');
      }
    }

    // Common server error message fields
    const messageFields = ['detail', 'message', 'error', 'msg', 'description'];

    for (final field in messageFields) {
      if (data.containsKey(field) && data[field] != null) {
        final value = data[field];
        if (value is String && value.isNotEmpty) {
          return value;
        } else if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
      }
    }

    // Handle validation errors (legacy format)
    if (data.containsKey('errors') && data['errors'] is Map) {
      final errors = data['errors'] as Map;
      final firstError = errors.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
    }

    // Fallback to localization-based error mapping
    if (context != null) {
      final apiMessage = data.values.first.toString();
      return _localizeApiErrorMessage(apiMessage, context);
    }

    return null;
  }

  /// Gets appropriate authentication error message
  static String _getAuthenticationMessage(
      String? serverMessage, BuildContext context) {
    if (serverMessage != null) {
      final lowerMessage = serverMessage.toLowerCase();

      if (lowerMessage.contains('otp') || lowerMessage.contains('code')) {
        return context.loc.invalidExpiredVerificationCode;
      } else if (lowerMessage.contains('token') ||
          lowerMessage.contains('jwt')) {
        return context.loc.sessionExpired;
      } else if (lowerMessage.contains('password')) {
        return context.loc.invalidPassword;
      } else if (lowerMessage.contains('email') ||
          lowerMessage.contains('username')) {
        return context.loc.invalidEmailUsername;
      }

      return serverMessage;
    }

    return context.loc.authenticationFailed;
  }

  /// Handles string-based error messages as fallback
  static Exception _handleStringBasedErrors(dynamic e, BuildContext context) {
    final errorString = e.toString().toLowerCase();

    // Authentication-specific patterns
    if (_isOtpError(errorString)) {
      return AuthenticationException(
          context.loc.invalidExpiredVerificationCode);
    }

    if (_isTokenError(errorString)) {
      return AuthenticationException(context.loc.sessionExpired);
    }

    if (_isUserNotFoundError(errorString)) {
      return NotFoundException(context.loc.userNotFound);
    }

    if (_isPermissionError(errorString)) {
      return PermissionException(context.loc.permissionDenied);
    }

    if (_isCredentialsError(errorString)) {
      return ValidationException(context.loc.invalidCredentials);
    }

    if (_isRateLimitError(errorString)) {
      return ValidationException(context.loc.tooManyFailedAttempts);
    }

    // Fallback to network exception handling
    return handleNetworkException(e, context);
  }

  // Helper methods for error pattern matching
  static bool _isOtpError(String error) =>
      error.contains("invalid or expired otp") ||
      error.contains("otp") &&
          (error.contains("invalid") || error.contains("expired"));

  static bool _isTokenError(String error) =>
      error.contains("invalid or expired token") ||
      error.contains("token") &&
          (error.contains("invalid") || error.contains("expired")) ||
      error.contains("jwt") &&
          (error.contains("invalid") || error.contains("expired"));

  static bool _isUserNotFoundError(String error) =>
      error.contains("user not found") ||
      error.contains("no user found") ||
      error.contains("user does not exist");

  static bool _isPermissionError(String error) =>
      error.contains("permission denied") ||
      error.contains("access denied") ||
      error.contains("forbidden");

  static bool _isCredentialsError(String error) =>
      (error.contains("invalid") || error.contains("incorrect")) &&
      (error.contains("credentials") ||
          error.contains("password") ||
          error.contains("email"));

  static bool _isRateLimitError(String error) =>
      error.contains("attempts") ||
      error.contains("429") ||
      error.contains("rate limit") ||
      error.contains("too many");

  /// Handles checkout-specific errors with detailed error mapping
  static Exception handleCheckoutException(dynamic e, BuildContext context) {
    if (e is DioException) {
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;

      if (statusCode == 400 && responseData is Map<String, dynamic>) {
        final errorMessage = _extractServerMessage(responseData, context);

        if (errorMessage != null) {
          final lowerMessage = errorMessage.toLowerCase();

          // Check for specific checkout errors
          if (lowerMessage.contains('empty cart')) {
            return EmptyCartException(errorMessage);
          }

          if (lowerMessage.contains('not enough stock')) {
            return _parseStockError(errorMessage);
          }

          if (lowerMessage.contains('address') &&
              (lowerMessage.contains('not found') ||
                  lowerMessage.contains('not selected'))) {
            return AddressRequiredException(errorMessage);
          }
        }
      }

      if (statusCode == 403 && responseData is Map<String, dynamic>) {
        final errorMessage = _extractServerMessage(responseData, context);
        if (errorMessage != null &&
            errorMessage.toLowerCase().contains('only retailers')) {
          return RetailerOnlyException(errorMessage);
        }
      }
    }

    // Fallback to general error handling
    return handleAuthException(e, context);
  }

  /// Parses stock error message to extract product details
  static Exception _parseStockError(String errorMessage) {
    // Try to extract product name and available stock from error message
    // Format: "Not enough stock for ProductName. Available: X unit"
    final regex = RegExp(r'Not enough stock for (.+?)\. Available: (\d+) (.+)');
    final match = regex.firstMatch(errorMessage);

    if (match != null) {
      final productName = match.group(1) ?? 'Unknown Product';
      final availableStock = int.tryParse(match.group(2) ?? '0') ?? 0;
      final unit = match.group(3) ?? 'units';

      return StockException(
        productName: productName,
        availableStock: availableStock,
        unit: unit,
        message: errorMessage,
      );
    }

    // Fallback to generic stock exception
    return StockException(
      productName: 'Unknown Product',
      availableStock: 0,
      unit: 'units',
      message: errorMessage,
    );
  }

  /// Executes a function with proper error handling
  static Future<T> execute<T>(
    Future<T> Function() function, {
    Function(Exception)? onError,
  }) async {
    try {
      return await function();
    } catch (e) {
      final context = NavigationService.navigatorKey.currentContext;
      if (context == null) {
        throw Exception("Context is null, cannot handle exception.");
      }
      final exception = handleAuthException(e, context);
      debugPrint("Exception caught: $e");
      debugPrint("Exception type: ${exception.runtimeType}");
      if (onError != null) {
        onError(exception);
        return Future.value(null);
      }

      throw exception;
    }
  }
}
