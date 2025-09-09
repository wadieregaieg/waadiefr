import 'package:flutter/foundation.dart';
import 'package:freshk/models/product_category.dart';
import 'package:freshk/models/product.dart';
import 'package:freshk/utils/dio_instance.dart';
import 'package:freshk/utils/exception_handler.dart';

class ProductService {
  // Fetch product categories
  static Future<List<ProductCategory>> fetchCategories() async {
    return ExceptionHandler.executeWithRetry<List<ProductCategory>>(
      () async {
        final res = await DioInstance.dio.get("/api/categories");
        final categories = (res.data['results'] as List<dynamic>)
            .map((e) => ProductCategory.fromJson(e as Map<String, dynamic>))
            .toList();

        return categories;
      },
      onError: (e) {
        // Additional error handling if needed
        debugPrint("Error fetching categories: $e");
        return [];
      },
    );
  }

  // Fetch products with optional filters and pagination
  static Future<Map<String, dynamic>> fetchProducts({
    int? categoryId,
    String? searchTerm,
    int? supplierId,
    bool activeOnly = true,
    int page = 1,
    int pageSize = 10,
  }) async {
    return ExceptionHandler.executeWithRetry<Map<String, dynamic>>(
      () async {
        // Build query parameters
        final Map<String, dynamic> queryParams = {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        };

        if (categoryId != null) {
          queryParams['category'] = categoryId.toString();
        }

        if (searchTerm != null && searchTerm.isNotEmpty) {
          queryParams['search'] = searchTerm;
        }

        if (supplierId != null) {
          queryParams['supplier'] = supplierId.toString();
        }

        if (activeOnly) {
          queryParams['is_active'] = 'true';
        }

        final res = await DioInstance.dio.get(
          "/api/products",
          queryParameters: queryParams,
        );

        final listOfProducts = (res.data['results'] as List<dynamic>)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();

        // Return pagination info along with the products
        return {
          'products': listOfProducts,
          'count': res.data['count'] ?? 0,
          'next': res.data['next'],
          'previous': res.data['previous'],
        };
      },
      onError: (e) {
        // Additional error handling if needed
        debugPrint("Error fetching products: $e");
        return {
          'products': <Product>[],
          'count': 0,
          'next': null,
          'previous': null,
        };
      },
    );
  }
}
