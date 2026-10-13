import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/auth/auth_user.dart';
import '../utils/api_formats.dart';

/// Non-sensitive session details (name, position, id). The token itself
/// lives in [TokenStore] — never here.
class SessionStore {
  static const String _userId = 'cds_user_id';
  static const String _userName = 'cds_user_name';
  static const String _userPosition = 'cds_user_position';
  // Legacy: the old §7 "since this id" cursor. `autoId` turned out to be a
  // dismiss flag, so the value is no longer read; only cleared on sign-out.
  static const String _lastNotificationId = 'cds_last_notification_id';
  static const String _deviceId = 'cds_device_id';
  static const String _pendingPunches = 'cds_pending_punches';

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

  /// Verified punches that couldn't reach the server (offline), oldest
  /// first, each the JSON body of `mobile-punch`. Kept across sign-outs: a
  /// verified punch is a real attendance event and must not be lost.
  Future<List<Map<String, dynamic>>> readPendingPunches() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_pendingPunches);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      return Json.objects(jsonDecode(raw));
    } on FormatException {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> savePendingPunches(List<Map<String, dynamic>> punches) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (punches.isEmpty) {
      await prefs.remove(_pendingPunches);
    } else {
      await prefs.setString(_pendingPunches, jsonEncode(punches));
    }
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
}
