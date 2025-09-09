import 'package:freshk/constants.dart';
import 'package:freshk/extensions/localized_context.dart';
import 'package:freshk/models/cart.dart';
import 'package:freshk/providers/cart_provider.dart';
import 'package:freshk/utils/freshk_utils.dart';
import 'package:flutter/material.dart';
import 'package:freshk/widgets/base64_product_image.dart';
import 'package:freshk/widgets/custom_dissmissable.dart';

class ShoppingCartItem extends StatefulWidget {
  const ShoppingCartItem({
    super.key,
    required this.cart,
    required this.item,
    required this.price,
    required this.totalPrice,
  });

  final CartItem item;
  final CartProvider cart;
  final double price;
  final double totalPrice;

  @override
  State<ShoppingCartItem> createState() => _ShoppingCartItemState();
}

class _ShoppingCartItemState extends State<ShoppingCartItem> {
  bool _isDeleting = false;
  
  // Check if product is out of stock
  bool get _isOutOfStock => widget.item.product.stockQuantity <= 0;
  
  // Dialog for entering quantity
  Future<double?> _showQuantityDialog(
      BuildContext context, int itemId, double currentQuantity) {
    final controller = TextEditingController(text: currentQuantity.toString());
    final stock = widget.item.product.stockQuantity;

    return showDialog<double>(
      useSafeArea: true,
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        title: const Text(
          'Enter quantity (kg)',
          style: TextStyles.sectionHeader,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              context.loc.availableStockWithDecimal(stock.toStringAsFixed(1)),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.canPop(ctx)) {
                Navigator.pop(ctx);
              }
            },
            child: Text(context.loc.cancel),
          ),
          TextButton(
            onPressed: () {
              final q = double.tryParse(controller.text) ?? currentQuantity;
              if (q <= 0) {
                FreshkUtils.showErrorSnackbar(
                    ctx, context.loc.quantityMustBeGreaterThanZero);
                return;
              }
              if (Navigator.canPop(ctx)) {
                Navigator.pop(ctx, q);
              }
            },
            child: Text(context.loc.ok),
          ),
        ],
      ),
    );
  }

  // Dismissible background
  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.red[500],
      ),
      padding: const EdgeInsets.only(right: 20, left: 50),
      margin: const EdgeInsets.only(right: 2, left: 4, top: 8, bottom: 8),
      child: _isDeleting
          ? const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : const Icon(Icons.delete_forever, color: Colors.white, size: 30),
    );
  }

  // Product info (title, price, total)
  Widget _buildProductInfo() {
    return SizedBox(
      height: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.item.product.name,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _isOutOfStock ? Colors.grey.shade600 : Colors.black,
            ),
          ),
          Text(
            '${widget.price.toStringAsFixed(2)} TND/kg',
            style: TextStyle(
              fontSize: 14,
              color: _isOutOfStock ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
          Row(
            children: [
              Text(
                '${widget.totalPrice.toStringAsFixed(2)} TND',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _isOutOfStock ? Colors.red.shade600 : AppColors.primary,
                ),
              ),
              if (_isOutOfStock) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200, width: 1),
                  ),
                  child: Text(
                    'Out of Stock',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Quantity controls (remove, edit, add)
  Widget _buildQuantityControls(BuildContext context) {
    final iconButtonStyle = IconButton.styleFrom(
      splashFactory: NoSplash.splashFactory,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final itemQuantity = double.tryParse(widget.item.quantity) ?? 0.0;
    final stock = widget.item.product.stockQuantity;
    final isUpdating = widget.cart.isItemUpdating(widget.item.id);

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: SizedBox(
        height: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Add button
            IconButton(
              icon: Icon(
                Icons.add, 
                size: 20, 
                color: _isOutOfStock 
                    ? Colors.grey.shade400 
                    : AppColors.primary
              ),
              padding: const EdgeInsets.all(2),
              constraints: const BoxConstraints(),
              style: iconButtonStyle,
              onPressed: (_isOutOfStock || isUpdating)
                  ? null
                  : () {
                      if (itemQuantity < stock) {
                        // Haptic feedback on add
                        Feedback.forTap(context);
                        widget.cart.updateQuantity(
                            widget.item.id, (itemQuantity + 1).round(),
                            context: context);
                      }
                    },
            ),
            // Remove button
            // Quantity display & edit
            SizedBox(
              width: 50,
              child: InkWell(
                onTap: (_isOutOfStock || isUpdating)
                    ? null
                    : () async {
                        final newQuantity = await _showQuantityDialog(
                            context, widget.item.id, itemQuantity);
                        if (newQuantity != null) {
                          if (newQuantity <= 0) {
                            FreshkUtils.showErrorSnackbar(
                                context, context.loc.quantityCannotBeZero);
                          } else if (newQuantity > stock) {
                            widget.cart.updateQuantity(
                                widget.item.id, stock.round(),
                                context: context);
                            FreshkUtils.showInfoSnackbar(
                                context,
                                context.loc.quantitySetToMaximumAvailable(
                                    stock.round()));
                          } else {
                            widget.cart.updateQuantity(
                                widget.item.id, newQuantity.round(),
                                context: context);
                          }
                        }
                      },
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '${itemQuantity.toStringAsFixed(1)}kg',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: (_isOutOfStock || isUpdating) 
                              ? Colors.grey.shade400 
                              : AppColors.primary,
                        ),
                        maxLines: 1,
                      ),
                      if (isUpdating)
                        Center(
                          child: SizedBox(
                            width: 8,
                            height: 8,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red,
                      ),
                    )
                  : Icon(
                      Icons.remove, 
                      size: 20, 
                      color: _isOutOfStock 
                          ? Colors.grey.shade400 
                          : Colors.red
                    ),
              padding: const EdgeInsets.all(2),
              constraints: const BoxConstraints(),
              style: iconButtonStyle,
              onPressed: (_isOutOfStock || isUpdating || _isDeleting)
                  ? null
                  : () {
                      if (itemQuantity > 1) {
                        widget.cart.updateQuantity(
                            widget.item.id, (itemQuantity - 1).round(),
                            context: context);
                      } else {
                        setState(() {
                          _isDeleting = true;
                        });
                        widget.cart.removeItem(widget.item.id);
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomDissmissable(
      key: Key(widget.item.product.id),
      // direction: DismissDirection.endToStart,

      direction: DismissDirection.endToStart,
      background: _buildDismissBackground(),
      onDismissed: (direction) {
        widget.cart.removeItem(widget.item.id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        decoration: BoxDecoration(
          color: _isOutOfStock ? Colors.grey.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: _isOutOfStock 
              ? Border.all(color: Colors.red.shade200, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: _isOutOfStock 
                  ? Colors.red.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Product image with out-of-stock overlay
                  Stack(
                    children: [
                      Base64ProductImage(
                        imageUrl: widget.item.product.image ?? '',
                        height: 100,
                        width: 110,
                      ),
                      if (_isOutOfStock)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.block,
                                color: Colors.red.shade700,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  _buildProductInfo(),
                  const Spacer(),
                  _buildQuantityControls(context),
                ],
              ),
            ),
            // Out of stock banner at the top
            if (_isOutOfStock)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'OUT OF STOCK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
