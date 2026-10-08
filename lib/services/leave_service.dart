import 'dart:typed_data';

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

  /// `POST /api/leave` → `{ "transNo": "123" }`. Dates must already be
  /// `dd-MM-yyyy HH:mm` (handled by [LeaveCreateRequest.toJson]).
  ///
  /// Returns the new request's id, or `''` if the server didn't send one.
  Future<String> create(LeaveCreateRequest request) async {
    final dynamic body = await _api.post<dynamic>(
      '/api/leave',
      data: request.toJson(),
    );
    return body is Map ? Json.str(body['transNo']) : '';
  }

  /// `DELETE /api/leave/{transNo}` → 204. Since 2026-10-07 this is also the
  /// manager-side withdraw action's endpoint: only your own request, only
  /// while Pending; `400` otherwise.
  Future<void> delete(String transNo) =>
      _api.delete<dynamic>('/api/leave/$transNo');

  /// `GET /api/leave/{transNo}` (2026-10-07) → the request plus its full
  /// `steps` timeline, for the request-detail screen.
  Future<LeaveDetail> detail(String transNo) async {
    final dynamic body = await _api.get<dynamic>('/api/leave/$transNo');
    return LeaveDetail.fromJson(
      body is Map ? Map<String, dynamic>.from(body) : const <String, dynamic>{},
    );
  }

  /// `POST /api/leave/{transNo}/forward` (2026-10-07) `{ "note": "..." }` →
  /// 204. Only with `canDecide` + `canForward`; forwards to the caller's own
  /// `AttendanceParent ?? Parent`.
  Future<void> forward(String transNo, {String? note}) => _api.post<dynamic>(
    '/api/leave/$transNo/forward',
    data: note == null || note.trim().isEmpty
        ? null
        : <String, dynamic>{'note': note.trim()},
  );

  /// `GET /api/leave/team` — requests from everyone in the logged-in user's
  /// team tree, direct and indirect (taken from the token). Each row's
  /// `canDecide` says whether they are the direct manager. Newest first.
  /// Every filter is optional.
  Future<List<LeaveRequest>> team({
    String? approvalStatus,
    LeaveKind? kind,
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final List<Map<String, dynamic>> rows = await _api.getList(
      '/api/leave/team',
      query: <String, dynamic>{
        'approvalStatus': ?approvalStatus,
        'transType': ?kind?.transType,
        'userId': ?userId,
        if (fromDate != null) 'fromDate': ApiFormats.toQueryDate(fromDate),
        if (toDate != null) 'toDate': ApiFormats.toQueryDate(toDate),
      },
    );
    return rows.map(LeaveRequest.fromJson).toList();
  }

  /// `POST /api/leave/{transNo}/approve` → 204. The approver comes from the
  /// token; 403 if they aren't the requester's direct manager, 400 if it was
  /// already decided, 404 if it was deleted.
  Future<void> approve(String transNo) =>
      _api.post<dynamic>('/api/leave/$transNo/approve');

  /// `POST /api/leave/{transNo}/reject` `{ reason }` → 204. Same errors as
  /// [approve].
  Future<void> reject(String transNo, {required String reason}) =>
      _api.post<dynamic>(
        '/api/leave/$transNo/reject',
        data: <String, dynamic>{'reason': reason},
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
  /// `200 { "attachmentId": "7" }`; returns `''` if the server sent none
  /// (an older build), never swallows a non-2xx — that throws [ApiException]
  /// same as every other call here.
  Future<String> uploadAttachment(
    String transNo, {
    required String fileBase64,
    required String contentType,
  }) async {
    final dynamic body = await _api.post<dynamic>(
      '/api/leave/$transNo/attachment',
      data: <String, dynamic>{
        'fileBase64': fileBase64,
        'contentType': contentType,
      },
    );
    return body is Map ? Json.str(body['attachmentId']) : '';
  }

  /// `GET /api/leave/{transNo}/attachments` — same access as the leave
  /// itself (the employee, or anyone above them in the team tree).
  Future<List<LeaveAttachment>> attachments(String transNo) async {
    final List<Map<String, dynamic>> rows = await _api.getList(
      '/api/leave/$transNo/attachments',
    );
    return rows.map(LeaveAttachment.fromJson).toList();
  }

  /// `GET /api/leave/attachments/{id}` — raw file bytes, not JSON.
  Future<Uint8List> attachmentBytes(String id) =>
      _api.getBytes('/api/leave/attachments/$id');
}
