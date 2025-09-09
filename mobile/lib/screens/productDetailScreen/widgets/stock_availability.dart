import 'package:freshk/extensions/localized_context.dart';
import 'package:flutter/material.dart';

class StockAvailability extends StatelessWidget {
  final int availableStock;
  final double scale;

  const StockAvailability({
    Key? key,
    required this.availableStock,
    required this.scale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      availableStock > 0
          ? context.loc.availableStock(availableStock.toString())
          : context.loc.outOfStock,
      style: TextStyle(
        fontSize: 16 * scale,
        color: availableStock > 0 ? Colors.green : Colors.red,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
