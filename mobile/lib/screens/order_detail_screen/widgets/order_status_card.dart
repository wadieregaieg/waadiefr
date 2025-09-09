import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/order.dart';
import '../../../models/order_status.dart';
import '../../../extensions/localized_context.dart';
import '../extensions/order_extensions.dart';

class OrderStatusCard extends StatelessWidget {
  final Order order;
  final double scale;

  const OrderStatusCard({
    Key? key,
    required this.order,
    required this.scale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusMessages = {
      OrderStatus.pending: context.loc.orderConfirmed,
      OrderStatus.processing: context.loc.orderPacked,
      OrderStatus.out_for_delivery: context.loc.outForDelivery,
      OrderStatus.delivered: context.loc.delivered,
      OrderStatus.completed: context.loc.completed,
      OrderStatus.cancelled: context.loc.orderStatusUpdated,
      OrderStatus.returned: context.loc.orderStatusUpdated,
    };

    final statusIconData = {
      OrderStatus.pending: Icons.pending_actions,
      OrderStatus.processing: Icons.inventory,
      OrderStatus.out_for_delivery: Icons.local_shipping,
      OrderStatus.delivered: Icons.check_circle,
      OrderStatus.completed: Icons.verified,
      OrderStatus.cancelled: Icons.cancel,
      OrderStatus.returned: Icons.assignment_return,
    };

    return Container(
      margin: EdgeInsets.all(16 * scale),
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
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                color: order.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12 * scale),
              ),
              child: Icon(
                statusIconData[order.status] ?? Icons.help_outline,
                color: order.statusColor,
                size: 30 * scale,
              ),
            ),
            SizedBox(width: 16 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusMessages[order.status] ?? order.status.name,
                    style: TextStyle(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    '${context.loc.status}: ${order.statusDisplay ?? order.status.name}',
                    style: TextStyle(
                      fontSize: 14 * scale,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  if (order.updatedAt != null)
                    Text(
                      'Updated: ${DateFormat('MMM dd, yyyy').format(order.updatedAt!)}',
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
