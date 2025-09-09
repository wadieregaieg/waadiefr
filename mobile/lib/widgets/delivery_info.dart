import 'package:freshk/models/order.dart';
import 'package:flutter/material.dart';
import 'package:freshk/extensions/localized_context.dart';

class DeliveryInfo extends StatelessWidget {
  final Order order;
  final double scale;
  const DeliveryInfo({Key? key, required this.order, required this.scale})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use only fields from the Order model
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.deliveryInformation,
            style: TextStyle(
              fontSize: 11 * scale,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: 8 * scale),
          _buildInfoRow(context.loc.orderId, order.id.toString(), scale),
          SizedBox(height: 4 * scale),
          _buildInfoRow(context.loc.orderDate, _formatDate(context, order.orderDate), scale),
          SizedBox(height: 4 * scale),
          _buildInfoRow(context.loc.status, order.status.name, scale),
          SizedBox(height: 4 * scale),
          _buildInfoRow(context.loc.totalAmount, order.totalAmount, scale),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    // You can localize the date format if needed
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildInfoRow(String label, String value, double scale) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60 * scale,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11 * scale,
              color: const Color(0xFF939393),
              fontFamily: 'Roboto',
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11 * scale,
              fontWeight: FontWeight.w500,
              fontFamily: 'Roboto',
            ),
          ),
        ),
      ],
    );
  }
}
