import 'package:freshk/models/tokens.dart';
import 'package:freshk/models/user.dart';

class OtpVerifyResponse {
  Tokens tokens;
  User user;
  String? error;
  OtpVerifyResponse({
    required this.tokens,
    required this.user,
    this.error,
  });

  factory OtpVerifyResponse.fromJson(Map<String, dynamic> json) {
    return OtpVerifyResponse(
      tokens: Tokens.fromJson(json ?? {}),
      user: User.fromJson(json['user'] ?? {}),
      error: json['error'] as String?,
    );
  }
}
