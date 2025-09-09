import 'package:freshk/constants.dart';
import 'package:flutter/material.dart';
import 'package:freshk/extensions/localized_context.dart';

class EmptyCart extends StatelessWidget {
  const EmptyCart({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart, size: 40, color: Colors.grey),
          SizedBox(height: 20),
          Text(
            context.loc.yourCartIsEmpty,
            style: TextStyles.secondaryText,
          ),
        ],
      ),
    );
  }
}
