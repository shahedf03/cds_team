import '../core/network/api_client.dart';

/// 2026-10-08 part E — registers/unregisters this phone's Firebase (FCM)
/// token with our own API. The app never talks to the Push Gateway itself;
/// ownership is tagged explicitly via `userId` on [register], not inferred
/// from the JWT.
class DeviceService {
  DeviceService(this._api);

  final ApiClient _api;

  /// After login, and again on every `onTokenRefresh` / app start while
  /// signed in (cheap — it's an upsert). [userId] is sent explicitly, same
  /// as every other endpoint in this app (see e.g. `NotificationsService`) —
  /// the server does not infer it from the JWT on its own, so a `null`
  /// [userId] registers the device without linking it to a user (guest).
  Future<void> register({
    required String token,
    required String platform,
    String? userId,
  }) => _api.post<dynamic>(
    '/api/devices',
    data: <String, dynamic>{
      'token': token,
      'platform': platform,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
    },
  );

  /// On logout, before clearing the JWT. Harmless if another user already
  /// signed in on this phone and took the token over — it just returns 204.
  Future<void> unregister(String token) => _api.post<dynamic>(
    '/api/devices/unregister',
    data: <String, dynamic>{'token': token},
  );
}
