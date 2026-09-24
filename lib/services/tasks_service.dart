import '../core/network/api_client.dart';
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
}
