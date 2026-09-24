import '../core/utils/api_formats.dart';

/// One row of `GET /api/attendance`.
///
/// `start`/`end` arrive already formatted by the server (`"9:26 AM"`), so they
/// stay strings. `withinGeofence` is reserved for the mobile check-in feature
/// and is `null` for every terminal-based record today.
class AttendanceRecord {
  const AttendanceRecord({
    required this.date,
    required this.start,
    required this.end,
    this.withinGeofence,
  });

  final DateTime? date;
  final String? start;
  final String? end;
  final bool? withinGeofence;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        date: Json.date(json['date']),
        start: Json.strOrNull(json['start']),
        end: Json.strOrNull(json['end']),
        withinGeofence: Json.boolOrNull(json['withinGeofence']),
      );

  String get startLabel => start ?? '—';
  String get endLabel => end ?? '—';

  String get dayNumber =>
      date == null ? '--' : ApiFormats.dayNumber.format(date!);
  String get monthLabel =>
      date == null ? '' : ApiFormats.monthShort.format(date!);

  /// The API does not compute "late" yet, so the rule stays client-side:
  /// a start after 09:00 is late. Unchanged from the old app.
  static const int lateAfterHour = 9;
  static const int lateAfterMinute = 0;

  bool get isLate {
    final DateTime? started = _parseClock(start);
    if (started == null) return false;
    final int startedMinutes = started.hour * 60 + started.minute;
    const int threshold = lateAfterHour * 60 + lateAfterMinute;
    return startedMinutes > threshold;
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
