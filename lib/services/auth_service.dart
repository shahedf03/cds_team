import '../core/network/api_client.dart';
import '../models/auth/auth_user.dart';

/// §2 — replaces the old `Home.aspx?op=1` GET that put the password in the URL.
class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  /// `POST /api/auth/login` → 200 with a JWT, or 401 `{ "error": ... }`.
  Future<LoginResult> login({
    required String username,
    required String password,
    String playerId = '0',
  }) async {
    final dynamic body = await _api.post<dynamic>(
      '/api/auth/login',
      data: <String, dynamic>{
        'username': username,
        'password': password,
        'playerId': playerId,
      },
    );
    return LoginResult.fromJson(Map<String, dynamic>.from(body as Map));
  }
}
