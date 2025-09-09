class Product {
  final String id;
  final String name;
  final double price;
  final String? image; // Nullable image field
  final double stockQuantity; // Renamed to match Django model
  final String description;
  final int category; // Updated to use ProductCategory object
  final String sku;
  final String? supplier; // Nullable supplier field
  final String? unit; // Unit of measurement (e.g., "kg", "piece", "liter")

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.image,
    required this.stockQuantity,
    required this.description,
    required this.category,
    required this.sku,
    this.supplier,
    this.unit,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Unknown',
      price: json['price'] is double
          ? json['price'] as double
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      image: json['image'] as String?,
      stockQuantity:
          double.tryParse(json['stock_quantity']?.toString() ?? '0') ?? 0,
      description: json['description'] as String? ?? 'No description available',
      category: json['category'] as int? ?? 0,
      sku: json['sku'] as String? ?? 'N/A',
      supplier: json['supplier'] as String?,
      unit: json['unit'] as String?,
    );
  }
  factory Product.fromOrderResJson(Map<String, dynamic> json) {
    return Product(
      id: json['product_id']?.toString() ?? '0',
      name: json['product_name'] as String? ?? 'Unknown',
      price: json['price'] is double
          ? json['price'] as double
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      image: json['product_image'] as String?,
      stockQuantity: 0, // Stock quantity not available in order response
      description: 'Product from order', // No description in order response
      category: 0, // No category in order response
      sku: 'ORDER_ITEM', // No SKU in order response
      supplier: null, // No supplier in order response
      unit: json['unit'] as String?, // Unit from order response
    );
  }

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? image,
    double? stockQuantity,
    String? description,
    int? category,
    String? sku,
    String? supplier,
    String? unit,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      image: image ?? this.image,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      description: description ?? this.description,
      category: category ?? this.category,
      sku: sku ?? this.sku,
      supplier: supplier ?? this.supplier,
      unit: unit ?? this.unit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image': image,
      'stock_quantity': stockQuantity,
      'description': description,
      'category': category,
      'sku': sku,
      'supplier': supplier,
      if (unit != null) 'unit': unit,
    };
  }
}
