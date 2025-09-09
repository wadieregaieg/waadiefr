import 'package:flutter/material.dart';
import 'package:freshk/models/order.dart';
import 'package:freshk/models/order_status.dart';
import 'package:freshk/constants.dart';
import 'package:freshk/extensions/localized_context.dart';
import 'package:freshk/utils/freshk_utils.dart';
import 'package:freshk/widgets/base64_product_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ModernOrderCard extends StatefulWidget {
  final Order order;
  final VoidCallback? onTap;

  const ModernOrderCard({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  State<ModernOrderCard> createState() => _ModernOrderCardState();
}

class _ModernOrderCardState extends State<ModernOrderCard>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isCopied = false;
  late AnimationController _expandController;
  late AnimationController _copyController;
  late Animation<double> _expandAnimation;
  late Animation<double> _copyAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _copyController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    _copyAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _copyController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _expandController.dispose();
    _copyController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  void _copyOrderNumber() {
    setState(() {
      _isCopied = true;
    });
    _copyController.forward().then((_) {
      _copyController.reverse();
    });

    // Copy to clipboard
    FreshkUtils.showInfoSnackbar(
        context, AppLocalizations.of(context)!.orderNumberCopied);

    // Reset after delay
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
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildTimeline(),
            if (_isExpanded) _buildExpandedContent(),
            _buildExpandButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              // Status indicator
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMd(
                              Localizations.localeOf(context).toString())
                          .format(widget.order.orderDate),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // Order total
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.order.totalAmount} TND',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${widget.order.items.length} ${AppLocalizations.of(context)!.items}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Order number row
          Row(
            children: [
              Icon(
                Icons.receipt_outlined,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                '${AppLocalizations.of(context)!.orderNumber} ${widget.order.id.toString()}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _copyAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _copyAnimation.value,
                    child: GestureDetector(
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
                          color:
                              _isCopied ? AppColors.primary : Colors.grey[600],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

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

  String _getStatusText() {
    switch (widget.order.status) {
      case OrderStatus.pending:
        return AppLocalizations.of(context)!.pending;
      case OrderStatus.processing:
        return AppLocalizations.of(context)!.processing;
      case OrderStatus.out_for_delivery:
        return AppLocalizations.of(context)!.outForDelivery;
      case OrderStatus.delivered:
        return AppLocalizations.of(context)!.delivered;
      case OrderStatus.completed:
        return AppLocalizations.of(context)!.completed;
      case OrderStatus.cancelled:
        return AppLocalizations.of(context)!.cancelled;
      case OrderStatus.returned:
        return AppLocalizations.of(context)!.returned;
    }
  }

  bool _isStepCompleted(int step) {
    switch (widget.order.status) {
      case OrderStatus.pending:
        return step == 0;
      case OrderStatus.processing:
        return step <= 1;
      case OrderStatus.out_for_delivery:
        return step <= 2;
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return step <= 3;
      case OrderStatus.cancelled:
        return step == 4; // Only the cancelled step is completed
      case OrderStatus.returned:
        return step == 0;
    }
  }

  bool _isCurrentStep(int step) {
    switch (widget.order.status) {
      case OrderStatus.pending:
        return step == 0;
      case OrderStatus.processing:
        return step == 1;
      case OrderStatus.out_for_delivery:
        return step == 2;
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return step == 3;
      case OrderStatus.cancelled:
        return step == 4;
      case OrderStatus.returned:
        return step == 0;
    }
  }

  Widget _buildTimeline() {
    final isCancelled = widget.order.status == OrderStatus.cancelled;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: isCancelled
            ? [
                _buildTimelineStep(AppLocalizations.of(context)!.cancelled, 0,
                    Icons.cancel_outlined),
              ]
            : [
                _buildTimelineStep(AppLocalizations.of(context)!.confirmed, 0,
                    Icons.check_circle_outline),
                _buildTimelineConnector(0),
                _buildTimelineStep(AppLocalizations.of(context)!.packed, 1,
                    Icons.inventory_2_outlined),
                _buildTimelineConnector(1),
                _buildTimelineStep(AppLocalizations.of(context)!.outForDelivery,
                    2, Icons.local_shipping_outlined),
                _buildTimelineConnector(2),
                _buildTimelineStep(AppLocalizations.of(context)!.delivered, 3,
                    Icons.home_outlined),
              ],
      ),
    );
  }

  Widget _buildTimelineStep(String label, int step, IconData icon) {
    final isCompleted = _isStepCompleted(step);
    final isCurrent = _isCurrentStep(step);

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.primary
                  : isCurrent
                      ? AppColors.primary.withOpacity(0.2)
                      : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: isCompleted
                  ? Colors.white
                  : isCurrent
                      ? AppColors.primary
                      : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isCompleted
                  ? AppColors.primary
                  : isCurrent
                      ? AppColors.primary
                      : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineConnector(int step) {
    final isCompleted = _isStepCompleted(step);

    return Container(
      height: 2,
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.primary : Colors.grey[300],
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return SizeTransition(
      sizeFactor: _expandAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDeliveryInfo(),
            const SizedBox(height: 16),
            _buildOrderItems(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.deliveryAddress,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            widget.order.deliveryAddress ??
                AppLocalizations.of(context)!.addressNotAvailable,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.shopping_basket_outlined,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.orderItems,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...widget.order.items.take(3).map((item) => _buildOrderItem(item)),
        if (widget.order.items.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              AppLocalizations.of(context)!
                  .moreItems(widget.order.items.length - 3),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrderItem(dynamic item) {
    final product = item.product;
    final quantity = item.quantity;
    final price = product.price;
    final total = price * (double.tryParse(quantity) ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Base64ProductImage(
              imageUrl:
                  product.image ?? FreshkUtils.getFallbackImage(product.name),
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppLocalizations.of(context)!.quantity(quantity.toString()),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${total.toStringAsFixed(2)} TND',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandButton() {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _expandAnimation.value * 3.14159 / 2,
              child: Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.primary,
                size: 24,
              ),
            );
          },
        ),
      ),
    );
  }
}
