import '../core/network/api_client.dart';
import '../models/app_notification.dart';

/// §7 — `GET /api/notifications?userId=&autoId=` (replaces `op=11`).
///
/// `autoId` is **not** a paging cursor: it dismisses. Every call returns
/// the remaining list, newest first.
class NotificationsService {
  NotificationsService(this._api);

  final ApiClient _api;

  /// `-1` in `autoId` hides everything.
  static const String _all = '-1';

  /// The current list.
  Future<List<AppNotification>> list({required String userId}) =>
      _fetch(<String, dynamic>{'userId': userId});

  /// Hides notification [autoId] and returns what's left.
  Future<List<AppNotification>> dismiss({
    required String userId,
    required String autoId,
  }) => _fetch(<String, dynamic>{'userId': userId, 'autoId': autoId});

  /// Hides every notification; the server returns an empty list.
  Future<List<AppNotification>> clearAll({required String userId}) =>
      _fetch(<String, dynamic>{'userId': userId, 'autoId': _all});

  /// `POST /api/notifications/read` — marks one notification read. Never
  /// removes it from the list. A missing/non-numeric `autoId` is a `400`
  /// (use [markAllRead] for everything).
  Future<void> markRead({required String userId, required String autoId}) =>
      _api.post<dynamic>(
        '/api/notifications/read',
        data: <String, dynamic>{'userId': userId, 'autoId': autoId},
      );

  /// `POST /api/notifications/read-all` — marks every notification of this
  /// user read. Never removes anything from the list.
  Future<void> markAllRead({required String userId}) => _api.post<dynamic>(
    '/api/notifications/read-all',
    data: <String, dynamic>{'userId': userId},
  );

  Future<List<AppNotification>> _fetch(Map<String, dynamic> query) async {
    final List<Map<String, dynamic>> rows = await _api.getList(
      '/api/notifications',
      query: query,
    );
    return rows.map(AppNotification.fromJson).toList();
  }
}
