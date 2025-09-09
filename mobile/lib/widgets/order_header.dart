import 'package:freshk/models/order.dart';
import 'package:flutter/material.dart';
import 'package:freshk/extensions/localized_context.dart';

class OrderHeader extends StatelessWidget {
  final Order order;
  final double scale;
  final bool isCopied;
  final VoidCallback onCopy;
  const OrderHeader({
    Key? key,
    required this.order,
    required this.scale,
    required this.isCopied,
    required this.onCopy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.loc.orderConfirmed,
                  style: TextStyle(
                    fontSize: 11 * scale,
                    color: const Color(0xFF939393),
                    fontFamily: 'Roboto',
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  _formatDate(context, order.orderDate),
                  style: TextStyle(
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),
        ),
        Flexible(
          fit: FlexFit.loose,
          child: Padding(
            padding: EdgeInsets.only(right: 10 * scale),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.loc.orderNumber,
                        style: TextStyle(
                          fontSize: 11 * scale,
                          color: const Color(0xFF939393),
                          fontFamily: 'Roboto',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(width: 4 * scale),
                      GestureDetector(
                        onTap: onCopy,
                        child: Icon(
                          Icons.copy,
                          size: 12 * scale,
                          color: isCopied ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    order.id.toString(),
                    style: TextStyle(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    // You can localize the date format if needed
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
