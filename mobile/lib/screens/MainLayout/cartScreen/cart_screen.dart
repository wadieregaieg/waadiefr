import 'package:freshk/providers/cart_provider.dart';
import 'package:freshk/screens/MainLayout/cartScreen/widget/cart_content.dart';
import 'package:freshk/screens/MainLayout/cartScreen/widget/empty_cart.dart';
import 'package:flutter/material.dart';
import 'package:freshk/utils/freshk_utils.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  var isSwipeHintShown = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.fetchCart(showLoading: true, context: context);

      // Check if swipe hint should be shown, if on debug mode always show it
      FreshkUtils.isCartSwipeHintShown().then((value) {
        isSwipeHintShown = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        // Show loader only for initial load when cart is empty
        if (cart.isLoading && cart.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return cart.items.isEmpty
            ? EmptyCart()
            : CartContent(
                cart: cart,
                isSwipeHintShown: isSwipeHintShown,
              );
      },
    );
  }
}
