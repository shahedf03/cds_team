import 'package:flutter/foundation.dart';

import '../core/storage/session_store.dart';
import '../core/utils/api_formats.dart';
import '../models/app_notification.dart';
import '../services/notifications_service.dart';
import 'loadable.dart';

/// §7 — notifications, with the `autoId` cursor preserved across launches.
class NotificationsProvider extends ChangeNotifier with Loadable {
  NotificationsProvider({
    required NotificationsService service,
    required SessionStore sessionStore,
  }) : _service = service,
       _sessionStore = sessionStore;

  final NotificationsService _service;
  final SessionStore _sessionStore;

  List<AppNotification> _items = const <AppNotification>[];
  String _lastSeenId = '0';

  List<AppNotification> get items => _items;

  /// Anything newer than the last id the user actually looked at.
  int get unreadCount {
    final int seen = Json.intVal(_lastSeenId);
    return _items.where((AppNotification n) => n.autoIdValue > seen).length;
  }

  bool get hasUnread => unreadCount > 0;

  /// Full fetch (cursor `0`) — used when opening the notifications screen.
  Future<void> load({required String userId}) => guard(() async {
    _lastSeenId = await _sessionStore.readLastNotificationId();
    _items = await _service.list(userId: userId, autoId: '0');
  });

  /// Incremental poll from the last-seen id, the same way the old endpoint
  /// was called. Merges rather than replaces.
  Future<void> poll({required String userId}) async {
    await guard(() async {
      final String cursor = await _sessionStore.readLastNotificationId();
      final List<AppNotification> fresh = await _service.list(
        userId: userId,
        autoId: cursor,
      );
      if (fresh.isEmpty) return;

      final Set<String> existing = _items
          .map((AppNotification n) => n.autoId)
          .toSet();
      _items = <AppNotification>[
        ...fresh.where((AppNotification n) => !existing.contains(n.autoId)),
        ..._items,
      ]..sort(
        (AppNotification a, AppNotification b) =>
            b.autoIdValue.compareTo(a.autoIdValue),
      );
    }, silent: true);
  }

  /// Advances the cursor once the user has seen the list.
  Future<void> markAllSeen() async {
    if (_items.isEmpty) return;
    final String newest = _items.first.autoId;
    _lastSeenId = newest;
    await _sessionStore.saveLastNotificationId(newest);
    notifyListeners();
  }

  void reset() {
    _items = const <AppNotification>[];
    _lastSeenId = '0';
    resetLoadState();
    notifyListeners();
  }
}
