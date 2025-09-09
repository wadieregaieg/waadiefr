import 'package:flutter/material.dart';
import 'package:freshk/constants.dart';
import 'package:freshk/models/order_status.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OrderFilterChip extends StatefulWidget {
  final OrderStatus? selectedStatus;
  final Function(OrderStatus?) onStatusChanged;
  final bool isLoading;

  const OrderFilterChip({
    super.key,
    this.selectedStatus,
    required this.onStatusChanged,
    this.isLoading = false,
  });

  @override
  State<OrderFilterChip> createState() => _OrderFilterChipState();
}

class _OrderFilterChipState extends State<OrderFilterChip>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(
              null, AppLocalizations.of(context)!.all, Icons.list_alt_outlined),
          const SizedBox(width: 8),
          _buildFilterChip(OrderStatus.pending,
              AppLocalizations.of(context)!.pending, Icons.schedule_outlined),
          const SizedBox(width: 8),
          _buildFilterChip(
              OrderStatus.processing,
              AppLocalizations.of(context)!.processing,
              Icons.inventory_2_outlined),
          const SizedBox(width: 8),
          _buildFilterChip(
              OrderStatus.out_for_delivery,
              AppLocalizations.of(context)!.outForDelivery,
              Icons.local_shipping_outlined),
          const SizedBox(width: 8),
          _buildFilterChip(
              OrderStatus.delivered,
              AppLocalizations.of(context)!.delivered,
              Icons.check_circle_outlined),
          const SizedBox(width: 8),
          _buildFilterChip(OrderStatus.completed,
              AppLocalizations.of(context)!.completed, Icons.verified_outlined),
          const SizedBox(width: 8),
          _buildFilterChip(OrderStatus.cancelled,
              AppLocalizations.of(context)!.cancelled, Icons.cancel_outlined),
          const SizedBox(width: 8),
          _buildFilterChip(
              OrderStatus.returned,
              AppLocalizations.of(context)!.returned,
              Icons.assignment_return_outlined),
        ],
      ),
    );
  }

  Widget _buildFilterChip(OrderStatus? status, String label, IconData icon) {
    final isSelected = widget.selectedStatus == status;

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: widget.isLoading ? null : () => widget.onStatusChanged(status),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey[300]!,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
