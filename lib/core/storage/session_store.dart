import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/auth/auth_user.dart';

/// Non-sensitive session details (name, position, id). The token itself
/// lives in [TokenStore] — never here.
class SessionStore {
  static const String _userId = 'cds_user_id';
  static const String _userName = 'cds_user_name';
  static const String _userPosition = 'cds_user_position';
  static const String _lastNotificationId = 'cds_last_notification_id';
  static const String _playerId = 'cds_player_id';
  static const String _deviceId = 'cds_device_id';

  Future<void> saveUser(AuthUser user) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userId, user.userId);
    await prefs.setString(_userName, user.userName);
    await prefs.setString(_userPosition, user.userPosition);
  }

  Future<AuthUser?> readUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? id = prefs.getString(_userId);
    if (id == null || id.isEmpty) return null;
    return AuthUser(
      userId: id,
      userName: prefs.getString(_userName) ?? '',
      userPosition: prefs.getString(_userPosition) ?? '',
    );
  }

  Future<void> clearUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userId);
    await prefs.remove(_userName);
    await prefs.remove(_userPosition);
    await prefs.remove(_lastNotificationId);
  }

  /// Cursor for incremental notification polling (§7 `autoId`).
  Future<String> readLastNotificationId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastNotificationId) ?? '0';
  }

  Future<void> saveLastNotificationId(String autoId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastNotificationId, autoId);
  }

  /// Stable per-install id sent as `deviceId` on mobile check-in (§10).
  /// Generated once and kept across sign-outs — it identifies the phone,
  /// not the user.
  Future<String> readDeviceId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? existing = prefs.getString(_deviceId);
    if (existing != null && existing.isNotEmpty) return existing;

    final Random random = Random.secure();
    final String generated = List<String>.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await prefs.setString(_deviceId, generated);
    return generated;
  }

  /// Push-notification player id carried over from the legacy `player_id`
  /// param. `"0"` when the device hasn't registered for push yet.
  Future<String> readPlayerId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_playerId) ?? '0';
  }

  Future<void> savePlayerId(String playerId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playerId, playerId);
  }
}
