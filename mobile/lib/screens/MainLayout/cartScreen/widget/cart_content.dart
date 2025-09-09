import 'package:freshk/constants.dart';
import 'package:freshk/extensions/localized_context.dart';
import 'package:freshk/providers/cart_provider.dart';
import 'package:freshk/routes.dart';
import 'package:freshk/screens/MainLayout/cartScreen/widget/shopping_cart_item.dart';
import 'package:flutter/material.dart';
import 'package:freshk/utils/freshk_utils.dart';

class CartContent extends StatelessWidget {
  const CartContent(
      {super.key, required this.cart, required this.isSwipeHintShown});
  final CartProvider cart;
  final bool isSwipeHintShown;
  final double swipeStartPosition = 50.0;

  // Check if there are out-of-stock items
  bool get _hasOutOfStockItems => cart.items.any((item) => item.product.stockQuantity <= 0);
  
  // Check if all items are out of stock
  bool get _allItemsOutOfStock => cart.items.every((item) => item.product.stockQuantity <= 0);

  Widget _buildOutOfStockWarning() {
    if (!_hasOutOfStockItems) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _allItemsOutOfStock 
                  ? 'All items in your cart are currently out of stock. Please remove them or wait for restocking.'
                  : 'Some items in your cart are out of stock. You can still checkout with available items.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    context.loc.total,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  if (cart.hasUpdatingItems) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                '${cart.total.toStringAsFixed(2)} TND',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (_allItemsOutOfStock) ...[
                const SizedBox(height: 4),
                Text(
                  'No items available for checkout',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _allItemsOutOfStock 
                  ? Colors.grey.shade400 
                  : const Color.fromRGBO(26, 181, 96, 0.9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _allItemsOutOfStock 
                ? null 
                : () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.orderSummary,
                      arguments: cart.total,
                    );
                  },
            child: Text(
              _allItemsOutOfStock ? 'Cannot Checkout' : context.loc.confirmOrder,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Out of stock warning
          _buildOutOfStockWarning(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                final price = item.product.price;
                final totalPrice =
                    price * (double.tryParse(item.quantity) ?? 0.0);
                if (index == 0) {
                  return _SwipeHintOverlay(
                    showHint: !isSwipeHintShown,
                    onHintShown: () async {
                      await FreshkUtils.setCartSwipeHintShown();
                    },
                    child: ShoppingCartItem(
                      cart: cart,
                      item: item,
                      price: price,
                      totalPrice: totalPrice,
                    ),
                  );
                }
                return ShoppingCartItem(
                  cart: cart,
                  item: item,
                  price: price,
                  totalPrice: totalPrice,
                );
              },
            ),
          ),
          _buildConfirmBar(context),
        ],
      ),
    );
  }
}

class _SwipeHintOverlay extends StatefulWidget {
  final Widget child;
  final bool showHint;
  final VoidCallback onHintShown;
  const _SwipeHintOverlay({
    required this.child,
    required this.showHint,
    required this.onHintShown,
  });

  @override
  State<_SwipeHintOverlay> createState() => _SwipeHintOverlayState();
}

class _SwipeHintOverlayState extends State<_SwipeHintOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  bool _hintVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.1, 0), // Offscreen right
      end: const Offset(-0.5, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.showHint) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _controller.forward();
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() => _hintVisible = false);
        widget.onHintShown();
      });
    } else {
      _hintVisible = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _hintVisible ? 1.0 : 0.0,
            curve: Curves.ease,
            child: IgnorePointer(
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  alignment: Alignment.centerRight,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swipe_left_rounded,
                            color: AppColors.primary, size: 28),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
