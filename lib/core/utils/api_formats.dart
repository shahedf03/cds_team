import 'package:intl/intl.dart';

/// Date/number shapes the API insists on. Getting these wrong is a 400,
/// so they live in exactly one place.
class ApiFormats {
  const ApiFormats._();

  /// Query-string dates: `fromDate=2026-09-01`.
  static final DateFormat queryDate = DateFormat('yyyy-MM-dd');

  /// Leave create body: `20-09-2026 09:00`. The API parses this EXACT
  /// format and rejects ISO 8601 with a 400.
  static final DateFormat leaveDateTime = DateFormat('dd-MM-yyyy HH:mm');

  /// Display helpers.
  static final DateFormat displayDate = DateFormat('MMM dd, yyyy');
  static final DateFormat dayNumber = DateFormat('dd');
  static final DateFormat monthShort = DateFormat('MMM');
  static final DateFormat clockTime = DateFormat('hh:mm a');

  static String toQueryDate(DateTime date) => queryDate.format(date);

  static String toLeaveDateTime(DateTime value) => leaveDateTime.format(value);

  /// Timestamps for the mobile check-in are sent exactly as captured on the
  /// device, no zone conversion: `2026-09-20T09:15:00`.
  static String toIsoLocal(DateTime value) =>
      value.toIso8601String().split('.').first;

  /// The API returns `fromDateTime` as `dd-MM-yyyy HH:mm` but dates elsewhere
  /// as ISO. Try both before giving up.
  static DateTime? tryParse(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final String raw = value.trim();
    final DateTime? iso = DateTime.tryParse(raw);
    if (iso != null) return iso;
    for (final DateFormat format in <DateFormat>[
      leaveDateTime,
      DateFormat('dd-MM-yyyy'),
      queryDate,
    ]) {
      try {
        return format.parseStrict(raw);
      } catch (_) {
        // try the next shape
      }
    }
    return null;
  }
}

/// The backend mirrors legacy stored procedures, so the same logical field
/// can arrive as a string, an int or null depending on the endpoint.
/// These readers keep `fromJson` boring.
class Json {
  const Json._();

  static String str(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  static String? strOrNull(dynamic value) {
    if (value == null) return null;
    final String s = value is String ? value : value.toString();
    return s.trim().isEmpty ? null : s;
  }

  static int intVal(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim()) ?? fallback;
  }

  static double doubleVal(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim().replaceAll(',', '')) ??
        fallback;
  }

  static bool? boolOrNull(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final String s = value.toString().toLowerCase().trim();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return null;
  }

  static DateTime? date(dynamic value) =>
      ApiFormats.tryParse(value?.toString());

  /// Punch times (`checkInAt`, `lastPunchAt`, `firstPunchAt`, `startAt`,
  /// `endAt`, ...) are real UTC with a trailing `Z` — confirmed consistent
  /// across every endpoint as of the 2026-09-30 API update. Convert to the
  /// device's local time before display; printing the raw UTC digits is
  /// exactly the "punch shows 3 hours early" bug (Amman is UTC+3).
  static DateTime? utcToLocal(dynamic value) => date(value)?.toLocal();

  static List<Map<String, dynamic>> objects(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
