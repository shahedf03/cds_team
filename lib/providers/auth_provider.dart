import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../core/storage/session_store.dart';
import '../core/storage/token_store.dart';
import '../models/auth/auth_user.dart';
import '../services/auth_service.dart';
import '../services/push_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Owns the session: JWT in secure storage, user row in app state.
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthService service,
    required TokenStore tokenStore,
    required SessionStore sessionStore,
    required PushService push,
  }) : _service = service,
       _tokenStore = tokenStore,
       _sessionStore = sessionStore,
       _push = push;

  final AuthService _service;
  final TokenStore _tokenStore;
  final SessionStore _sessionStore;
  final PushService _push;

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
      // The server pushes to whatever id this login carries, so prefer the
      // live OneSignal id (waiting briefly on a fresh install) over "0".
      final String? liveId = await _push.subscriptionId();
      if (liveId != null) await _sessionStore.savePlayerId(liveId);
      final String playerId = liveId ?? await _sessionStore.readPlayerId();
      final LoginResult result = await _service.login(
        username: username.trim(),
        password: password,
        playerId: playerId,
      );

      await _tokenStore.write(result.token);
      await _sessionStore.saveUser(result.user);

      _user = result.user;
      _status = AuthStatus.authenticated;
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

  /// User-initiated sign out.
  Future<void> logout() => _endSession();

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
