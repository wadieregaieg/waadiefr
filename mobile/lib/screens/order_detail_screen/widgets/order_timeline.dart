import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../models/order.dart';
import '../../../models/order_status.dart';
import '../../../extensions/localized_context.dart';
import '../extensions/order_extensions.dart';

class OrderTimeline extends StatelessWidget {
  final Order order;
  final double scale;

  const OrderTimeline({
    Key? key,
    required this.order,
    required this.scale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Order of statuses in the delivery process
    final orderStatuses = [
      OrderStatus.pending,
      OrderStatus.processing,
      OrderStatus.out_for_delivery,
      OrderStatus.delivered,
      OrderStatus.completed,
    ];

    // Get the current status index
    int currentStatusIndex = orderStatuses.indexOf(order.status);

    // If status is cancelled or returned, handle differently
    if (order.status == OrderStatus.cancelled ||
        order.status == OrderStatus.returned) {
      return _buildCancelledOrReturnedStatus(context);
    }

    return _buildNormalTimeline(context, orderStatuses, currentStatusIndex);
  }

  Widget _buildCancelledOrReturnedStatus(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16 * scale),
      padding: EdgeInsets.all(16 * scale),
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
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8 * scale),
            decoration: BoxDecoration(
              color: order.statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8 * scale),
            ),
            child: Icon(
              order.status == OrderStatus.cancelled
                  ? Icons.cancel
                  : Icons.assignment_return,
              color: order.statusColor,
              size: 24 * scale,
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Text(
              order.status == OrderStatus.cancelled
                  ? context.loc.orderCancelled
                  : context.loc.orderReturned,
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.bold,
                color: order.statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalTimeline(BuildContext context,
      List<OrderStatus> orderStatuses, int currentStatusIndex) {
    // Status icons
    final statusIcons = {
      OrderStatus.pending: Icons.check_circle,
      OrderStatus.processing: Icons.inventory,
      OrderStatus.out_for_delivery: Icons.local_shipping,
      OrderStatus.delivered: Icons.home,
      OrderStatus.completed: Icons.verified,
    };

    return Container(
      margin: EdgeInsets.all(16 * scale),
      padding: EdgeInsets.all(16 * scale),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.orderStatus,
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16 * scale),
          Row(
            children: List.generate(orderStatuses.length, (index) {
              // Is this status complete?
              final isComplete = index <= currentStatusIndex;

              // Is this the current status?
              final isCurrent = index == currentStatusIndex;

              return Expanded(
                child: Row(
                  children: [
                    // Left connecting line (except for the first item)
                    if (index > 0)
                      Expanded(
                        child: Container(
                          height: 3 * scale,
                          color: isComplete && index <= currentStatusIndex
                              ? AppColors.primary
                              : Colors.grey.shade200,
                        ),
                      ),

                    // Status circle
                    Container(
                      width: 50 * scale,
                      height: 50 * scale,
                      decoration: BoxDecoration(
                        color: isComplete
                            ? AppColors.primary
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(
                                color: AppColors.primary, width: 4 * scale)
                            : null,
                      ),
                      child: Icon(
                        statusIcons[orderStatuses[index]],
                        color: isComplete ? Colors.white : Colors.grey,
                        size: 24 * scale,
                      ),
                    ),

                    // Right connecting line (except for the last item)
                    if (index < orderStatuses.length - 1)
                      Expanded(
                        child: Container(
                          height: 3 * scale,
                          color: isComplete && index < currentStatusIndex
                              ? AppColors.primary
                              : Colors.grey.shade200,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
