import '../core/utils/api_formats.dart';

/// Which device produced a punch — the `source`/`startSource`/`endSource`
/// values on `GET /api/attendance` (added 2026-09-30).
enum AttendanceSource {
  device,
  mobile;

  /// The exact query-string / JSON value the API uses.
  String get value => this == device ? 'device' : 'mobile';

  static AttendanceSource? fromJson(dynamic value) {
    final String s = Json.str(value).toLowerCase().trim();
    if (s == 'device') return AttendanceSource.device;
    if (s == 'mobile') return AttendanceSource.mobile;
    return null;
  }
}

/// One row of `GET /api/attendance`.
///
/// `start`/`end` arrive already formatted by the server (`"9:26 AM"`), so they
/// stay strings — Amman wall-clock text, display as-is. `startAt`/`endAt` are
/// the same instants as real UTC (`Z`); [Json.utcToLocal] converts them.
/// `withinGeofence` is only set when the punch involved was a phone punch —
/// always `null` for a pure `source=device` row.
class AttendanceRecord {
  const AttendanceRecord({
    required this.date,
    required this.start,
    required this.end,
    this.startAt,
    this.endAt,
    this.startSource,
    this.endSource,
    this.withinGeofence,
    this.isLate = false,
  });

  final DateTime? date;
  final String? start;
  final String? end;

  /// Same instant as [start]/[end], as a `DateTime` (already converted to
  /// local time). `endAt` is `null` with only one punch that day.
  final DateTime? startAt;
  final DateTime? endAt;

  /// `device` or `mobile` — which punch each side of the row came from.
  /// `endSource` is `null` when there's no End yet.
  final AttendanceSource? startSource;
  final AttendanceSource? endSource;

  final bool? withinGeofence;

  /// Set server-side (added 2026-10-05): the row's Start is after the
  /// `Attendance:LateAfter` threshold (8:30 Amman time by default).
  final bool isLate;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        date: Json.date(json['date']),
        start: Json.strOrNull(json['start']),
        end: Json.strOrNull(json['end']),
        startAt: Json.utcToLocal(json['startAt']),
        endAt: Json.utcToLocal(json['endAt']),
        startSource: AttendanceSource.fromJson(json['startSource']),
        endSource: AttendanceSource.fromJson(json['endSource']),
        withinGeofence: Json.boolOrNull(json['withinGeofence']),
        isLate: Json.boolOrNull(json['isLate']) ?? false,
      );

  String get startLabel => start ?? '—';
  String get endLabel => end ?? '—';

  String get dayNumber =>
      date == null ? '--' : ApiFormats.dayNumber.format(date!);
  String get monthLabel =>
      date == null ? '' : ApiFormats.monthShort.format(date!);

  /// The day's first punch (terminal or mobile) as a full local timestamp.
  DateTime? get startedAt => _onDate(start);

  /// The day's last punch as a full local timestamp.
  DateTime? get endedAt => _onDate(end);

  DateTime? _onDate(String? value) {
    final DateTime? day = date;
    final DateTime? clock = _parseClock(value);
    if (day == null || clock == null) return null;
    return DateTime(day.year, day.month, day.day, clock.hour, clock.minute);
  }

  /// Parses the server's `"9:26 AM"` shape into a time-of-day.
  static DateTime? _parseClock(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final RegExpMatch? match = RegExp(
      r'^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([AaPp][Mm])?$',
    ).firstMatch(value.trim());
    if (match == null) return null;

    int hour = int.parse(match.group(1)!);
    final int minute = int.parse(match.group(2)!);
    final String? meridiem = match.group(4)?.toUpperCase();

    if (meridiem == 'PM' && hour != 12) hour += 12;
    if (meridiem == 'AM' && hour == 12) hour = 0;
    if (hour > 23 || minute > 59) return null;

    return DateTime(2000, 1, 1, hour, minute);
  }
}
