import 'package:freshk/models/apiResponses/checkout_response.dart';
import 'package:freshk/models/cart.dart';
import 'package:freshk/services/cart_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/product.dart';
import 'package:freshk/utils/freshk_utils.dart';

class CartProvider with ChangeNotifier {
  Cart userCart = Cart(
    id: 0,
    totalAmount: '0',
    items: [],
  );
  final Map<int, Timer> _pendingUpdates = {};
  final Map<int, bool> _itemUpdatingStatus = {};
  final Map<String, bool> _productAddingStatus = {};

  bool isLoading = false;

  // Check if a specific item is being updated
  bool isItemUpdating(int itemId) => _itemUpdatingStatus[itemId] ?? false;

  // Check if any items are being updated
  bool get hasUpdatingItems =>
      _itemUpdatingStatus.values.any((isUpdating) => isUpdating);

  // Check if a specific product is being added to cart
  bool isProductAddingToCart(String productId) =>
      _productAddingStatus[productId] ?? false;

  Future<void> fetchCart(
      {bool showLoading = true, BuildContext? context}) async {
    if (showLoading) {
      isLoading = true;
      notifyListeners();
    }
    try {
      userCart = await CartService.viewCart();
      if (kDebugMode) print('Fetched cart: ${userCart.toJson()}');
    } catch (e) {
      if (kDebugMode) print('Fetch cart failed: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Cancel all pending updates
    for (var timer in _pendingUpdates.values) {
      timer.cancel();
    }
    _pendingUpdates.clear();
    _itemUpdatingStatus.clear();
    super.dispose();
  }

  List<CartItem> get items => userCart.items;

  int get itemCount => userCart.items.length;

  double get total {
    return double.tryParse(userCart.totalAmount) ?? 0.0;
  }

  Future<void> addItem(Product product, int quantity,
      {BuildContext? context}) async {
    final productId = product.id;
    _productAddingStatus[productId] = true;
    notifyListeners();

    try {
      userCart = await CartService.addItemToCart(
        int.parse(product.id),
        quantity,
      );
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Add item failed: $e');
      rethrow;
    } finally {
      _productAddingStatus[productId] = false;
      notifyListeners();
    }
  }

  Future<void> removeItem(int itemId, {BuildContext? context}) async {
    userCart.items.removeWhere((item) => item.id == itemId);
    // Optimistic UI update: notify immediately, no global loading
    notifyListeners();
    try {
      userCart = await CartService.removeItemFromCart(itemId);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Remove item failed: $e');
      rethrow;
    }
  }

  Future<void> updateQuantity(int itemId, int newQuantity,
      {BuildContext? context}) async {
    // Validate quantity before making API call
    if (newQuantity <= 0) {
      throw Exception('Quantity must be greater than 0');
    }

    // Store original state for potential rollback
    final originalCart = Cart.fromJson(userCart.toJson());

    // Optimistic UI update - immediately update the UI
    final itemIndex = userCart.items.indexWhere((item) => item.id == itemId);
    if (itemIndex != -1) {
      userCart.items[itemIndex] = userCart.items[itemIndex].copyWith(
        quantity: newQuantity.toString(),
      );

      // Recalculate total optimistically
      double newTotal = 0.0;
      for (var item in userCart.items) {
        newTotal +=
            item.product.price * (double.tryParse(item.quantity) ?? 0.0);
      }
      userCart = Cart(
        id: userCart.id,
        totalAmount: newTotal.toStringAsFixed(2),
        items: userCart.items,
      );

      notifyListeners();
    }

    // Cancel any pending update for this item
    _pendingUpdates[itemId]?.cancel();

    // Set up debounced API call (wait 500ms after last change)
    _pendingUpdates[itemId] =
        Timer(const Duration(milliseconds: 500), () async {
      _itemUpdatingStatus[itemId] = true;
      notifyListeners();

      try {
        userCart = await CartService.updateItemInCart(
          itemId,
          newQuantity,
        );
        _pendingUpdates.remove(itemId);
      } catch (e) {
        if (kDebugMode) {
          print('Update item failed: $e');
          print('Item ID: $itemId, New Quantity: $newQuantity');
          print('Reverting to original cart state');
        }

        // Rollback to original state on error
        userCart = originalCart;

        // Show error to user if context is available
        if (context != null && context.mounted) {
          FreshkUtils.showErrorSnackbar(
              context, 'Failed to update quantity. Please try again.');
        }
      } finally {
        _itemUpdatingStatus[itemId] = false;
        notifyListeners();
      }
    });
  }

  Future<void> refreshCart({BuildContext? context}) async {
    isLoading = true;
    notifyListeners();
    try {
      userCart = await CartService.viewCart();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Refresh cart failed: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<CheckoutResponse> checkout({
    required int addressId,
    String paymentMethod = "cash_on_delivery",
    BuildContext? context,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      // Pre-checkout validation
      if (userCart.items.isEmpty) {
        throw Exception('Cannot checkout with empty cart');
      }

      final cartRes = await CartService.checkout(
        addressId: addressId,
        paymentMethod: paymentMethod,
      );

      // Clear cart after successful checkout
      userCart = Cart(id: 0, totalAmount: '0', items: []);
      notifyListeners();

      return cartRes;
    } catch (e) {
      if (kDebugMode) print('Checkout failed: $e');
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
