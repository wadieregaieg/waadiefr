import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:freshk/services/order_service.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import 'dart:async';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  Timer? _autoFetchTimer;
  // Pagination properties - Updated for cursor-based pagination
  int _currentPage =
      1; // Keep for compatibility, but not used for actual pagination
  int _totalPages = 0;
  int _totalCount = 0;
  bool _hasNext = false;
  bool _hasPrevious = false;
  bool _isLoadingMore = false;
  String? _nextUrl; // Store the next URL for cursor pagination
  final int _pageSize = 10;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalCount => _totalCount;
  bool get hasNext => _hasNext;
  bool get hasPrevious => _hasPrevious;
  int get pageSize => _pageSize;

  // Explicitly type getters and add debug print
  List<Order> get activeOrders {
    final active = _orders
        .where((order) =>
            order.status == OrderStatus.pending ||
            order.status == OrderStatus.processing ||
            order.status == OrderStatus.out_for_delivery)
        .toList();
    if (kDebugMode) print('Active orders: \\${active.length}');
    return active;
  }

  List<Order> get pastOrders {
    final past = _orders
        .where((order) =>
            order.status == OrderStatus.delivered ||
            order.status == OrderStatus.completed ||
            order.status == OrderStatus.cancelled ||
            order.status == OrderStatus.returned)
        .toList();
    if (kDebugMode) print('Past orders: \\${past.length}');
    return past;
  }

  // Add these computed properties for filtered endless scroll
  int get filteredTotalCount => _orders.length;
  bool get filteredHasNext => false;
  Future<void> fetchOrders(
      {bool showLoading = true,
      BuildContext? context,
      bool reset = true}) async {
    if (reset) {
      _currentPage = 1;
      _orders = [];
      _nextUrl = null; // Reset next URL for fresh start
    }

    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }
    _error = null;
    notifyListeners();
    try {
      final result = await OrderService.getOrdersPaginated(
        page: _currentPage,
        pageSize: _pageSize,
        nextUrl: reset ? null : _nextUrl, // Use nextUrl for pagination
      );

      final newOrders = result['orders'] as List<Order>;

      if (reset) {
        _orders = newOrders;
      } else {
        _orders.addAll(newOrders);
      }

      _totalPages = result['totalPages'] as int;
      _totalCount = result['count'] as int;
      _hasNext = result['hasNext'] as bool;
      _hasPrevious = result['hasPrevious'] as bool;
      _nextUrl = result['next'] as String?; // Store next URL
      _currentPage = result['currentPage'] as int;

      if (kDebugMode) {
        print(
            'Fetched orders: ${newOrders.length}, Total: $_totalCount, Page: $_currentPage/$_totalPages');
      }
    } catch (e) {
      _error = e.toString();
      if (reset) {
        _orders = []; // Reset to empty list on error
      }
      if (kDebugMode) print('Error fetching orders: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreOrders({BuildContext? context}) async {
    if (_isLoadingMore || !_hasNext) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      // For cursor-based pagination, we don't increment page number
      // Just call fetchOrders with reset=false, which will use _nextUrl
      await fetchOrders(showLoading: false, context: context, reset: false);
    } catch (e) {
      // Handle "Invalid page" error - this means no more pages available
      if (e.toString().contains('Invalid page')) {
        _hasNext = false;
        if (kDebugMode) print('📄 No more pages available - reached end');
      } else {
        rethrow; // Re-throw other errors
      }
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Method to check if we should load more data based on scroll position
  bool shouldLoadMore(ScrollController scrollController,
      {double threshold = 200.0}) {
    if (!_hasNext || _isLoadingMore) {
      if (kDebugMode) {
        print(
            '🚫 shouldLoadMore: hasNext=$_hasNext, isLoadingMore=$_isLoadingMore');
      }
      return false;
    }

    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;
    final shouldLoad = currentScroll >= (maxScroll - threshold);

    if (kDebugMode && shouldLoad) {
      print(
          '📜 shouldLoadMore: YES - currentScroll=$currentScroll, maxScroll=$maxScroll, threshold=$threshold');
    }

    return shouldLoad;
  }

  Future<void> goToPage(int page, {BuildContext? context}) async {
    if (page < 1 || page > _totalPages || page == _currentPage) return;

    _currentPage = page;
    await fetchOrders(showLoading: true, context: context, reset: true);
  }

  Future<void> nextPage({BuildContext? context}) async {
    if (_hasNext) {
      await goToPage(_currentPage + 1, context: context);
    }
  }

  Future<void> previousPage({BuildContext? context}) async {
    if (_hasPrevious) {
      await goToPage(_currentPage - 1, context: context);
    }
  }

  Future<void> refreshOrders({BuildContext? context}) async {
    await fetchOrders(context: context);
  }

  Order? getOrderById(int id) {
    try {
      return _orders.firstWhere((order) => order.id == id);
    } catch (_) {
      return null;
    }
  }

  void clear() {
    _orders = [];
    _error = null;
    _currentPage = 1;
    _totalPages = 0;
    _totalCount = 0;
    _hasNext = false;
    _hasPrevious = false;
    notifyListeners();
  }

  void startAutoFetch() {
    _autoFetchTimer?.cancel();
    // first fetch
    fetchOrders(showLoading: true);

    _autoFetchTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      fetchOrders(showLoading: false);
    });
  }

  Future<bool> cancelOrder(int id) async {
    final res = await OrderService.cancelOrder(id);
    if (res) {
      _orders.removeWhere((order) => order.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _autoFetchTimer?.cancel();
    super.dispose();
  }
}
