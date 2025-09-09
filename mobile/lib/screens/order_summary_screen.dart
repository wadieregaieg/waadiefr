import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/cart.dart';
import '../models/address.dart';
import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import '../routes.dart';
import '../extensions/localized_context.dart';
import '../widgets/base64_product_image.dart';

class OrderSummaryScreen extends StatefulWidget {
  const OrderSummaryScreen({Key? key}) : super(key: key);

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  // Selected address for this order (can be different from default)
  Address? _selectedOrderAddress;

  void _showAddressSelectionModal() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final addresses = userProvider.currentUser?.addresses ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        snap: true,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.loc.selectDeliveryAddress,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Address List
            Expanded(
              child: addresses.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.loc.noAddressesAvailable,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.loc.pleaseAddAnAddress,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: addresses.length,
                      itemBuilder: (context, index) {
                        final address = addresses[index];
                        final isSelected =
                            _selectedOrderAddress?.id == address.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryLight
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() {
                                  _selectedOrderAddress = address;
                                });
                                Navigator.pop(context);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Selection indicator
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.grey.shade300,
                                          width: 2,
                                        ),
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),

                                    // Address info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  address.streetAddress,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: isSelected
                                                        ? AppColors.primary
                                                        : AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                              if (address.isDefault)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    context.loc.defaultAddress,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color:
                                                          Colors.blue.shade700,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${address.street}, ${address.city}, ${address.state} ${address.postalCode}, ${address.country}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isSelected
                                                  ? AppColors.primary
                                                      .withOpacity(0.8)
                                                  : Colors.grey.shade600,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Add new address button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    final result = await Navigator.pushNamed(
                      context,
                      AppRoutes.addNewAddress,
                    );
                    if (result == true) {
                      // Refresh addresses after adding new one
                      final userProvider =
                          Provider.of<UserProvider>(context, listen: false);
                      await userProvider.getUserAddresses();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: Text(context.loc.addNewAddress),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final addresses = userProvider.currentUser?.addresses ?? [];
    final cartItems = cartProvider.items;

    // Use selected address for this order, or fall back to default address
    final selectedAddress = _selectedOrderAddress ??
        (addresses.isNotEmpty
            ? addresses.firstWhere(
                (addr) => addr.isDefault,
                orElse: () => addresses[0],
              )
            : null);

    // Get cart data
    final double subtotal = cartProvider.total;
    const double deliveryCharge = AppBusinessRules.deliveryCharge;
    const double discount = 0.00;
    final double totalAmount = subtotal + deliveryCharge - discount;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          context.loc.orderSummary,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: cartProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 72, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        context.loc.yourCartIsEmpty,
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.main,
                          (route) => false,
                        ),
                        child: Text(context.loc.shopNow),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order Details
                            Text(
                              context.loc.orderDetails,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Items List
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: ListView.separated(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: cartItems.length,
                                separatorBuilder: (_, __) =>
                                    Divider(color: Colors.grey.shade300),
                                itemBuilder: (context, index) {
                                  final item = cartItems[index];
                                  return _buildOrderItemCard(context, item);
                                },
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Delivery Address Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.loc.deliveryAddress,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _showAddressSelectionModal,
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  label: Text(
                                    selectedAddress == null
                                        ? context.loc.select
                                        : context.loc.change,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: selectedAddress == null
                                        ? Colors.orange
                                        : AppColors.primary,
                                    width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade200,
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: selectedAddress == null
                                        ? Colors.orange
                                        : AppColors.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: selectedAddress == null
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                context.loc.noAddressSelected,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                context
                                                    .loc.addressRequiredMessage,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      selectedAddress
                                                          .streetAddress,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  if (selectedAddress.isDefault)
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .primaryLight,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: Text(
                                                        context
                                                            .loc.defaultAddress,
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              AppColors.primary,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                '${selectedAddress.street}, ${selectedAddress.city}, ${selectedAddress.state} ${selectedAddress.postalCode}, ${selectedAddress.country}',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade700,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Payment Summary Section
                            Text(
                              context.loc.orderInfo,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade100,
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildPriceRow(
                                    context.loc.subTotal,
                                    '${subtotal.toStringAsFixed(2)} TND',
                                  ),
                                  _buildPriceRow(
                                    context.loc.deliveryCharge,
                                    '${deliveryCharge.toStringAsFixed(2)} TND',
                                  ),
                                  _buildPriceRow(
                                    context.loc.discount,
                                    '${discount.toStringAsFixed(2)} TND',
                                  ),
                                  Divider(
                                      color: Colors.grey.shade300, height: 24),
                                  _buildPriceRow(
                                    context.loc.totalAmount,
                                    '${totalAmount.toStringAsFixed(2)} TND',
                                    isTotal: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Continue to Payment Button
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: selectedAddress == null
                              ? null // Disable button if no address is selected
                              : () {
                                  Navigator.pushNamed(
                                      context, AppRoutes.payment);
                                },
                          child: Text(
                            context.loc.continueToPayment,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildOrderItemCard(BuildContext context, CartItem item) {
    final price = item.product.price;
    final quantity = double.tryParse(item.quantity) ?? 0;
    final totalPrice = price * quantity;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Base64ProductImage(
              imageUrl: item.product.image ?? '',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${price.toStringAsFixed(2)} TND/kg',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${context.loc.qty}: ${quantity.toStringAsFixed(1)}kg',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '${totalPrice.toStringAsFixed(2)} TND',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? AppColors.textPrimary : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
