import 'package:freshk/providers/order_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';
import '../../routes.dart';
import '../../models/address.dart';
import '../../providers/cart_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/freshk_expections.dart';
import '../../extensions/localized_context.dart';
import '../../utils/freshk_utils.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedMethod;
  bool _isProcessingOrder = false;
  final methodsAvailable = [
    'cash_on_delivery',
    'bank_transfer',
  ];

  @override
  void initState() {
    super.initState();
    // Load user addresses when the payment screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.getUserAddresses().catchError((e) {
        if (mounted) {
          FreshkUtils.showErrorSnackbar(
              context, context.loc.errorLoadingAddresses(e.toString()));
        }
        return <Address>[]; // Return empty list on error
      });
    });
  }

  void _showErrorDialog(String title, String message,
      {String? actionText, VoidCallback? onAction}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.error_outline,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.loc.ok,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (actionText != null && onAction != null)
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onAction();
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  actionText,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Compute scale factor based on a design width of 375.
    final double screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = screenWidth * 0.05;
    final double availableWidth = screenWidth - (2 * horizontalPadding);
    final double scale = availableWidth / 375.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          context.loc.paymentMethods,
          style: TextStyle(fontSize: 20 * scale, color: Colors.black),
        ),
        iconTheme: IconThemeData(color: Colors.black, size: 24 * scale),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0 * scale),
        child: Column(
          children: [
            _buildPaymentOption(
              context.loc.cashOnDelivery,
              context.loc.payWithCashOnDelivery,
              'assets/cash.png',
              'cash_on_delivery',
              scale,
            ),
            _buildPaymentOption(
              context.loc.bankTransfer,
              context.loc.comingSoon,
              'assets/bank.png',
              'bank_transfer',
              scale,
              enabled: false,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.0 * scale),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16 * scale),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12 * scale),
            ),
          ),
          onPressed: _selectedMethod != null && !_isProcessingOrder
              ? () async {
                  setState(() {
                    _isProcessingOrder = true;
                  });

                  // Get the current user from UserProvider.
                  final userProvider =
                      Provider.of<UserProvider>(context, listen: false);
                  final currentUser = userProvider.currentUser;
                  final userId = currentUser?.id ?? -1;
                  if (userId == -1) {
                    // Handle the case where the user is not logged in.
                    FreshkUtils.showErrorSnackbar(
                        context, context.loc.pleaseLogInToProceed);
                    return;
                  }

                  // Get the default address or first available address
                  final addresses = currentUser?.addresses ?? [];
                  final defaultAddress = addresses.isNotEmpty
                      ? addresses.firstWhere(
                          (addr) => addr.isDefault,
                          orElse: () => addresses[0],
                        )
                      : null;

                  if (defaultAddress?.id == null) {
                    FreshkUtils.showErrorSnackbar(
                        context, context.loc.addressRequiredMessage);
                    return;
                  }
                  try {
                    final cart =
                        Provider.of<CartProvider>(context, listen: false);
                    final newOrder = await cart.checkout(
                      addressId: defaultAddress!.id!,
                      paymentMethod: _selectedMethod!,
                    );

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Provider.of<OrderProvider>(context, listen: false)
                          .refreshOrders();
                      Provider.of<CartProvider>(context, listen: false)
                          .refreshCart();
                    });

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.paymentSuccess,
                        (route) => route.settings.name == AppRoutes.main,
                        arguments: newOrder,
                      );
                    });
                  } catch (e) {
                    if (mounted) {
                      // Handle specific checkout errors with appropriate UI responses
                      if (e is EmptyCartException) {
                        _showErrorDialog(
                          context.loc.emptyCart,
                          context.loc.yourCartIsEmptyMessage,
                          actionText: context.loc.shopNow,
                          onAction: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.main,
                              (route) => false,
                            );
                          },
                        );
                      } else if (e is StockException) {
                        _showErrorDialog(
                          context.loc.stockUnavailable,
                          context.loc.stockUnavailableMessage(e.productName,
                              e.availableStock.toString(), e.unit),
                          actionText: context.loc.viewCart,
                          onAction: () {
                            Navigator.pop(context);
                          },
                        );
                      } else if (e is AddressRequiredException) {
                        _showErrorDialog(
                          context.loc.addressRequired,
                          context.loc.addressRequiredMessage,
                          actionText: context.loc.addAddress,
                          onAction: () {
                            Navigator.pushNamed(
                                context, AppRoutes.addressScreen);
                          },
                        );
                      } else if (e is RetailerOnlyException) {
                        _showErrorDialog(
                          context.loc.accessRestricted,
                          context.loc.accessRestrictedMessage,
                        );
                      } else {
                        // Show snackbar for other errors
                        String errorMessage =
                            context.loc.checkoutFailedMessage(e.toString());
                        Color backgroundColor = AppColors.error;
                        IconData icon = Icons.error_outline;

                        if (e is NetworkException) {
                          errorMessage = context.loc.networkError;
                          icon = Icons.wifi_off_outlined;
                        } else if (e is ValidationException) {
                          errorMessage = e.message;
                          icon = Icons.warning_outlined;
                          backgroundColor = Colors.orange;
                        }
                        FreshkUtils.showErrorSnackbar(context, errorMessage);
                      }
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isProcessingOrder = false;
                      });
                    }
                  }
                }
              : null,
          child: _isProcessingOrder
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20 * scale,
                      height: 20 * scale,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12 * scale),
                    Text(
                      context.loc.processing,
                      style:
                          TextStyle(fontSize: 18 * scale, fontFamily: 'Roboto'),
                    ),
                  ],
                )
              : Text(
                  context.loc.placeOrder,
                  style: TextStyle(fontSize: 18 * scale, fontFamily: 'Roboto'),
                ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String title,
    String subtitle,
    String iconPath,
    String methodId,
    double scale, {
    bool enabled = true,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16 * scale),
      color: Colors.white,
      child: ListTile(
        leading: Image.asset(
          iconPath,
          width: 40 * scale,
          height: 40 * scale,
          fit: BoxFit.contain,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: enabled ? Colors.black : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 16 * scale,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 14 * scale),
        ),
        trailing: GestureDetector(
          onTap:
              enabled ? () => setState(() => _selectedMethod = methodId) : null,
          child: Radio<String>(
            value: methodId,
            groupValue: _selectedMethod,
            activeColor: AppColors.primary,
            onChanged: enabled
                ? (value) => setState(() => _selectedMethod = value)
                : null,
          ),
        ),
        enabled: enabled,
      ),
    );
  }
}
