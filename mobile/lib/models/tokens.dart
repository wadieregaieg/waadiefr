class Tokens {
  String refresh;
  String access;

  Tokens({
    required this.refresh,
    required this.access,
  });

  factory Tokens.fromJson(Map<String, dynamic> json) {
    return Tokens(
      refresh: json['refresh'] ?? "",
      access: json['access'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'refresh': refresh,
      'access': access,
    };
  }
}
