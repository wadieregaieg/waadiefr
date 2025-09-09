import 'package:freshk/extensions/localized_context.dart';
import 'package:freshk/models/cart.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import 'widgets/product_image.dart';
import 'widgets/product_title_and_price.dart';
import 'widgets/stock_availability.dart';
import 'package:freshk/utils/freshk_utils.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product})
      : super(key: key);

  @override
  ProductDetailScreenState createState() => ProductDetailScreenState();
}

class ProductDetailScreenState extends State<ProductDetailScreen> {
  late ValueNotifier<int> quantityNotifier;
  late int maxStock;
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    maxStock = widget.product.stockQuantity.toInt();
    quantityNotifier = ValueNotifier<int>(1);
    _quantityController = TextEditingController(text: '1');
    FirebaseAnalytics.instance.logViewItem(
      items: [
        AnalyticsEventItem(
          itemId: widget.product.id,
          itemName: widget.product.name,
          price: widget.product.price,
          currency: 'TND',
        ),
      ],
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    quantityNotifier.dispose();
    super.dispose();
  }

  int _getAvailableStock() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final cartItem = cart.items.firstWhere(
      (item) => item.product.id == widget.product.id,
      orElse: () => CartItem.defaultValues(product: widget.product),
    );
    return maxStock - (double.tryParse(cartItem.quantity) ?? 0).toInt();
  }

  @override
  Widget build(BuildContext context) {
    // Compute a scale factor based on a design width of 375 and 5% horizontal padding.
    const designWidth = 375.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.05;
    final availableWidth = screenWidth - (2 * horizontalPadding);
    final scale = availableWidth / designWidth;

    final availableStock = _getAvailableStock();
    final pricePerKg = widget.product.price;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.product.name,
          style: TextStyle(fontSize: 20 * scale),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ProductImage(
                      imageUrl: widget.product.image,
                      productName: widget.product.name),
                  SizedBox(height: 20 * scale),
                  Padding(
                    padding: EdgeInsets.all(16.0 * scale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProductTitleAndPrice(
                          name: widget.product.name,
                          pricePerKg: pricePerKg,
                          scale: scale,
                        ),
                        SizedBox(height: 10 * scale),
                        StockAvailability(
                          availableStock: availableStock,
                          scale: scale,
                        ),
                        SizedBox(height: 20 * scale),
                        Text(
                          context.loc.description,
                          style: TextStyle(
                            fontSize: 20 * scale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10 * scale),
                        Text(
                          widget.product.description,
                          style: TextStyle(
                            fontSize: 16 * scale,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomControls(context, availableStock, scale),
        ],
      ),
    );
  }

  Widget _buildBottomControls(
      BuildContext context, int availableStock, double scale) {
    return Container(
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20 * scale),
          topRight: Radius.circular(20 * scale),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 10 * scale,
            offset: Offset(0, -5 * scale),
          ),
        ],
      ),
      child: Column(
        children: [
          ValueListenableBuilder<int>(
            valueListenable: quantityNotifier,
            builder: (context, quantity, child) {
              final totalPrice =
                  (quantity * widget.product.price).toStringAsFixed(2);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.loc.total,
                    style: TextStyle(
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$totalPrice TND',
                    style: TextStyle(
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 15 * scale),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  onTap: () => _quantityController.clear(),
                  onChanged: (value) {
                    int newQty = int.tryParse(value) ?? 1;
                    if (newQty < 1) newQty = 1;
                    if (newQty > availableStock) newQty = availableStock;
                    quantityNotifier.value = newQty;
                    _quantityController.value = TextEditingValue(
                      text: newQty.toString(),
                      selection: TextSelection.collapsed(
                        offset: newQty.toString().length,
                      ),
                    );
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4 * scale),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 8 * scale, vertical: 8 * scale),
                    hintText: context.loc.enterQuantityKg,
                    hintStyle: TextStyle(fontSize: 14 * scale),
                    errorText: quantityNotifier.value > availableStock
                        ? 'Stock Out'
                        : null,
                  ),
                ),
              ),
              SizedBox(width: 10 * scale),
              Text('kg', style: TextStyle(fontSize: 16 * scale)),
            ],
          ),
          SizedBox(height: 15 * scale),
          ElevatedButton(
            onPressed: (availableStock > 0 && !Provider.of<CartProvider>(context, listen: false).isProductAddingToCart(widget.product.id))
                ? () async {
                    final cartProvider = context.read<CartProvider>();
                    try {
                      await cartProvider.addItem(
                          widget.product, quantityNotifier.value);
                      FreshkUtils.showSuccessSnackbar(
                          context,
                          context.loc
                              .addedToCartMessage(quantityNotifier.value));
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context, true);
                      }
                    } on Exception catch (e) {
                      FreshkUtils.showErrorSnackbar(
                          context, context.loc.failedToAddToCart(e.toString()));
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: Size(double.infinity, 50 * scale),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10 * scale),
              ),
            ),
            child: Consumer<CartProvider>(
              builder: (context, cartProvider, child) {
                final isAddingToCart = cartProvider.isProductAddingToCart(widget.product.id);
                
                if (isAddingToCart) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Adding to Cart...',
                        style: TextStyle(fontSize: 18 * scale, color: Colors.white),
                      ),
                    ],
                  );
                }
                
                return Text(
                  availableStock > 0
                      ? context.loc.addToCart
                      : context.loc.outOfStock,
                  style: TextStyle(fontSize: 18 * scale, color: Colors.white),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
