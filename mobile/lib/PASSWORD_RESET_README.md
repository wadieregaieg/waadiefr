# Password Reset Implementation

This document describes the complete password reset functionality implemented for the Freshk mobile application.

## Overview

The password reset feature supports two methods:
1. **Phone Number + OTP**: Users receive an OTP via SMS and complete the reset in-app
2. **Email + Link**: Users receive a reset link via email (external flow)

## API Endpoints

### Request Password Reset
- **Endpoint**: `POST /api/users/users/password_reset_request/`
- **Permission**: AllowAny
- **Content-Type**: application/json

**Request Body (Phone):**
```json
{
  "phone_number": "+1234567890"
}
```

**Request Body (Email):**
```json
{
  "email": "user@example.com"
}
```

**Response:**
```json
{
  "message": "If an account exists, a reset link/OTP has been sent"
}
```

### Confirm Password Reset
- **Endpoint**: `POST /api/users/users/password_reset_confirm/`
- **Permission**: AllowAny
- **Content-Type**: application/json

**Request Body:**
```json
{
  "token": "123456",
  "password": "newpassword123"
}
```

**Response:**
```json
{
  "message": "Password reset successful"
}
```

## Service Layer

### UserService Methods

```dart
// Request password reset via email or phone
static Future<String> requestPasswordReset({
  String? email,
  String? phoneNumber,
}) async

// Confirm password reset with token and new password
static Future<String> confirmPasswordReset(
  String token,
  String newPassword,
) async
```

**Features:**
- Uses centralized `ExceptionHandler` for error handling
- Validates input parameters (either email or phone required)
- Returns success messages from API responses

## Provider Layer

### UserProvider Methods

```dart
// Request password reset via email or phone number
Future<String> requestPasswordReset({
  String? email,
  String? phoneNumber,
}) async

// Confirm password reset with token and new password
Future<String> confirmPasswordReset(
  String token,
  String newPassword,
) async
```

**Features:**
- Wraps service calls with additional error handling
- Provides debug logging
- Re-throws exceptions for UI layer handling

## UI Components

### 1. ForgotPasswordPhoneScreen
- **File**: `lib/screens/forgot_password_phone_screen.dart`
- **Purpose**: Phone number input for password reset
- **Features**:
  - Phone number validation (8-digit format)
  - Loading state during API call
  - Success/error messaging via SnackBar
  - Navigation to OTP verification screen

### 2. ResetOtpScreen
- **File**: `lib/screens/reset_otp_screen.dart`
- **Purpose**: OTP verification for phone-based reset
- **Features**:
  - 6-digit OTP input fields
  - Auto-focus and auto-advance
  - Resend timer (30 seconds)
  - Navigation to password reset screen with token

### 3. ResetPasswordScreen
- **File**: `lib/screens/reset_password_screen.dart`
- **Purpose**: New password input and confirmation
- **Features**:
  - Password validation (minimum 6 characters)
  - Password confirmation matching
  - Show/hide password toggles
  - Loading state during API call
  - Integration with UserProvider for API calls

### 4. EmailPasswordResetScreen
- **File**: `lib/screens/email_password_reset_screen.dart`
- **Purpose**: Email-based password reset request
- **Features**:
  - Email validation
  - Loading state during API call
  - Success dialog with instructions
  - Error handling via SnackBar

### 5. PasswordResetExampleScreen
- **File**: `lib/screens/password_reset_example_screen.dart`
- **Purpose**: Demonstration and usage examples
- **Features**:
  - UI for choosing reset method
  - Code examples in dialog
  - Navigation to functional screens

## Usage Examples

### Basic Usage with Provider

```dart
import 'package:provider/provider.dart';
import 'package:freshk/providers/user_provider.dart';

// Request reset via phone
try {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final message = await userProvider.requestPasswordReset(
    phoneNumber: "+1234567890",
  );
  // Show success message
} catch (e) {
  // Handle error
}

// Request reset via email
try {
  final message = await userProvider.requestPasswordReset(
    email: "user@example.com",
  );
  // Show success message
} catch (e) {
  // Handle error
}

// Confirm password reset
try {
  final message = await userProvider.confirmPasswordReset(
    "123456", // OTP token
    "newPassword123", // New password
  );
  // Navigate to success screen
} catch (e) {
  // Handle error
}
```

### Direct Service Usage

```dart
import 'package:freshk/services/user_service.dart';

// Request reset
final message = await UserService.requestPasswordReset(
  email: "user@example.com",
);

// Confirm reset
final confirmMessage = await UserService.confirmPasswordReset(
  "123456",
  "newPassword123",
);
```

## User Flows

### Phone-Based Reset Flow
1. User enters phone number in `ForgotPasswordPhoneScreen`
2. App calls `requestPasswordReset()` with phone number
3. User receives OTP via SMS
4. User enters OTP in `ResetOtpScreen`
5. App navigates to `ResetPasswordScreen` with OTP token
6. User enters new password
7. App calls `confirmPasswordReset()` with token and password
8. Success screen is displayed

### Email-Based Reset Flow
1. User enters email in `EmailPasswordResetScreen`
2. App calls `requestPasswordReset()` with email
3. User receives reset link via email
4. User clicks link (external to app)
5. User completes reset on web interface

## Error Handling

All methods use the centralized `ExceptionHandler` which provides:
- Network error handling
- Authentication error handling
- Server error handling
- Custom exception types

UI components display errors via:
- SnackBar messages for temporary feedback
- Form validation for input errors
- Loading states to prevent multiple submissions

## Security Considerations

1. **Token Validation**: OTP tokens are validated server-side
2. **Rate Limiting**: API endpoints should implement rate limiting
3. **Token Expiry**: OTP tokens should have short expiration times
4. **Input Validation**: All inputs are validated client and server-side
5. **Secure Storage**: No sensitive data is stored locally

## Testing

To test the implementation:

1. Navigate to the example screen:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const PasswordResetExampleScreen(),
  ),
);
```

2. Use the phone-based flow with test numbers
3. Use the email-based flow with test emails
4. Verify error handling with invalid inputs

## Dependencies

Required packages:
- `provider` - State management
- `flutter/material.dart` - UI components
- `flutter/services.dart` - Input formatting

The implementation integrates with existing:
- `DioInstance` - HTTP client
- `ExceptionHandler` - Error handling
- `FreshkUtils` - Utility functions

## Future Enhancements

Potential improvements:
1. Biometric authentication integration
2. Password strength indicators
3. Password history validation
4. Multi-factor authentication
5. Social login password reset options
