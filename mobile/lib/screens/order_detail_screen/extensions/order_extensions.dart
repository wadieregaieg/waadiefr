import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/order.dart';
import '../../../models/order_status.dart';

/// Extension to add formatted date getters to the Order model.
extension OrderFormatting on Order {
  String get orderDateFormatted {
    // Format: DD-MM-YYYY
    return '${orderDate.day.toString().padLeft(2, '0')}-'
        '${orderDate.month.toString().padLeft(2, '0')}-'
        '${orderDate.year}';
  }

  // Format date in a readable format
  String get readableDate {
    return DateFormat('MMM dd, yyyy').format(orderDate);
  }

  // Get color based on status
  Color get statusColor {
    switch (status) {
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.out_for_delivery:
        return Colors.blue;
      case OrderStatus.processing:
        return Colors.orange;
      case OrderStatus.pending:
        return Colors.amber;
      case OrderStatus.completed:
        return Colors.greenAccent;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.returned:
        return Colors.purple;
    }
  }

  // Get payment status key based on order status
  String getPaymentStatusKey() {
    // For cash on delivery orders, use specific key
    if (paymentMethod?.toLowerCase() == 'cash_on_delivery' ||
        paymentMethod?.toLowerCase() == 'cod') {
      switch (status) {
        case OrderStatus.pending:
        case OrderStatus.processing:
        case OrderStatus.out_for_delivery:
          return 'payOnDelivery';
        case OrderStatus.delivered:
        case OrderStatus.completed:
          return 'completed';
        case OrderStatus.cancelled:
          return 'paymentCancelled';
        case OrderStatus.returned:
          return 'paymentRefunded';
      }
    }

    // For other payment methods, use regular status logic
    switch (status) {
      case OrderStatus.pending:
        return 'awaitingConfirmation';
      case OrderStatus.processing:
        return 'paymentConfirmed';
      case OrderStatus.out_for_delivery:
        return 'paymentConfirmed';
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'paymentCancelled';
      case OrderStatus.returned:
        return 'paymentRefunded';
    }
  }

  // Get payment status color
  Color get paymentStatusColor {
    // For cash on delivery orders, use different color logic
    if (paymentMethod?.toLowerCase() == 'cash_on_delivery' ||
        paymentMethod?.toLowerCase() == 'cod') {
      switch (status) {
        case OrderStatus.pending:
        case OrderStatus.processing:
        case OrderStatus.out_for_delivery:
          return Colors.blue; // Different color for "Pay on Delivery"
        case OrderStatus.delivered:
        case OrderStatus.completed:
          return Colors.green;
        case OrderStatus.cancelled:
          return Colors.red;
        case OrderStatus.returned:
          return Colors.purple;
      }
    }

    // For other payment methods, use regular status logic
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
      case OrderStatus.out_for_delivery:
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.returned:
        return Colors.purple;
    }
  }

  // Get formatted payment method
  String get formattedPaymentMethod {
    if (paymentMethod == null) return 'Not specified';

    switch (paymentMethod!.toLowerCase()) {
      case 'cash_on_delivery':
      case 'cod':
        return 'Cash on Delivery';
      case 'credit_card':
        return 'Credit Card';
      case 'debit_card':
        return 'Debit Card';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'mobile_payment':
        return 'Mobile Payment';
      default:
        return paymentMethod!
            .split('_')
            .map((word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1)
                : word)
            .join(' ');
    }
  }
}
