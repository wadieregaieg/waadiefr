import 'dart:io';
import 'package:freshk/services/user_service.dart';
import 'package:freshk/utils/freshk_utils.dart';
import 'package:freshk/utils/navigation_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DioInstance {
  static final DioInstance _instance = DioInstance._internal();

  factory DioInstance() {
    return _instance;
  }

  DioInstance._internal();

  static final Dio __dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      responseType: ResponseType.json,
      baseUrl: false
          ? "http://192.168.100.121:8000" // Local development URL
          : "https://b2b-freshk-backend-ld4r.onrender.com",
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, ErrorInterceptorHandler handler) async {
          // Network connectivity issues handling
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.connectionError ||
              (e.type == DioExceptionType.unknown &&
                  e.error is SocketException)) {
            // Log network error but don't automatically delete tokens
            if (kDebugMode) {
              debugPrint('\x1B[33mNetwork error: ${e.message}\x1B[0m');
            }
            // We can't return a custom exception here, just continue with original error
            // Our app will handle this in the splash screen
            return handler.next(e);
          }

          // Token refresh logic
          if (e.response?.statusCode == 401 &&
              e.response?.data != null &&
              e.response?.data["code"] == "token_not_valid") {
            if (kDebugMode) {
              debugPrint('\x1B[31mToken invalid: ${e.response?.data}\x1B[0m');
            }

            final tokens = await FreshkUtils.getTokensFromStorage();
            if (tokens == null) {
              // Tokens not available
              return handler.next(e);
            }
            try {
              // Refresh the access token
              final newAccessToken = await UserService.refreshAccesToken(
                tokens.refresh,
              );

              if (kDebugMode) {
                debugPrint('\x1B[34mNew Access Token acquired\x1B[0m');
              }

              // Update stored tokens
              FreshkUtils.saveAuthTokens(newAccessToken, tokens.refresh);

              // Retry the failed request with the new token
              final retryRequest = e.requestOptions;
              retryRequest.headers['Authorization'] = 'Bearer $newAccessToken';

              final response = await dio.request(
                retryRequest.path,
                options: Options(
                  method: retryRequest.method,
                  headers: retryRequest.headers,
                ),
                data: retryRequest.data,
                queryParameters: retryRequest.queryParameters,
              );

              return handler.resolve(response);
            } on DioException catch (e) {
              // If token refresh fails, continue with original error
              if (kDebugMode) {
                debugPrint('\x1B[31mToken refresh failed: $e\x1B[0m');
              }
              if (e.response?.statusCode == 401) {
                // If the refresh token is also invalid, delete tokens and navigate to login
                FreshkUtils.deleteAuthTokens();
                FreshkUtils.deleteUserData();
                NavigationService.navigateToLogin();
              }
              return handler.next(e);
            }
          }

          // For all other errors, continue with error handling
          return handler.next(e);
        },
      ),
    );

  static Dio get dio => __dio;

  static setDioAuthorizationHeader(String accessToken) {
    __dio.options.headers["Authorization"] = "Bearer $accessToken";
  }

  static setDioHeaders(Map<String, dynamic> headers) {
    __dio.options.headers.addAll(headers);
  }
}
