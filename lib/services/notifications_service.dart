import '../core/network/api_client.dart';
import '../models/app_notification.dart';

/// §7 — `GET /api/notifications?userId=&autoId=` (replaces `op=11`).
class NotificationsService {
  NotificationsService(this._api);

  final ApiClient _api;

  /// [autoId] is the "since this id" cursor for incremental polling; pass the
  /// last-seen id, or `"0"` for a full fetch.
  Future<List<AppNotification>> list({
    required String userId,
    String autoId = '0',
  }) async {
    final List<Map<String, dynamic>> rows = await _api.getList(
      '/api/notifications',
      query: <String, dynamic>{'userId': userId, 'autoId': autoId},
    );
    return rows.map(AppNotification.fromJson).toList()
      ..sort(
        (AppNotification a, AppNotification b) =>
            b.autoIdValue.compareTo(a.autoIdValue),
      );
  }
}
