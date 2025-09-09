import 'package:freshk/models/apiResponses/otp_verify_response.dart';
import 'package:freshk/models/user.dart';
import 'package:freshk/utils/dio_instance.dart';
import 'package:freshk/utils/freshk_expections.dart';
import 'package:freshk/utils/exception_handler.dart';
import 'package:flutter/foundation.dart';

class UserService {
  // This class will handle user-related operations
  // such as authentication, user data retrieval, etc.
  // Original custom exception handler has been replaced by the centralized ExceptionHandler
  /// Authenticate user via email and password
  static Future<OtpVerifyResponse> authenticateViaEmail(
    String email,
    String password,
  ) async {
    return ExceptionHandler.executeWithRetry<OtpVerifyResponse>(
      () async {
        final res = await DioInstance.dio.post(
          "/api/token/",
          data: {
            "username": email,
            "password": password,
          },
        );
        final data = res.data as Map<String, dynamic>;
        if (data.isEmpty) {
          throw UnknownException("Response data is empty.");
        }
        try {
          // Transform the token response to match OtpVerifyResponse format
          // Since the email login returns just tokens, we need to get user data separately
          final accessToken = data["access"] as String;
          final refreshToken = data["refresh"] as String;

          // Set authorization header to get user data
          DioInstance.setDioAuthorizationHeader(accessToken);

          // Get user data
          final userRes = await DioInstance.dio.get("/api/users/profile/");
          final userData = userRes.data as Map<String, dynamic>;

          // Create response in OtpVerifyResponse format
          final responseData = {
            "access": accessToken,
            "refresh": refreshToken,
            "user": userData,
          };

          return OtpVerifyResponse.fromJson(responseData);
        } catch (e) {
          throw UnknownException(
              "Failed to parse response data or get user info.");
        }
      },
    );
  }

  static Future<bool> authenticateViaPhone(
    String phone,
  ) async {
    return ExceptionHandler.execute<bool>(
      () async {
        final res = await DioInstance.dio
            .post("/api/mobile/auth/request/", data: {"phone_number": phone});
        final data = res.data as Map<String, dynamic>;
        return data["is_new_user"] as bool;
      },
    );
  }

  static Future<OtpVerifyResponse> verifyOtp(
    String phoneNumber,
    String otp,
  ) async {
    print("Phone being verified is: $phoneNumber");

    return ExceptionHandler.execute<OtpVerifyResponse>(
      () async {
        final res =
            await DioInstance.dio.post("/api/mobile/auth/verify/", data: {
          "phone_number": phoneNumber,
          "otp": otp,
        });
        final data = res.data as Map<String, dynamic>;
        if (data.isEmpty) {
          throw UnknownException("Response data is empty.");
        }
        try {
          return OtpVerifyResponse.fromJson(data);
        } catch (e) {
          throw UnknownException("Failed to parse response data.");
        }
      },
    );
  }

  static Future<String> refreshAccesToken(
    String refreshToken,
  ) async {
    return ExceptionHandler.execute<String>(
      () async {
        final accesTokenRes = await DioInstance.dio.post(
          "/api/token/refresh/",
          data: {
            "refresh": refreshToken,
          },
        );
        return accesTokenRes.data["access"] as String;
      },
    );
  }

  static Future<User> getUserData() async {
    return ExceptionHandler.execute<User>(
      () async {
        final res = await DioInstance.dio.get("/api/users/profile/");
        final data = res.data;
        return User.fromJson(data);
      },
    );
  }

  static Future<void> updateUserAdress() async {
    return ExceptionHandler.execute<void>(
      () async {
        final res = await DioInstance.dio.post("/api/users/profile/");
        if (res.statusCode != 200) {
          throw UnknownException("Failed to update user address.");
        }
      },
    );
  }

