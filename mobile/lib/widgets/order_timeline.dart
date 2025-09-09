import 'package:freshk/models/order.dart';
import 'package:freshk/models/order_status.dart';
import 'package:flutter/material.dart';

class OrderTimeline extends StatelessWidget {
  final Order order;
  final double scale;
  const OrderTimeline({Key? key, required this.order, required this.scale})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStep('Confirme', 0, scale),
        _buildCustomDivider(0, scale),
        _buildStep('logistics', 1, scale),
        _buildCustomDivider(1, scale),
        _buildStep('delivery', 2, scale),
        _buildCustomDivider(2, scale),
        _buildStep('check', 3, scale),
      ],
    );
  }

  Widget _buildStep(String type, int stepIndex, double scale) {
    final String iconColorStr = _getIconColor(stepIndex);
    final Color iconColor = _colorFromName(iconColorStr);
    final String iconPath = 'assets/icon/${type}_$iconColorStr.png';
    return Column(
      children: [
        Container(
          height: 20 * scale,
          width: 20 * scale,
          alignment: Alignment.center,
          child: Image.asset(
            iconPath,
            width: 20 * scale,
            height: 20 * scale,
          ),
        ),
        SizedBox(height: 6 * scale),
        Text(
          _getStepLabel(type),
          style: TextStyle(
            fontSize: 11 * scale,
            color: iconColor,
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }

  Widget _buildCustomDivider(int stepIndex, double scale) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double dashWidth = 3 * scale;
          final double dashSpace = 4 * scale;
          final int dashCount =
              (constraints.maxWidth / (dashWidth + dashSpace)).floor();

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (index) {
              return Container(
                width: dashWidth,
                height: 2 * scale,
                color: const Color(0xFFC2C2C2),
              );
            }),
          );
        },
      ),
    );
  }

  String _getIconColor(int stepIndex) {
    // Use the OrderStatus enum from the Order model
    switch (order.status) {
      case OrderStatus.pending:
        return stepIndex == 0 ? 'yellow' : 'grey';
      case OrderStatus.cancelled:
        return stepIndex == 0 ? 'red' : 'grey';
      case OrderStatus.processing:
        return stepIndex <= 1 ? 'green' : 'grey';
      case OrderStatus.out_for_delivery:
        return stepIndex <= 2 ? 'green' : 'grey';
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return 'green';
      case OrderStatus.returned:
        return stepIndex == 0 ? 'red' : 'grey';
    }
    return 'grey';
  }

  Color _colorFromName(String colorName) {
    switch (colorName) {
      case 'green':
        return const Color(0xFF1AB560);
      case 'yellow':
        return const Color(0xFFFFEB3B);
      case 'grey':
        return Colors.grey;
      case 'red':
        return Colors.red;
    }
    return Colors.grey;
  }

  String _getStepLabel(String type) {
    switch (type) {
      case 'Confirme':
        return 'Confirmed';
      case 'logistics':
        return 'Packed';
      case 'delivery':
        return 'Out for Delivery';
      case 'check':
        return 'Delivery';
    }
    return '';
  }
}
