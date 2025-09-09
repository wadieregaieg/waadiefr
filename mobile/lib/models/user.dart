import 'address.dart';

class User {
  final int id;
  final String username;
  final String phoneNumber;
  final String? email;
  final String? firstName;
  final String? lastName;
  final bool phoneVerified;
  final bool isActive;
  final String password;
  final String role;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  List<Address> addresses;
  User({
    required this.id,
    required this.username,
    required this.phoneNumber,
    required this.password,
    this.email,
    this.firstName,
    this.lastName,
    this.phoneVerified = false,
    this.isActive = true,
    this.role = "",
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.addresses = const [],
  });
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String? ?? "",
      phoneNumber: json['phone_number'] as String? ?? "",
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      role: json['role'] as String? ?? "retailer",
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String?,
      password: "",
    );
  }
  String toJson() {
    return {
      'id': id,
      'username': username,
      'phone_number': phoneNumber,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      "phone_verified": phoneVerified,
      'is_active': isActive,
      'role': role,
      'address': address,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'addresses': addresses.map((address) => address.toJson()).toList(),
    }.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'phone_number': phoneNumber,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      "phone_verified": phoneVerified,
      'is_active': isActive,
      'role': role,
      'address': address,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'addresses': addresses.map((address) => address.toMap()).toList(),
    };
  }
}
