import 'package:flutter/material.dart';

class ProductTitleAndPrice extends StatelessWidget {
  final String name;
  final double pricePerKg;
  final double scale;

  const ProductTitleAndPrice({
    Key? key,
    required this.name,
    required this.pricePerKg,
    required this.scale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 24 * scale,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '${pricePerKg.toStringAsFixed(2)} TND/kg',
          style: TextStyle(
            fontSize: 18 * scale,
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
