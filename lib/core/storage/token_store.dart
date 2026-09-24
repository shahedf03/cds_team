import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted storage for the JWT. Deliberately NOT SharedPreferences.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  static const String _tokenKey = 'cds_jwt';

  final FlutterSecureStorage _storage;

  /// Cached in memory so the request interceptor stays synchronous-fast.
  String? _cached;

  String? get cachedToken => _cached;

  Future<String?> read() async {
    _cached ??= await _storage.read(key: _tokenKey);
    return _cached;
  }

  Future<void> write(String token) async {
    _cached = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: _tokenKey);
  }
}
