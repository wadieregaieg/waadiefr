import 'package:freshk/constants.dart';
import 'package:freshk/models/order_status.dart';
import 'package:freshk/providers/order_provider.dart';
import 'package:freshk/utils/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../extensions/localized_context.dart';
import 'package:freshk/utils/freshk_utils.dart';
import 'package:provider/provider.dart';

// Import modular widgets
import 'widgets/widgets.dart';

// Import extensions
import '../../providers/cart_provider.dart';
import '../../routes.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isCopied = false;
  bool _isReordering = false;

  Color _getStatusColor() {
    switch (widget.order.status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.out_for_delivery:
        return Colors.purple;
      case OrderStatus.delivered:
        return AppColors.primary;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.returned:
        return Colors.red;
    }
  }

  IconData _getStatusIcon() {
    switch (widget.order.status) {
      case OrderStatus.pending:
        return Icons.schedule_outlined;
      case OrderStatus.processing:
        return Icons.inventory_2_outlined;
      case OrderStatus.out_for_delivery:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.check_circle_outline;
      case OrderStatus.completed:
        return Icons.verified_outlined;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
      case OrderStatus.returned:
        return Icons.assignment_return_outlined;
    }
  }

  String _getStatusText() {
    switch (widget.order.status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.out_for_delivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.returned:
        return 'Returned';
    }
  }

  Widget _buildOrderStatusCard(double scale) {
    return Container(
      margin: EdgeInsets.all(16 * scale),
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'EEEE, MMMM dd, yyyy',
                        Localizations.localeOf(context).languageCode.toString(),
                      ).format(widget.order.orderDate),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.receipt_outlined,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                '${context.loc.orderNumber} #${widget.order.id}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _copyOrderNumber,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isCopied
                        ? AppColors.primary.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isCopied ? Icons.check : Icons.copy,
                    size: 16,
                    color: _isCopied ? AppColors.primary : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyOrderNumber() {
    setState(() {
      _isCopied = true;
    });
    FreshkUtils.showInfoSnackbar(context, 'Order number copied to clipboard');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double scale = screenWidth / 375.0; // Using 375 as base width

    // Calculate pricing
    final subtotal = _calculateSubtotal();
    final totalAmount = double.tryParse(widget.order.totalAmount) ?? 0.0;
    final deliveryCharge = _calculateDeliveryCharge(totalAmount, subtotal);
    final discount = _calculateDiscount(totalAmount, subtotal);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context, scale),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildOrderStatusCard(scale),

            // if (widget.order.status != OrderStatus.cancelled)
            // Order Status Timeline
            // OrderTimeline(order: widget.order, scale: scale),

            // Payment Information Section
            SectionTitle(
                title: context.loc.paymentMethodAndStatus, scale: scale),
            PaymentDetailsCard(order: widget.order, scale: scale),

            // Delivery Address Section
            SectionTitle(title: context.loc.deliveryAddress, scale: scale),
            DeliveryAddressCard(order: widget.order, scale: scale),

            // Items Section
            SectionTitle(title: context.loc.articlesOrdered, scale: scale),
            ..._buildProductCards(scale),

            // Order Summary Section
            SectionTitle(title: context.loc.orderInfo, scale: scale),
            OrderSummaryCard(
              order: widget.order,
              subtotal: subtotal,
              deliveryCharge: deliveryCharge,
              discount: discount,
              totalAmount: totalAmount,
              scale: scale,
            ),

            // Notes Section
            if (widget.order.notes != null && widget.order.notes!.isNotEmpty)
              _buildNotesSection(widget.order.notes!, scale),

            // Action Buttons
            ActionButtons(
              order: widget.order,
              scale: scale,
              onCancel: () async {
                if (widget.order.status == OrderStatus.pending) {
                  final res = await _showCancelOrderDialog(context);
                  if (res == true) {
                    NavigationService.popRoute();
                  }
                } else {
                  FreshkUtils.showErrorSnackbar(
                      context, context.loc.canCancelOnlyPending);
                }
              },
              onReorder: _reorderItems,
              isReordering: _isReordering,
            ),

            // Bottom padding
            SizedBox(height: 12 * scale),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, double scale) {
    return AppBar(
      title: Text(
        context.loc.orderDetails,
        style: TextStyle(
          color: Colors.black87,
          fontSize: 20 * scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black87),
    );
  }

  List<Widget> _buildProductCards(double scale) {
    return widget.order.items
        .map((item) => ProductCard(item: item, scale: scale))
        .toList();
  }

  Widget _buildNotesSection(String notes, double scale) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.loc.notes,
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8 * scale),
            Text(
              notes,
              style: TextStyle(
                fontSize: 14 * scale,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateSubtotal() {
    double subtotal = 0;
    for (var item in widget.order.items) {
      if (item.itemTotal != null) {
        subtotal += item.itemTotal!;
      } else {
        subtotal += item.product.price * double.tryParse(item.quantity)!;
      }
    }
    return subtotal;
  }

  double _calculateDeliveryCharge(double totalAmount, double subtotal) {
    return totalAmount > subtotal ? totalAmount - subtotal : 0.0;
  }

  double _calculateDiscount(double totalAmount, double subtotal) {
    return totalAmount < subtotal ? subtotal - totalAmount : 0.0;
  }

  Future<bool?> _showCancelOrderDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.loc.cancelOrder),
          content: Text(context.loc.cancelOrderConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                context.loc.cancel,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                final orderProvider = context.read<OrderProvider>();

                try {
                  final isCanceled = await orderProvider.cancelOrder(
                    widget.order.id,
                  );
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (isCanceled) {
                      await orderProvider.refreshOrders(context: context);
                    } else {
                      FreshkUtils.showErrorSnackbar(
                          context, context.loc.failedToDeleteOrder);
                    }
                  });
                  Navigator.of(context).pop(true);
                } catch (e) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    FreshkUtils.showErrorSnackbar(context,
                        context.loc.failedToDeleteOrderWithError(e.toString()));
                  });
                  Navigator.of(context).pop(false);
                }
              },
              child: Text(
                context.loc.confirm,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _reorderItems() async {
    setState(() => _isReordering = true);
    final cartProvider = context.read<CartProvider>();
    bool hasError = false;
    for (var item in widget.order.items) {
      try {
        final qty = int.tryParse(item.quantity) ?? 1;
        await cartProvider.addItem(item.product, qty);
      } catch (e) {
        hasError = true;
      }
    }
    if (hasError) {
      FreshkUtils.showErrorSnackbar(
          context, context.loc.someItemsCouldNotBeAddedToCart);
    } else {
      FreshkUtils.showSuccessSnackbar(context, context.loc.itemsAddedToCart);
      Navigator.pushNamed(
        context,
        AppRoutes.orderSummary,
        arguments: cartProvider.total,
      );
    }
    if (mounted) setState(() => _isReordering = false);
  }
}