  /// Update user profile with full update functionality
  static Future<User> updateUserProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? profilePicture,
  }) async {
    return ExceptionHandler.execute<User>(
      () async {
        Map<String, dynamic> data = {};

        if (firstName != null) {
          data["first_name"] = firstName;
        }
        if (lastName != null) {
          data["last_name"] = lastName;
        }
        if (email != null) {
          data["email"] = email;
        }
        if (phoneNumber != null) {
          data["phone_number"] = phoneNumber;
        }
        if (profilePicture != null) {
          data["profile_picture"] = profilePicture;
        }

        print(data.toString());
        final res = await DioInstance.dio.patch(
          "/api/users/profile/",
          data: data,
        );

        final responseData = res.data as Map<String, dynamic>;
        return User.fromJson(responseData);
      },
    );
  }

  /// Authenticate user via username/email and password with JWT tokens
  static Future<OtpVerifyResponse> authenticateWithJWT(
    String username,
    String password,
  ) async {
    return ExceptionHandler.executeWithRetry<OtpVerifyResponse>(
      () async {
        final res = await DioInstance.dio.post(
          "/api/token/",
          data: {
            "username": username,
            "password": password,
          },
        );
        final data = res.data as Map<String, dynamic>;
        if (data.isEmpty) {
          throw UnknownException("Response data is empty.");
        }
        try {
          // The new JWT endpoint returns access, refresh, username, and role
          final accessToken = data["access"] as String;
          final refreshToken = data["refresh"] as String;

          // Set authorization header to get user data
          DioInstance.setDioAuthorizationHeader(accessToken);

          // Get user data
          final userRes = await DioInstance.dio.get("/api/users/profile/");
          final userData = userRes.data as Map<String, dynamic>;

          // Create response in OtpVerifyResponse format
          final responseData = {
            "access": accessToken,
            "refresh": refreshToken,
            "user": userData,
          };

          return OtpVerifyResponse.fromJson(responseData);
        } catch (e) {
          throw UnknownException(
              "Failed to parse response data or get user info.");
        }
      },
      onError: (exception) {
        debugPrint("Authentication failed: $exception");
        // Re-throw the exception so the UI can handle it appropriately
        throw exception;
      },
    );
  }

  /// Register a new user account
  static Future<String> registerUser({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    String? firstName,
    String? lastName,
    String? role,
    String? phoneNumber,
    Map<String, dynamic>? preferences,
  }) async {
    return ExceptionHandler.execute<String>(
      () async {
        Map<String, dynamic> data = {
          "username": username,
          "email": email,
          "password": password,
          "confirm_password": confirmPassword,
        };

        if (firstName != null) {
          data["first_name"] = firstName;
        }
        if (lastName != null) {
          data["last_name"] = lastName;
        }
        if (role != null) {
          data["role"] = role;
        }
        if (phoneNumber != null) {
          data["phone_number"] = phoneNumber;
        }
        if (preferences != null) {
          data["preferences"] = preferences;
        }

        final res = await DioInstance.dio.post(
          "/api/users/",
          data: data,
        );

        final responseData = res.data as Map<String, dynamic>;
        return responseData["message"] as String;
      },
    );
  }

  /// Request password reset via email or phone number (updated for new API)
  static Future<String> requestPasswordResetNew({
    String? email,
    String? phoneNumber,
  }) async {
    return ExceptionHandler.execute<String>(
      () async {
        if (email == null && phoneNumber == null) {
          throw ArgumentError("Either email or phone number must be provided");
        }

        Map<String, dynamic> data = {};
        if (email != null) {
          data["email"] = email;
        }
        if (phoneNumber != null) {
          data["phone_number"] = phoneNumber;
        }

        final res = await DioInstance.dio.post(
          "/api/password-reset-request/",
          data: data,
        );

        final responseData = res.data as Map<String, dynamic>;
        return responseData["message"] as String;
      },
    );
  }

  /// Confirm password reset with token and new password (updated for new API)
  static Future<String> confirmPasswordResetNew(
    String token,
    String password,
    String password2,
  ) async {
    return ExceptionHandler.execute<String>(
      () async {
        final res = await DioInstance.dio.post(
          "/api/password-reset-confirm/",
          data: {
            "token": token,
            "password": password,
            "password2": password2,
          },
        );

        final responseData = res.data as Map<String, dynamic>;
        return responseData["message"] as String;
      },
    );
  }
}
