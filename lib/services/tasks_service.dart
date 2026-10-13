import 'dart:typed_data';

import '../core/network/api_client.dart';
import '../core/utils/api_formats.dart';
import '../models/task_item.dart';

/// §6 — `GET /api/tasks` (replaces `op=10`).
class TasksService {
  TasksService(this._api);

  final ApiClient _api;

  Future<List<TaskItem>> list({
    required String userId,
    String? assignUserId,
  }) async {
    final List<Map<String, dynamic>> rows = await _api.getList(
      '/api/tasks',
      query: <String, dynamic>{
        'userId': userId,
        'assignUserId': assignUserId ?? userId,
      },
    );
    return rows.map(TaskItem.fromJson).toList();
  }

  /// `GET /api/tasks/{taskId}/attachments` (2026-10-04) — oldest first.
  /// Anyone who can see the task gets `200`; anyone else `403`, an unknown
  /// id `404`.
  Future<List<TaskAttachment>> attachments(String taskId) async {
    final List<Map<String, dynamic>> rows = await _api.getList(
      '/api/tasks/$taskId/attachments',
    );
    return rows.map(TaskAttachment.fromJson).toList();
  }

  /// `GET /api/tasks/attachments/{id}` — raw file bytes, not JSON.
  Future<Uint8List> attachmentBytes(String id) =>
      _api.getBytes('/api/tasks/attachments/$id');

  /// `GET /api/tasks/lookups` (2026-10-05) — statuses/projects/priorities/
  /// clients, loaded once.
  Future<TaskLookups> lookups() async {
    final dynamic body = await _api.get<dynamic>('/api/tasks/lookups');
    return TaskLookups.fromJson(body is Map ? Map<String, dynamic>.from(body) : const <String, dynamic>{});
  }

  /// `GET /api/tasks/search` (2026-10-05) — every status at once, filtered
  /// locally on the phone by [TaskItem.taskStatus]. Managers/team leaders
  /// get everyone's tasks; anyone else gets their own (or a team member's
  /// via [assignUserId]). Dates filter the created date; the server default
  /// is the last 6 months when omitted.
  Future<List<TaskItem>> search({
    required String userId,
    String? assignUserId,
    String? project,
    String? client,
    String? priority,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final List<Map<String, dynamic>> rows = await _api.getList(
      '/api/tasks/search',
      query: <String, dynamic>{
        'assignUserId': assignUserId ?? userId,
        'project': project ?? '0',
        'client': client ?? '0',
        'priority': priority ?? '0',
        if (fromDate != null) 'fromDate': ApiFormats.toQueryDate(fromDate),
        if (toDate != null) 'toDate': ApiFormats.toQueryDate(toDate),
      },
    );
    return rows.map(TaskItem.fromJson).toList();
  }

  /// `GET /api/tasks/finished` (2026-10-08 part B) — my tasks finished since
  /// the 1st of this month, the list behind the dashboard's "منجزة هذا
  /// الشهر" card. [since] defaults to that card's own count when omitted.
  Future<List<TaskItem>> finished({DateTime? since}) async {
    final List<Map<String, dynamic>> rows = await _api.getList(
      '/api/tasks/finished',
      query: since == null
          ? null
          : <String, dynamic>{'since': ApiFormats.toQueryDate(since)},
    );
    return rows.map(TaskItem.fromJson).toList();
  }

  /// `POST /api/tasks/{taskId}/remind` (2026-10-08 part A, no body) → the
  /// names it was sent to. `400` with a human message when it's closed,
  /// nobody else is on it, or it's too soon since the last reminder.
  Future<List<String>> remind(String taskId) async {
    final dynamic body = await _api.post<dynamic>('/api/tasks/$taskId/remind');
    final dynamic sentTo = body is Map ? body['sentTo'] : null;
    return sentTo is List
        ? sentTo.map((Object? e) => e.toString()).toList()
        : const <String>[];
  }

  /// `PUT /api/tasks/{taskId}/status` `{ "status": 3 }` → 204. `403` when
  /// the caller isn't the creator, the assignee or the assignee's manager;
  /// `400` for an invalid status code; `404` if the task doesn't exist.
  Future<void> updateStatus(String taskId, int status) => _api.put<dynamic>(
    '/api/tasks/$taskId/status',
    data: <String, dynamic>{'status': status},
  );

  /// `DELETE /api/tasks/{taskId}` → 204. `403` for anyone without
  /// [TaskItem.canDelete], `404` if it's already gone.
  Future<void> delete(String taskId) =>
      _api.delete<dynamic>('/api/tasks/$taskId');
}
