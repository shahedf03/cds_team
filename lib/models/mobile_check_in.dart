import '../core/utils/api_formats.dart';

/// `GET /api/attendance/sites` — geofence reference points the phone's GPS
/// is checked against. May be empty until an admin configures real site
/// coordinates; always treat an empty list as "nothing to check against",
/// never as "no site is in range".
class Site {
  const Site({
    required this.siteId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final int siteId;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  factory Site.fromJson(Map<String, dynamic> json) => Site(
    siteId: Json.intVal(json['siteId']),
    name: Json.str(json['name']),
    latitude: Json.doubleVal(json['latitude']),
    longitude: Json.doubleVal(json['longitude']),
    radiusMeters: Json.doubleVal(json['radiusMeters']),
  );
}

/// Body for `POST /api/attendance/mobile-punch` (§10).
///
/// Nothing biometric is ever transmitted — only the boolean result of the
/// on-device match, plus GPS, a timestamp and the per-install device id.
/// Never add a fingerprint image or template to this payload.
class MobilePunchRequest {
  const MobilePunchRequest({
    required this.userId,
    required this.deviceId,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.biometricVerified,
    this.photoBase64,
  });

  final String userId;
  final String deviceId;

  /// When the finger was on the sensor — kept as-is when a queued punch is
  /// sent later, so a late upload still lands at the right time.
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final bool biometricVerified;

  /// Optional selfie; the server keeps it for the day's first punch only.
  final String? photoBase64;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'userId': userId,
    'deviceId': deviceId,
    'timestamp': ApiFormats.toIsoLocal(timestamp),
    'latitude': latitude,
    'longitude': longitude,
    'biometricVerified': biometricVerified,
    'photoBase64': photoBase64,
  };

  /// Reads back a punch parked in the offline queue.
  factory MobilePunchRequest.fromJson(Map<String, dynamic> json) =>
      MobilePunchRequest(
        userId: Json.str(json['userId']),
        deviceId: Json.str(json['deviceId']),
        timestamp: Json.date(json['timestamp']) ?? DateTime.now(),
        latitude: Json.doubleVal(json['latitude']),
        longitude: Json.doubleVal(json['longitude']),
        biometricVerified: Json.boolOrNull(json['biometricVerified']) ?? false,
        photoBase64: Json.strOrNull(json['photoBase64']),
      );
}

/// `In` = the day's first punch (Start); `Out` = any later one (End).
enum PunchType {
  punchIn,
  punchOut;

  static PunchType fromJson(dynamic value) =>
      Json.str(value).toLowerCase() == 'out' ? punchOut : punchIn;
}

/// `{ punchType, recordId, firstPunchAt, lastPunchAt, withinGeofence,
/// siteName }` — times are the device's wall-clock time, read as-is.
class PunchResult {
  const PunchResult({
    required this.punchType,
    this.recordId,
    this.firstPunchAt,
    this.lastPunchAt,
    this.withinGeofence,
    this.siteName,
  });

  final PunchType punchType;
  final int? recordId;
  final DateTime? firstPunchAt;
  final DateTime? lastPunchAt;
  final bool? withinGeofence;
  final String? siteName;

  factory PunchResult.fromJson(Map<String, dynamic> json) => PunchResult(
    punchType: PunchType.fromJson(json['punchType']),
    recordId: json['recordId'] == null ? null : Json.intVal(json['recordId']),
    firstPunchAt: Json.utcToLocal(json['firstPunchAt']),
    lastPunchAt: Json.utcToLocal(json['lastPunchAt']),
    withinGeofence: Json.boolOrNull(json['withinGeofence']),
    siteName: Json.strOrNull(json['siteName']),
  );

  /// The time this punch recorded: Start for `In`, End for `Out`.
  DateTime? get recordedAt =>
      punchType == PunchType.punchIn ? firstPunchAt : lastPunchAt;
}

/// `GET /api/attendance/today` — drives the Home widget.
class TodaySession {
  const TodaySession({
    required this.hasPunchedToday,
    required this.hasOpenSession,
    required this.elapsedMinutes,
    this.checkInAt,
    this.lastPunchAt,
    this.siteName,
    this.withinGeofence,
    this.isLate = false,
  });

  /// Any punch today.
  final bool hasPunchedToday;

  /// Exactly one punch today — Start, no End yet.
  final bool hasOpenSession;

  /// Today's Start, local time.
  final DateTime? checkInAt;

  /// Today's End, local time; `null` until the second punch.
  final DateTime? lastPunchAt;

  final String? siteName;
  final bool? withinGeofence;

  /// Start → End, or Start → now while there's only one punch.
  final int elapsedMinutes;

  /// Server-computed since 2026-10-05: today's first punch is after the
  /// `Attendance:LateAfter` threshold (`false` before any punch).
  final bool isLate;

  /// `checkInAt`/`lastPunchAt` are real UTC with a trailing `Z` on every
  /// endpoint that returns this shape (`/attendance/today` and
  /// `/team/attendance-today` alike, confirmed 2026-09-30) — always convert
  /// with [Json.utcToLocal]. Printing the raw UTC digits is the "punch shows
  /// 3 hours early" bug (Amman is UTC+3).
  factory TodaySession.fromJson(Map<String, dynamic> json) {
    DateTime? clock(dynamic value) => Json.utcToLocal(value);

    final DateTime? checkInAt = clock(json['checkInAt']);
    return TodaySession(
      // Older servers don't send it; any Start means a punch today.
      hasPunchedToday:
          Json.boolOrNull(json['hasPunchedToday']) ?? checkInAt != null,
      hasOpenSession: Json.boolOrNull(json['hasOpenSession']) ?? false,
      checkInAt: checkInAt,
      lastPunchAt: clock(json['lastPunchAt']),
      siteName: Json.strOrNull(json['siteName']),
      withinGeofence: Json.boolOrNull(json['withinGeofence']),
      elapsedMinutes: Json.intVal(json['elapsedMinutes']),
      isLate: Json.boolOrNull(json['isLate']) ?? false,
    );
  }

  static const TodaySession none = TodaySession(
    hasPunchedToday: false,
    hasOpenSession: false,
    elapsedMinutes: 0,
  );
}

/// What the Home card shows after a punch attempt.
enum PunchStatus {
  /// Nothing tried yet this session.
  idle,

  /// Fingerprint prompt / GPS / network call in flight.
  working,

  /// Server accepted the punch.
  success,

  /// Verified but offline — parked in the queue, sent later.
  queued,

  /// Anything genuinely wrong (denied biometrics, GPS off, 4xx/5xx).
  failed,
}
