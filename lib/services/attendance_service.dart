import '../core/network/api_client.dart';
import '../core/utils/api_formats.dart';
import '../models/attendance_record.dart';
import '../models/mobile_check_in.dart';

/// §3 attendance history and §10 mobile check-in.
class AttendanceService {
  AttendanceService(this._api);

  final ApiClient _api;

  /// `GET /api/attendance?userId={string}&fromDate=&toDate=`
  ///
  /// `userId` is the login name the server hands back (e.g. `"Amani"`), the
  /// same value every other endpoint takes. It used to be coerced to an int
  /// here, which silently sent `userId=0` for every real account and made the
  /// history page come back empty.
  Future<List<AttendanceRecord>> history({
    required String userId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final List<Map<String, dynamic>> rows = await _api.getList(
      '/api/attendance',
      query: <String, dynamic>{
        'userId': userId,
        'fromDate': ApiFormats.toQueryDate(fromDate),
        'toDate': ApiFormats.toQueryDate(toDate),
      },
    );
    return rows.map(AttendanceRecord.fromJson).toList()
      ..sort((AttendanceRecord a, AttendanceRecord b) {
        final DateTime da = a.date ?? DateTime(1900);
        final DateTime db = b.date ?? DateTime(1900);
        return db.compareTo(da);
      });
  }

  /// `POST /api/attendance/mobile-check-in` → 200 `{ checkInId, withinGeofence,
  /// siteName }`, or 400 (not verified / already checked in).
  Future<MobileCheckInResult> mobileCheckIn(MobileCheckInRequest request) async {
    final dynamic body = await _api.post<dynamic>(
      '/api/attendance/mobile-check-in',
      data: request.toJson(),
    );
    if (body is Map) {
      return MobileCheckInResult.fromJson(Map<String, dynamic>.from(body));
    }
    return const MobileCheckInResult(withinGeofence: null);
  }

  /// `POST /api/attendance/mobile-check-out` → 204, or 400 when there is no
  /// open check-in.
  Future<void> mobileCheckOut(MobileCheckOutRequest request) =>
      _api.post<dynamic>(
        '/api/attendance/mobile-check-out',
        data: request.toJson(),
      );

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
}
