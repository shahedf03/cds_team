import '../../core/utils/api_formats.dart';

/// Response of `POST /api/auth/login` (minus the token, which never leaves
/// secure storage).
class AuthUser {
  const AuthUser({
    required this.userId,
    required this.userName,
    required this.userPosition,
  });

  final String userId;
  final String userName;
  final String userPosition;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    userId: Json.str(json['userId']),
    userName: Json.str(json['userName']),
    userPosition: Json.str(json['userPosition']),
  );

  String get initials {
    final List<String> parts = userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  String get firstName {
    final String trimmed = userName.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split(RegExp(r'\s+')).first;
  }
}

/// The full login payload — token plus the user row.
class LoginResult {
  const LoginResult({required this.token, required this.user});

  final String token;
  final AuthUser user;

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
    token: Json.str(json['token']),
    user: AuthUser.fromJson(json),
  );
}
