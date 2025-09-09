class ProductCategory {
  final int id;
  final String name;
  final String description;

  ProductCategory({
    required this.id,
    required this.name,
    required this.description,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
  factory ProductCategory.empty() {
    return ProductCategory(
      id: -1,
      name: '__skeleton__',
      description: '',
    );
  }
}
