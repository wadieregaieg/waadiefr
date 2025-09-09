import 'package:flutter/foundation.dart';
import 'package:freshk/models/order.dart';
import 'package:freshk/models/product.dart';
import 'package:freshk/utils/dio_instance.dart';
import 'package:freshk/utils/exception_handler.dart';
import 'package:dio/src/response.dart';

class OrderService {
  static Future<Map<String, dynamic>> getOrdersPaginated({
    int page = 1,
    int pageSize = 10,
    String? status,
    String? nextUrl, // Add support for next URL
  }) async {
    return ExceptionHandler.executeWithRetry<Map<String, dynamic>>(
      () async {
        String url;
        Map<String, dynamic>? queryParams;

        if (nextUrl != null && nextUrl.isNotEmpty) {
          // Use the provided next URL directly
          url = nextUrl;
        } else {
          // First request - use base URL with query parameters
          url = "/api/mobile/orders/";
          queryParams = {};

          if (status != null && status.isNotEmpty) {
            queryParams['status'] = status;
          }
        }

        late final Response res;
        try {
          res = await DioInstance.dio.get(url, queryParameters: queryParams);
        } catch (e) {
          // Handle "Invalid page" error specifically
          if (e.toString().contains('Invalid page')) {
            return {
              'orders': <Order>[],
              'count': 0,
              'next': null,
              'previous': null,
              'totalPages': 0,
              'currentPage': page,
              'hasNext': false,
              'hasPrevious': false,
            };
          }
          rethrow; // Re-throw other errors
        }

        debugPrint("📡 API Response status: ${res.statusCode}");
        debugPrint("📡 API Response data type: ${res.data.runtimeType}");
        debugPrint("📡 API Response data: ${res.data}");

        // Handle null response
        if (res.data == null) {
          debugPrint("⚠️ Received null response, returning empty result");
          return {
            'orders': <Order>[],
            'count': 0,
            'next': null,
            'previous': null,
            'totalPages': 0,
            'currentPage': page,
            'hasNext': false,
            'hasPrevious': false,
          };
        }

        // Handle different response formats
        List<dynamic> dataList;
        int count = 0;
        String? next;
        String? previous;

        if (res.data is List) {
          // Direct array response (non-paginated)
          dataList = res.data as List<dynamic>;
          count = dataList.length;
        } else if (res.data is Map<String, dynamic>) {
          // Paginated response with results key
          final responseMap = res.data as Map<String, dynamic>;
          dataList = (responseMap["results"] as List<dynamic>?) ?? <dynamic>[];
          count = responseMap['count'] ?? dataList.length;
          next = responseMap['next'];
          previous = responseMap['previous'];
        } else {
          // Unexpected format
          debugPrint("❌ Unexpected response format: ${res.data.runtimeType}");
          return {
            'orders': <Order>[],
            'count': 0,
            'next': null,
            'previous': null,
            'totalPages': 0,
            'currentPage': page,
            'hasNext': false,
            'hasPrevious': false,
          };
        }
        final orders = dataList
            .map((order) => Order.fromJson(order as Map<String, dynamic>))
            .toList();

        // For cursor-based pagination, we don't calculate totalPages
        // We just trust the 'next' field from the API
        final hasNext = next != null;
        final hasPrevious = previous != null;

        return {
          'orders': orders,
          'count': count,
          'next': next,
          'previous': previous,
          'totalPages': 0, // Not applicable for cursor pagination
          'currentPage': page, // Keep for compatibility
          'hasNext': hasNext,
          'hasPrevious': hasPrevious,
        };
      },
    );
  }

  static Future<Order> getOrderById(int id) async {
    return ExceptionHandler.execute<Order>(
      () async {
        final res = await DioInstance.dio.get("/api/mobile/orders/$id/");

        if (res.data == null) {
          throw Exception("Order not found");
        }

        final data = res.data as Map<String, dynamic>;
        return Order.fromJson(data);
      },
    );
  }

  static Future<List<Product>> getOrderItems() async {
    return ExceptionHandler.execute<List<Product>>(
      () async {
        final res = await DioInstance.dio.get("/api/mobile/orders/items/");
        final data = res.data as List<Map<String, dynamic>>;
        return data.map((order) => Product.fromJson(order)).toList();
      },
    );
  }

  static Future<bool> cancelOrder(int id) async {
    return ExceptionHandler.execute<bool>(
      () async {
        final res =
            await DioInstance.dio.post("/api/mobile/orders/$id/cancel/");

        if (res.data == null) {
          return false;
        }

        final data = res.data as Map<String, dynamic>;
        return data["error"] == null && data["message"] != null;
      },
    );
  }
  // Old Dio exception handler removed in favor of ExceptionHandler
}
