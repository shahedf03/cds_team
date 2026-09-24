import '../core/utils/api_formats.dart';

/// Body for `POST /api/attendance/mobile-check-in` (§10).
///
/// Nothing biometric is ever transmitted — only the boolean result of the
/// on-device match, plus GPS, a timestamp and the per-install device id.
/// Never add a fingerprint image or template to this payload.
class MobileCheckInRequest {
  const MobileCheckInRequest({
    required this.userId,
    required this.deviceId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.biometricVerified,
  });

  final String userId;
  final String deviceId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final bool biometricVerified;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'userId': userId,
    'deviceId': deviceId,
    'timestamp': ApiFormats.toIsoUtc(timestamp),
    'latitude': latitude,
    'longitude': longitude,
    'biometricVerified': biometricVerified,
  };
}

/// `{ "checkInId": 42, "withinGeofence": true, "siteName": "Main Office" }`
class MobileCheckInResult {
  const MobileCheckInResult({
    required this.withinGeofence,
    this.checkInId,
    this.siteName,
  });

  final bool? withinGeofence;
  final int? checkInId;
  final String? siteName;

  factory MobileCheckInResult.fromJson(Map<String, dynamic> json) =>
      MobileCheckInResult(
        withinGeofence: Json.boolOrNull(json['withinGeofence']),
        checkInId: json['checkInId'] == null
            ? null
            : Json.intVal(json['checkInId']),
        siteName: Json.strOrNull(json['siteName']),
      );
}

/// Body for `POST /api/attendance/mobile-check-out`.
class MobileCheckOutRequest {
  const MobileCheckOutRequest({
    required this.userId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
  });

  final String userId;
  final DateTime timestamp;
  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'userId': userId,
    'timestamp': ApiFormats.toIsoUtc(timestamp),
    'latitude': latitude,
    'longitude': longitude,
  };
}

/// `GET /api/attendance/today` — drives the live "checked in since…" timer.
class TodaySession {
  const TodaySession({
    required this.hasOpenSession,
    required this.elapsedMinutes,
    this.checkInAt,
    this.siteName,
    this.withinGeofence,
  });

  final bool hasOpenSession;
  final DateTime? checkInAt;
  final String? siteName;
  final bool? withinGeofence;
  final int elapsedMinutes;

  factory TodaySession.fromJson(Map<String, dynamic> json) => TodaySession(
    hasOpenSession: Json.boolOrNull(json['hasOpenSession']) ?? false,
    checkInAt: Json.date(json['checkInAt'])?.toLocal(),
    siteName: Json.strOrNull(json['siteName']),
    withinGeofence: Json.boolOrNull(json['withinGeofence']),
    elapsedMinutes: Json.intVal(json['elapsedMinutes']),
  );

  static const TodaySession none = TodaySession(
    hasOpenSession: false,
    elapsedMinutes: 0,
  );
}

/// What the Home screen shows after a check-in/out attempt.
enum CheckInStatus {
  /// Nothing tried yet this session.
  idle,

  /// Fingerprint prompt / GPS / network call in flight.
  working,

  /// Backend accepted the check-in.
  success,

  /// Backend accepted the check-out.
  checkedOut,

  /// Anything genuinely wrong (denied biometrics, GPS off, 4xx/5xx).
  failed,
}
