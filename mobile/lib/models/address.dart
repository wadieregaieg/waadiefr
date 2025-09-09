class Address {
  final int? id;
  final String? addressType;
  final String streetAddress;
  final String city;
  final String? state;
  final String postalCode;
  final String country;
  bool isDefault;
  final String? fullAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Address({
    this.id,
    this.addressType,
    required this.streetAddress,
    required this.city,
    this.state,
    required this.postalCode,
    required this.country,
    this.isDefault = false,
    this.fullAddress,
    this.createdAt,
    this.updatedAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as int?,
      addressType: json['address_type'] as String?,
      streetAddress: json['street_address'] as String,
      city: json['city'] as String,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String,
      country: json['country'] as String,
      isDefault: json['is_default'] as bool? ?? false,
      fullAddress: json['full_address'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (addressType != null) 'address_type': addressType,
      'street_address': streetAddress,
      'city': city,
      if (state != null) 'state': state,
      'postal_code': postalCode,
      'country': country,
      'is_default': isDefault,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (addressType != null) 'address_type': addressType,
      'street_address': streetAddress,
      'city': city,
      if (state != null) 'state': state,
      'postal_code': postalCode,
      'country': country,
      'is_default': isDefault,
      if (fullAddress != null) 'full_address': fullAddress,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  // Legacy properties for backward compatibility with existing UI
  String get addressLine1 => streetAddress;
  String? get addressLine2 => null; // Not supported by backend
  String get street => streetAddress;
  String get phone =>
      ''; // This will need to be handled differently or removed from UI

  // Create a copy with updated values
  Address copyWith({
    int? id,
    String? addressType,
    String? streetAddress,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    bool? isDefault,
    String? fullAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      addressType: addressType ?? this.addressType,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
      fullAddress: fullAddress ?? this.fullAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
