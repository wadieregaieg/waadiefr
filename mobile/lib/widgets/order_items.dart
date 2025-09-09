import 'package:freshk/extensions/localized_context.dart';
import 'package:freshk/models/order.dart';
import 'package:freshk/routes.dart';
import 'package:flutter/material.dart';

class OrderItems extends StatelessWidget {
  final Order order;
  final double scale;
  const OrderItems({Key? key, required this.order, required this.scale})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8 * scale),
          child: Text(
            (order.items.length == 1)
                ? '${order.items.length} ${context.loc.item}'
                : '${order.items.length} ${context.loc.items}',
            style: TextStyle(
              fontSize: 10 * scale,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: Colors.black87,
            ),
          ),
        ),
        ...order.items.map((item) {
          final name = item.product.name;
          final qty = item.quantity;
          final price = item.product.price.toStringAsFixed(2);
          final productImage = item.product.image;

          // Calculate total properly: price is already a double, quantity is a string
          final total = () {
            try {
              final quantityValue = double.tryParse(item.quantity) ?? 0.0;
              final priceValue = item.product.price;
              final totalValue = priceValue * quantityValue;
              return '${totalValue.toStringAsFixed(2)} TND';
            } catch (e) {
              debugPrint(
                  'Error calculating total for item ${item.product.name}: $e');
              return '0.00 TND';
            }
          }();

          return _buildOrderItem(
              context, name, qty, price, total, productImage, scale);
        }).toList(),
        SizedBox(height: 16 * scale),
        Center(
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRoutes.orderDetails,
                arguments: order,
              );
            },
            child: Text(
              context.loc.moreDetails,
              style: TextStyle(
                color: const Color(0xFF939393),
                fontSize: 12 * scale,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItem(BuildContext context, String name, String qty,
      String price, String total, String? productImage, double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60 * scale,
            height: 60 * scale,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8 * scale),
              image: productImage != null && productImage.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(productImage),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
          SizedBox(width: 16 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                ),
                SizedBox(height: 8 * scale),
                Text(
                  '${context.loc.price}: $price TND',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: Colors.grey[600],
                    fontFamily: 'Roboto',
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  '${context.loc.quantity}: $qty',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: Colors.grey[600],
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),
          Text(
            total,
            style: TextStyle(
              fontSize: 14 * scale,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: const Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }
}
