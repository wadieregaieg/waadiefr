import 'package:freshk/models/apiResponses/checkout_response.dart';
import 'package:freshk/models/cart.dart';
import 'package:freshk/utils/dio_instance.dart';
import 'package:freshk/utils/freshk_expections.dart';
import 'package:freshk/utils/exception_handler.dart';
import 'package:freshk/utils/navigation_service.dart';
import 'package:flutter/foundation.dart';

class CartService {
  static Future<Cart> viewCart() async {
    return ExceptionHandler.execute<Cart>(
      () async {
        final res = await DioInstance.dio.get("/api/mobile/cart/");
        final data = res.data as Map<String, dynamic>;

        if (kDebugMode) {
          print("Cart response: ${data.toString()}");
        }

        // Directly parse the whole response as Cart
        return Cart.fromJson(data);
      },
    );
  }

  static Future<Cart> addItemToCart(
    int productId,
    int quantity,
  ) async {
    return ExceptionHandler.execute<Cart>(
      () async {
        final res = await DioInstance.dio.post(
          "/api/mobile/cart/add_item/",
          data: {
            "product_id": productId,
            "quantity": quantity,
          },
        );

        return Cart.fromJson(res.data);
      },
    );
  }

  static Future<Cart> removeItemFromCart(
    int itemId,
  ) async {
    return ExceptionHandler.execute<Cart>(
      () async {
        final res = await DioInstance.dio.post(
          "/api/mobile/cart/remove_item/",
          data: {
            "item_id": itemId,
          },
        );
        return Cart.fromJson(res.data);
      },
    );
  }

  static Future<Cart> updateItemInCart(
    int itemId,
    int quantity,
  ) async {
    return ExceptionHandler.executeWithRetry<Cart>(
      () async {
        final res = await DioInstance.dio.post(
          "/api/mobile/cart/update_item/",
          data: {
            "item_id": itemId,
            "quantity": quantity,
          },
        );
        return Cart.fromJson(res.data);
      },
      onError: (exception) {
        // Log the error for debugging
        debugPrint("Cart update failed: $exception");

        // You can add specific error handling here if needed
        // For example, show a specific message for certain error types
        if (exception is TransientServerException) {
          debugPrint("Transient server error - will retry automatically");
        } else if (exception is PersistentServerException) {
          debugPrint("Persistent server error - user should try later");
        }
      },
    );
  }

  static Future<CheckoutResponse> checkout({
    String paymentMethod = "cash_on_delivery",
    required int addressId,
  }) async {
    try {
      final res =
          await DioInstance.dio.post("/api/mobile/cart/checkout/", data: {
        "payment_method": paymentMethod,
        "address_id": addressId,
      });
      return CheckoutResponse.fromJson(res.data);
    } catch (e) {
      print("\x1B[31mCheckout error: $e\x1B[0m");
      // Use checkout-specific error handler
      final context = NavigationService.navigatorKey.currentContext;
      if (context == null) {
        throw Exception("Checkout context is null");
      }
      throw ExceptionHandler.handleCheckoutException(e, context);
    }
  }
  // Old Dio exception handler removed in favor of ExceptionHandler
}
