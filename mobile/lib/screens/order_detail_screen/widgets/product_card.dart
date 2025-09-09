import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../models/cart.dart';
import '../../../extensions/localized_context.dart';
import '../../../widgets/base64_product_image.dart';

class ProductCard extends StatelessWidget {
  final CartItem item;
  final double scale;

  const ProductCard({
    Key? key,
    required this.item,
    required this.scale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = item.product.name;
    final qty = item.quantity;
    final unit = item.unit ?? item.product.unit ?? 'kg';

    final priceText = '${item.product.price.toStringAsFixed(2)} TND';

    // Use item total if available, otherwise calculate from product price
    final totalText = () {
      final quantityValue = double.tryParse(qty) ?? 0.0;
      final totalValue = item.product.price * quantityValue;
      return '${totalValue.toStringAsFixed(2)} TND';
    }();

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
        padding: EdgeInsets.all(12 * scale),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(),
            SizedBox(width: 12 * scale),
            Expanded(
              child: _buildProductDetails(context, title, priceText, unit,
                  double.parse(qty).toStringAsFixed(2), totalText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    final imageStr = item.product.image;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8 * scale),
      child: Base64ProductImage(
        imageUrl: imageStr ?? '',
        width: 80 * scale,
        height: 80 * scale,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildProductDetails(
    BuildContext context,
    String title,
    String priceText,
    String unit,
    String qty,
    String totalText,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16 * scale,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4 * scale),
        Text(
          '$priceText/$unit',
          style: TextStyle(
            fontSize: 14 * scale,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 4 * scale),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${context.loc.qty}: $qty$unit',
              style: TextStyle(
                fontSize: 14 * scale,
                color: Colors.grey[700],
              ),
            ),
            Text(
              totalText,
              style: TextStyle(
                fontSize: 15 * scale,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
