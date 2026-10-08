import '../core/network/api_client.dart';
import '../core/utils/api_formats.dart';
import '../models/attendance_record.dart';
import '../models/mobile_check_in.dart';

/// §3 attendance history and §10 mobile check-in.
class AttendanceService {
  AttendanceService(this._api);

  final ApiClient _api;

  /// `GET /api/attendance?userId={string}&fromDate=&toDate=&source=device|mobile`
  ///
  /// `userId` is the login name the server hands back (e.g. `"Amani"`), the
  /// same value every other endpoint takes. It used to be coerced to an int
  /// here, which silently sent `userId=0` for every real account and made the
  /// history page come back empty.
  ///
  /// [source]: omit for the merged view (Start = earliest punch of either
  /// kind, End = latest); pass [AttendanceSource.device] or `.mobile` for the
  /// "بصمة الجهاز" / "بصمة الموبايل" tabs — each gets its own Start/End, and a
  /// day with no punch of that kind isn't returned.
  Future<List<AttendanceRecord>> history({
    required String userId,
    required DateTime fromDate,
    required DateTime toDate,
    AttendanceSource? source,
  }) async {
    final List<Map<String, dynamic>> rows = await _api.getList(
      '/api/attendance',
      query: <String, dynamic>{
        'userId': userId,
        'fromDate': ApiFormats.toQueryDate(fromDate),
        'toDate': ApiFormats.toQueryDate(toDate),
        'source': ?source?.value,
      },
    );
    return rows.map(AttendanceRecord.fromJson).toList()
      ..sort((AttendanceRecord a, AttendanceRecord b) {
        final DateTime da = a.date ?? DateTime(1900);
        final DateTime db = b.date ?? DateTime(1900);
        return db.compareTo(da);
      });
  }

  /// `POST /api/attendance/mobile-punch` — one endpoint for in and out, like
  /// the wall terminal: the day's first punch is Start, every later one
  /// moves End. Only error is 400 (fingerprint not verified).
  ///
  /// Replaces `mobile-check-in` / `mobile-check-out`, which the server only
  /// keeps for older installed builds.
  Future<PunchResult> mobilePunch(MobilePunchRequest request) async {
    final dynamic body = await _api.post<dynamic>(
      '/api/attendance/mobile-punch',
      data: request.toJson(),
    );
    if (body is Map) {
      return PunchResult.fromJson(Map<String, dynamic>.from(body));
    }
    return const PunchResult(punchType: PunchType.punchIn);
  }

  /// `GET /api/attendance/today?userId=` — the live session, if any.
  Future<TodaySession> today({required String userId}) async {
    final dynamic body = await _api.get<dynamic>(
      '/api/attendance/today',
      query: <String, dynamic>{'userId': userId},
    );
    if (body is Map) {
      return TodaySession.fromJson(Map<String, dynamic>.from(body));
    }
    return TodaySession.none;
  }

  /// `GET /api/attendance/sites` — geofence reference points, checked
  /// client-side before a punch is allowed to go out. May come back empty.
  Future<List<Site>> sites() async {
    final List<Map<String, dynamic>> rows = await _api.getList(
      '/api/attendance/sites',
    );
    return rows.map(Site.fromJson).toList();
  }
}
