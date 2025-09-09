import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:freshk/models/product.dart';
import 'package:freshk/models/product_category.dart';
import 'package:freshk/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:async/async.dart';

class ProductProvider with ChangeNotifier {
  final List<Product> __products = [];
  final List<ProductCategory> __categories = [];
  bool loading = true;
  bool loadingMore = false;
  bool hasMoreProducts = true;
  int currentPage = 1;
  final int pageSize = 10;
  int? totalCount;
  DateTime? lastSearched;
  String? nextPageUrl;
  String _currentCategory = 'All';

  CancelableOperation<void>? _currentFetchOperation;
  int _fetchToken = 0;

  List<Product> get product => __products;
  List<ProductCategory> get categories => __categories;
  String get currentCategory => _currentCategory;

  set setProducts(List<Product> products) {
    __products.clear();
    __products.addAll(products);
    notifyListeners();
  }

  set setCategories(List<ProductCategory> categories) {
    __categories.clear();
    __categories.addAll(categories);
    notifyListeners();
  }

  set currentCategory(String value) {
    if (_currentCategory != value) {
      _currentCategory = value;
      notifyListeners();
    }
  }

  Future<void> fetchProductsAndCategories({
    bool showLoading = true,
    bool reset = true,
    BuildContext? context,
    int? categoryId,
    String? searchTerm,
  }) async {
    // Cancel previous fetch if running
    _currentFetchOperation?.cancel();
    _fetchToken++;
    final int fetchToken = _fetchToken;

    if (reset) {
      currentPage = 1;
      hasMoreProducts = true;
      nextPageUrl = null;
      if (showLoading) {
        loading = true;
        notifyListeners();
      }
    } else {
      if (!hasMoreProducts || loadingMore) {
        return;
      }
      loadingMore = true;
      notifyListeners();
    }

    _currentFetchOperation = CancelableOperation.fromFuture(() async {
      try {
        List<Future> futures = [];
        if (reset) {
          futures.add(ProductService.fetchCategories());
        }
        futures.add(ProductService.fetchProducts(
          categoryId: categoryId,
          searchTerm: searchTerm,
          page: currentPage,
          pageSize: pageSize,
        ));
        final results = await Future.wait(futures);
        if (fetchToken != _fetchToken) return; // Ignore outdated fetch
        if (reset) {
          final categories = results[0] as List<ProductCategory>;

          setCategories = categories;
          final productsData = results[1] as Map<String, dynamic>;
          final products = productsData['products'] as List<Product>;
          setProducts = products;
          totalCount = productsData['count'] as int;
          nextPageUrl = productsData['next'] as String?;
        } else {
          final productsData = results[0] as Map<String, dynamic>;
          final products = productsData['products'] as List<Product>;
          addProducts(products);
          nextPageUrl = productsData['next'] as String?;
        }
        hasMoreProducts = nextPageUrl != null;
        if (hasMoreProducts) {
          currentPage++;
        }
        loading = false;
        loadingMore = false;
        notifyListeners();
      } catch (e, stack) {
        if (fetchToken != _fetchToken) return; // Ignore outdated fetch
        if (kDebugMode) {
          debugPrint('Error in fetchProductsAndCategories: \\${e.toString()}');
          debugPrint(stack.toString());
        }

        loading = false;
        loadingMore = false;
        notifyListeners();
      }
    }(), onCancel: () {
      // Optionally handle cancellation
      loading = false;
      loadingMore = false;
      notifyListeners();
    });
  }

  // Load more products (for infinite scrolling)
  Future<void> loadMoreProducts({
    int? categoryId,
    String? searchTerm,
  }) async {
    if (!hasMoreProducts || loadingMore || loading) {
      return;
    }

    await fetchProductsAndCategories(
      showLoading: false,
      reset: false,
      categoryId: categoryId,
      searchTerm: searchTerm,
    );
  }

  void addProducts(List<Product> products) {
    // Prevent duplicates by checking product IDs
    final existingIds = __products.map((p) => p.id).toSet();
    final newProducts =
        products.where((p) => !existingIds.contains(p.id)).toList();
    __products.addAll(newProducts);
    notifyListeners();
  }

  // Dispose timer when provider is disposed
  @override
  void dispose() {
    _currentFetchOperation?.cancel();
    super.dispose();
  }
}
