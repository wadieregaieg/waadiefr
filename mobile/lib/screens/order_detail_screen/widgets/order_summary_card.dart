import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../models/order.dart';
import '../../../extensions/localized_context.dart';

class OrderSummaryCard extends StatelessWidget {
  final Order order;
  final double subtotal;
  final double deliveryCharge;
  final double discount;
  final double totalAmount;
  final double scale;

  const OrderSummaryCard({
    Key? key,
    required this.order,
    required this.subtotal,
    required this.deliveryCharge,
    required this.discount,
    required this.totalAmount,
    required this.scale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          children: [
            // Show item count if available
            if (order.itemCount != null)
              _buildPriceRow(
                context.loc.items,
                '${order.itemCount} ${context.loc.items}',
                scale,
              ),
            _buildPriceRow(
              context.loc.subTotal,
              '${subtotal.toStringAsFixed(2)} TND',
              scale,
            ),
            if (deliveryCharge > 0)
              _buildPriceRow(
                context.loc.deliveryCharge,
                '${deliveryCharge.toStringAsFixed(2)} TND',
                scale,
              ),
            if (discount > 0)
              _buildPriceRow(
                context.loc.discount,
                '-${discount.toStringAsFixed(2)} TND',
                scale,
                isDiscount: true,
              ),
            Divider(color: Colors.grey[300], height: 24 * scale),
            _buildPriceRow(
              context.loc.totalAmount,
              '${totalAmount.toStringAsFixed(2)} TND',
              scale,
              isTotal: true,
            ),
            if (order.profitMargin != null && order.profitMargin! > 0) ...[
              SizedBox(height: 8 * scale),
              _buildProfitMarginInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, double scale,
      {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 * scale : 14 * scale,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.black87 : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 * scale : 14 * scale,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal
                  ? AppColors.primary
                  : isDiscount
                      ? Colors.green
                      : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitMarginInfo() {
    return Container(
      padding: EdgeInsets.all(8 * scale),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: Row(
        children: [
          Icon(
            Icons.trending_up,
            size: 16 * scale,
            color: Colors.green[600],
          ),
          SizedBox(width: 8 * scale),
          Text(
            'Profit Margin: ${order.profitMargin!.toStringAsFixed(2)}%', // TODO: Add to localization
            style: TextStyle(
              fontSize: 12 * scale,
              color: Colors.green[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
