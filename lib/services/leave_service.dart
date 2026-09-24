import '../core/network/api_client.dart';
import '../core/utils/api_formats.dart';
import '../models/leave_request.dart';

/// §9 — leave / vacation requests (replaces `op=13/14/15`).
class LeaveService {
  LeaveService(this._api);

  final ApiClient _api;

  /// `GET /api/leave?userId=&fromDate=&toDate=`
  Future<List<LeaveRequest>> list({
    required String userId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final List<Map<String, dynamic>> rows = await _api.getList(
      '/api/leave',
      query: <String, dynamic>{
        'userId': userId,
        'fromDate': ApiFormats.toQueryDate(fromDate),
        'toDate': ApiFormats.toQueryDate(toDate),
      },
    );
    return rows.map(LeaveRequest.fromJson).toList()
      ..sort((LeaveRequest a, LeaveRequest b) {
        final DateTime da = a.from ?? DateTime(1900);
        final DateTime db = b.from ?? DateTime(1900);
        return db.compareTo(da);
      });
  }

  /// `POST /api/leave` — dates must already be `dd-MM-yyyy HH:mm`
  /// (handled by [LeaveCreateRequest.toJson]).
  Future<void> create(LeaveCreateRequest request) =>
      _api.post<dynamic>('/api/leave', data: request.toJson());

  /// `DELETE /api/leave/{transNo}` → 204.
  Future<void> delete(String transNo) =>
      _api.delete<dynamic>('/api/leave/$transNo');

  /// `POST /api/leave/{transNo}/approve` → 204.
  Future<void> approve(String transNo, {required String approvedBy}) =>
      _api.post<dynamic>(
        '/api/leave/$transNo/approve',
        data: <String, dynamic>{'approvedBy': approvedBy},
      );

  /// `POST /api/leave/{transNo}/reject` → 204.
  Future<void> reject(
    String transNo, {
    required String approvedBy,
    required String reason,
  }) => _api.post<dynamic>(
    '/api/leave/$transNo/reject',
    data: <String, dynamic>{'approvedBy': approvedBy, 'reason': reason},
  );

  /// `GET /api/leave/balance?userId=&year=` — empty when no quota is set.
  Future<List<LeaveBalance>> balance({
    required String userId,
    required int year,
  }) async {
    final List<Map<String, dynamic>> rows = await _api.getList(
      '/api/leave/balance',
      query: <String, dynamic>{'userId': userId, 'year': year},
    );
    return rows.map(LeaveBalance.fromJson).toList();
  }

  /// `GET /api/leave/conflicts?userId=&fromDate=&toDate=` — informational
  /// only, never a reason to block a submit.
  Future<List<LeaveConflict>> conflicts({
    required String userId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final List<Map<String, dynamic>> rows = await _api.getList(
      '/api/leave/conflicts',
      query: <String, dynamic>{
        'userId': userId,
        'fromDate': ApiFormats.toQueryDate(fromDate),
        'toDate': ApiFormats.toQueryDate(toDate),
      },
    );
    return rows.map(LeaveConflict.fromJson).toList();
  }

  /// `POST /api/leave/{transNo}/attachment` — the medical report photo.
  Future<void> uploadAttachment(
    String transNo, {
    required String fileBase64,
    required String contentType,
  }) => _api.post<dynamic>(
    '/api/leave/$transNo/attachment',
    data: <String, dynamic>{
      'fileBase64': fileBase64,
      'contentType': contentType,
    },
  );
}
