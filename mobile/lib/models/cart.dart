import 'package:freshk/models/product.dart';

class Cart {
  final int id;
  final String totalAmount;
  final List<CartItem> items;

  Cart({
    required this.id,
    required this.totalAmount,
    required this.items,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'] ?? 0,
      totalAmount: json['total_amount'] ?? '0',
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'total_amount': totalAmount,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class CartItem {
  final int id;
  final Product product;
  final String quantity;
  final String? price;
  final String? formattedPrice;
  final String? unit;
  final double? itemTotal;
  final String? formattedTotal;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    this.price,
    this.formattedPrice,
    this.unit,
    this.itemTotal,
    this.formattedTotal,
  });

  CartItem.defaultValues({
    this.id = 0,
    required this.product,
    this.quantity = '0',
    this.price,
    this.formattedPrice,
    this.unit,
    this.itemTotal,
    this.formattedTotal,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? 0,
      product: json.containsKey('product') && json['product'] != null
          ? Product.fromJson(json['product'])
          : Product.fromOrderResJson(json),
      quantity: (json['quantity'] ?? '0').toString(),
      price: json['price']?.toString(),
      formattedPrice: json['formatted_price'],
      unit: json['unit'],
      itemTotal: json['item_total']?.toDouble(),
      formattedTotal: json['formatted_total'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      if (price != null) 'price': price,
      if (formattedPrice != null) 'formatted_price': formattedPrice,
      if (unit != null) 'unit': unit,
      if (itemTotal != null) 'item_total': itemTotal,
      if (formattedTotal != null) 'formatted_total': formattedTotal,
    };
  }

  CartItem copyWith({
    int? id,
    Product? product,
    String? quantity,
    String? price,
    String? formattedPrice,
    String? unit,
    double? itemTotal,
    String? formattedTotal,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      formattedPrice: formattedPrice ?? this.formattedPrice,
      unit: unit ?? this.unit,
      itemTotal: itemTotal ?? this.itemTotal,
      formattedTotal: formattedTotal ?? this.formattedTotal,
    );
  }
}
