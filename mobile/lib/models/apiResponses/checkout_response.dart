import 'package:freshk/models/order_status.dart';

class CheckoutResponse {
  final int id;
  final String orderDate;
  final OrderStatus status;
  final String statusDisplay;
  final String totalAmount;
  final String formattedTotal;
  final int itemCount;

  CheckoutResponse({
    required this.id,
    required this.orderDate,
    required this.status,
    required this.statusDisplay,
    required this.totalAmount,
    required this.formattedTotal,
    required this.itemCount,
  });
  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutResponse(
      id: json['id'],
      orderDate: json['order_date'],
      status: json['status'] != null
          ? OrderStatus.fromString(json['status'])
          : OrderStatus.pending,
      statusDisplay: json['status_display'],
      totalAmount: json['total_amount'],
      formattedTotal: json['formatted_total'],
      itemCount: json['item_count'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_date': orderDate,
      'status': status.name,
      'status_display': statusDisplay,
      'total_amount': totalAmount,
      'formatted_total': formattedTotal,
      'item_count': itemCount,
    };
  }

  CheckoutResponse copyWith({
    int? id,
    String? orderDate,
    OrderStatus? status,
    String? statusDisplay,
    String? totalAmount,
    String? formattedTotal,
    int? itemCount,
  }) {
    return CheckoutResponse(
      id: id ?? this.id,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      statusDisplay: statusDisplay ?? this.statusDisplay,
      totalAmount: totalAmount ?? this.totalAmount,
      formattedTotal: formattedTotal ?? this.formattedTotal,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  @override
  String toString() {
    return 'checkoutResponse{id: $id, orderDate: $orderDate, status: $status, statusDisplay: $statusDisplay, totalAmount: $totalAmount, formattedTotal: $formattedTotal, itemCount: $itemCount}';
  }
}
