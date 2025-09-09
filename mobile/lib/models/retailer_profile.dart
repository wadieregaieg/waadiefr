class Company {
  final int id;
  final String name;
  final String contactNumber;
  final String address;

  Company({
    required this.id,
    required this.name,
    required this.contactNumber,
    required this.address,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as int,
      name: json['name'] as String,
      contactNumber: json['contact_number'] as String,
      address: json['address'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'contact_number': contactNumber,
      'address': address,
    };
  }
}

class RetailerProfile {
  final int? id;
  final int? user;
  final String? username;
  final String companyName;
  final String contactNumber;
  final String address;
  final List<Company>? companies;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RetailerProfile({
    this.id,
    this.user,
    this.username,
    required this.companyName,
    required this.contactNumber,
    required this.address,
    this.companies,
    this.createdAt,
    this.updatedAt,
  });

  factory RetailerProfile.fromJson(Map<String, dynamic> json) {
    return RetailerProfile(
      id: json['id'] as int?,
      user: json['user'] as int?,
      username: json['username'] as String?,
      companyName: json['company_name'] as String? ?? '',
      contactNumber: json['contact_number'] as String? ?? '',
      address: json['address'] as String? ?? '',
      companies: json['companies'] != null
          ? (json['companies'] as List<dynamic>)
              .map((company) =>
                  Company.fromJson(company as Map<String, dynamic>))
              .toList()
          : null,
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
      'id': id,
      'user': user,
      'username': username,
      'company_name': companyName,
      'contact_number': contactNumber,
      'address': address,
      'companies': companies?.map((company) => company.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'company_name': companyName,
      'contact_number': contactNumber,
      'address': address,
      // Note: user field is handled by the backend based on authentication
    };
  }

  RetailerProfile copyWith({
    int? id,
    int? user,
    String? username,
    String? companyName,
    String? contactNumber,
    String? address,
    List<Company>? companies,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RetailerProfile(
      id: id ?? this.id,
      user: user ?? this.user,
      username: username ?? this.username,
      companyName: companyName ?? this.companyName,
      contactNumber: contactNumber ?? this.contactNumber,
      address: address ?? this.address,
      companies: companies ?? this.companies,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'RetailerProfile{id: $id, user: $user, username: $username, companyName: $companyName, contactNumber: $contactNumber, address: $address}';
  }
}
