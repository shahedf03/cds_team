import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/storage/session_store.dart';
import '../core/storage/token_store.dart';
import '../models/auth/auth_user.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';
import '../services/push_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Owns the session: JWT in secure storage, user row in app state.
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthService service,
    required TokenStore tokenStore,
    required SessionStore sessionStore,
    required PushService push,
    required DeviceService device,
  }) : _service = service,
       _tokenStore = tokenStore,
       _sessionStore = sessionStore,
       _push = push,
       _device = device;

  final AuthService _service;
  final TokenStore _tokenStore;
  final SessionStore _sessionStore;
  final PushService _push;
  final DeviceService _device;

  AuthStatus _status = AuthStatus.unknown;
  AuthUser? _user;
  bool _busy = false;
  String? _error;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  bool get isBusy => _busy;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Restores a previous session on cold start.
  Future<void> bootstrap() async {
    final String? token = await _tokenStore.read();
    final AuthUser? saved = await _sessionStore.readUser();

    if (token != null && token.isNotEmpty && saved != null) {
      _user = saved;
      _status = AuthStatus.authenticated;
      // Cheap upsert: makes sure this install's current token is on file
      // even if it rotated while the app was closed.
      unawaited(_registerDevice());
    } else {
      // A half-restored session is no session.
      await _tokenStore.clear();
      await _sessionStore.clearUser();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      // `playerId` was the OneSignal subscription id; the server ignores it
      // now that push goes through Firebase (2026-10-08 part E), so it's
      // always sent as "0".
      final LoginResult result = await _service.login(
        username: username.trim(),
        password: password,
      );

      await _tokenStore.write(result.token);
      await _sessionStore.saveUser(result.user);

      _user = result.user;
      _status = AuthStatus.authenticated;
      unawaited(_registerDevice());
      return true;
    } on ApiException catch (e) {
      // 401 here means bad credentials — show it inline, never log the body.
      _error = e.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// `POST /api/devices` with this phone's current FCM token, tagged with
  /// the signed-in user's id so the device shows up against them server-side
  /// (same explicit-userId pattern as every other endpoint — see
  /// `DeviceService.register`). Never blocks sign-in on failure (no network,
  /// push permission denied…).
  Future<void> _registerDevice() async {
    try {
      final String? token = await _push.currentToken();
      if (token == null || token.isEmpty) return;
      await _device.register(
        token: token,
        platform: _push.platform,
        userId: _user?.userId,
      );
    } catch (e) {
      debugPrint('[auth] device registration failed: $e');
    }
  }

  /// The FCM token rotated while signed in — keep the server's copy current.
  Future<void> handleTokenRefresh(String token) async {
    if (!isAuthenticated) return;
    try {
      await _device.register(
        token: token,
        platform: _push.platform,
        userId: _user?.userId,
      );
    } catch (e) {
      debugPrint('[auth] device re-registration failed: $e');
    }
  }

  /// User-initiated sign out. Unlinks the device from this user, then
  /// re-registers the same FCM token with no `userId` ("guest" device, same
  /// pattern as the Irbid Mall app) so the phone can still receive broadcast
  /// pushes until someone signs in again.
  Future<void> logout() async {
    final String? token = await _push.currentToken();
    try {
      if (token != null && token.isNotEmpty) await _device.unregister(token);
    } catch (e) {
      debugPrint('[auth] device unregistration failed: $e');
    }

    await _endSession();

    if (token != null && token.isNotEmpty) {
      try {
        await _device.register(token: token, platform: _push.platform);
      } catch (e) {
        debugPrint('[auth] guest re-registration failed: $e');
      }
    }
  }

  /// Called by the 401 interceptor from anywhere in the app.
  Future<void> handleUnauthorized() async {
    if (_status == AuthStatus.unauthenticated) return;
    await _endSession(
      message: 'Your session has expired. Please sign in again.',
    );
  }

  Future<void> _endSession({String? message}) async {
    await _tokenStore.clear();
    await _sessionStore.clearUser();
    _user = null;
    _error = message;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}
