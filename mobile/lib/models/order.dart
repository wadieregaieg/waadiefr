import 'package:freshk/models/cart.dart';
import 'package:freshk/models/order_status.dart';

class Order {
  final int id;
  final int? user;
  final String? username;
  final String? retailerName;
  final String? customerName;
  final String? companyName;
  final DateTime orderDate;
  final OrderStatus status;
  final String? statusDisplay;
  final String? paymentMethod;
  final String totalAmount;
  final String? formattedTotal;
  final int? itemCount;
  final String? notes;
  final String? shippingAddress;
  final String? deliveryAddress;
  final DateTime? updatedAt;
  final double? profitMargin;
  final List<CartItem> items;

  Order({
    required this.id,
    this.user,
    this.username,
    this.retailerName,
    this.customerName,
    this.companyName,
    required this.orderDate,
    required this.status,
    this.statusDisplay,
    this.paymentMethod,
    required this.totalAmount,
    this.formattedTotal,
    this.itemCount,
    this.notes,
    this.shippingAddress,
    this.deliveryAddress,
    this.updatedAt,
    this.profitMargin,
    required this.items,
  });

  Order.fromDeafaultValues({
    this.id = 0,
    this.user = 0,
    this.username = '',
    this.retailerName = '',
    this.customerName = '',
    this.companyName = '',
    required this.orderDate,
    this.status = OrderStatus.pending,
    this.statusDisplay,
    this.paymentMethod = '',
    this.totalAmount = '0',
    this.formattedTotal,
    this.itemCount = 0,
    this.notes,
    this.shippingAddress,
    this.deliveryAddress,
    this.updatedAt,
    this.profitMargin,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      user: json['user'],
      username: json['username'],
      retailerName: json['retailer_name'],
      customerName: json['customer_name'],
      companyName: json['company_name'],
      orderDate: json['order_date'] != null
          ? DateTime.parse(json['order_date'])
          : DateTime.now(),
      status: json['status'] != null
          ? OrderStatus.fromString(json['status'])
          : OrderStatus.pending,
      statusDisplay: json['status_display'],
      paymentMethod: json['payment_method'],
      totalAmount: (json['total_amount'] ?? '0').toString(),
      formattedTotal: json['formatted_total'],
      itemCount: json['item_count'],
      notes: json['notes'],
      shippingAddress: json['shipping_address'],
      deliveryAddress: json['delivery_address'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      profitMargin: json['profit_margin']?.toDouble(),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => CartItem.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (user != null) 'user': user,
      if (username != null) 'username': username,
      if (retailerName != null) 'retailer_name': retailerName,
      if (customerName != null) 'customer_name': customerName,
      if (companyName != null) 'company_name': companyName,
      'order_date': orderDate.toIso8601String(),
      'status': status.name,
      if (statusDisplay != null) 'status_display': statusDisplay,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      'total_amount': totalAmount,
      if (formattedTotal != null) 'formatted_total': formattedTotal,
      if (itemCount != null) 'item_count': itemCount,
      if (notes != null) 'notes': notes,
      if (shippingAddress != null) 'shipping_address': shippingAddress,
      if (deliveryAddress != null) 'delivery_address': deliveryAddress,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (profitMargin != null) 'profit_margin': profitMargin,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  Order copyWith({
    int? id,
    int? user,
    String? username,
    String? retailerName,
    String? customerName,
    String? companyName,
    DateTime? orderDate,
    OrderStatus? status,
    String? statusDisplay,
    String? paymentMethod,
    String? totalAmount,
    String? formattedTotal,
    int? itemCount,
    String? notes,
    String? shippingAddress,
    String? deliveryAddress,
    DateTime? updatedAt,
    double? profitMargin,
    List<CartItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      user: user ?? this.user,
      username: username ?? this.username,
      retailerName: retailerName ?? this.retailerName,
      customerName: customerName ?? this.customerName,
      companyName: companyName ?? this.companyName,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      statusDisplay: statusDisplay ?? this.statusDisplay,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      totalAmount: totalAmount ?? this.totalAmount,
      formattedTotal: formattedTotal ?? this.formattedTotal,
      itemCount: itemCount ?? this.itemCount,
      notes: notes ?? this.notes,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      updatedAt: updatedAt ?? this.updatedAt,
      profitMargin: profitMargin ?? this.profitMargin,
      items: items ?? this.items,
    );
  }
}
