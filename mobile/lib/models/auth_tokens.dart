import 'user.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String? sessionId;
  final User user;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    this.sessionId,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      sessionId: json['session_id'] as String?,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
