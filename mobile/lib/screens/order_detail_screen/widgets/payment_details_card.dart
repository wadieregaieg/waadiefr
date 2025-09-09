import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../constants.dart';
import '../../../models/order.dart';
import '../../../models/order_status.dart';
import '../../../extensions/localized_context.dart';
import '../extensions/order_extensions.dart';
import 'package:freshk/utils/freshk_utils.dart';

class PaymentDetailsCard extends StatelessWidget {
  final Order order;
  final double scale;

  const PaymentDetailsCard({
    Key? key,
    required this.order,
    required this.scale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        padding: EdgeInsets.all(16 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPaymentMethod(context),
            SizedBox(height: 12 * scale),
            _buildPaymentStatus(context),
            SizedBox(height: 12 * scale),
            _buildPaymentDate(context),
            SizedBox(height: 12 * scale),
            _buildTrackingNumber(context),
            if (order.status == OrderStatus.cancelled ||
                order.status == OrderStatus.returned) ...[
              SizedBox(height: 12 * scale),
              Divider(color: Colors.grey[300]),
              SizedBox(height: 12 * scale),
              _buildRefundInfo(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.loc.paymentMethod,
          style: TextStyle(
            fontSize: 14 * scale,
            color: Colors.grey[700],
          ),
        ),
        Row(
          children: [
            Icon(
              _getPaymentMethodIcon(order.paymentMethod ?? ''),
              size: 16 * scale,
              color: AppColors.primary,
            ),
            SizedBox(width: 8 * scale),
            Text(
              order.formattedPaymentMethod,
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentStatus(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.loc.paymentStatus,
          style: TextStyle(
            fontSize: 14 * scale,
            color: Colors.grey[700],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12 * scale,
            vertical: 6 * scale,
          ),
          decoration: BoxDecoration(
            color: order.paymentStatusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20 * scale),
          ),
          child: Text(
            _getPaymentStatusText(context),
            style: TextStyle(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w600,
              color: order.paymentStatusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentDate(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Payment Date', // TODO: Add to localization
          style: TextStyle(
            fontSize: 14 * scale,
            color: Colors.grey[700],
          ),
        ),
        Text(
          DateFormat('MMM dd, yyyy').format(order.orderDate),
          style: TextStyle(
            fontSize: 14 * scale,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingNumber(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.loc.trackingNumber,
          style: TextStyle(
            fontSize: 14 * scale,
            color: Colors.grey[700],
          ),
        ),
        Row(
          children: [
            Text(
              'FRK${order.id.toString().padLeft(6, '0')}',
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
            SizedBox(width: 8 * scale),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(
                  text: 'FRK${order.id.toString().padLeft(6, '0')}',
                ));
                FreshkUtils.showInfoSnackbar(context, 'Transaction ID copied');
              },
              child: Icon(
                Icons.content_copy,
                size: 16 * scale,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRefundInfo(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.info_outline,
          size: 16 * scale,
          color: Colors.blue,
        ),
        SizedBox(width: 8 * scale),
        Expanded(
          child: Text(
            order.status == OrderStatus.cancelled
                ? 'Refund will be processed within 3-5 business days' // TODO: Add to localization
                : 'Refund has been processed to your original payment method', // TODO: Add to localization
            style: TextStyle(
              fontSize: 12 * scale,
              color: Colors.blue[700],
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to get payment method icon
  IconData _getPaymentMethodIcon(String paymentMethod) {
    debugPrint('Payment method: $paymentMethod');
    switch (paymentMethod.toLowerCase()) {
      case 'cash_on_delivery':
      case 'cod':
        return Icons.money;
      case 'credit_card':
      case 'debit_card':
        return Icons.credit_card;
      case 'bank_transfer':
        return Icons.account_balance;
      case 'mobile_payment':
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  // Helper method to get localized payment status text
  String _getPaymentStatusText(BuildContext context) {
    // For cash on delivery orders, use specific status
    if (order.paymentMethod?.toLowerCase() == 'cash_on_delivery' ||
        order.paymentMethod?.toLowerCase() == 'cod') {
      switch (order.status) {
        case OrderStatus.pending:
        case OrderStatus.processing:
        case OrderStatus.out_for_delivery:
          return context.loc.payOnDelivery;
        case OrderStatus.delivered:
        case OrderStatus.completed:
          return context.loc.completed;
        case OrderStatus.cancelled:
          return context.loc.paymentCancelled;
        case OrderStatus.returned:
          return context.loc.paymentRefunded;
      }
    }

    // For other payment methods, use regular status logic
    switch (order.status) {
      case OrderStatus.pending:
        return context.loc.awaitingConfirmation;
      case OrderStatus.processing:
      case OrderStatus.out_for_delivery:
        return context.loc.paymentConfirmed;
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return context.loc.completed;
      case OrderStatus.cancelled:
        return context.loc.paymentCancelled;
      case OrderStatus.returned:
        return context.loc.paymentRefunded;
    }
  }
}
