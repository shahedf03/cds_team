import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import '../services/notifications_service.dart';
import 'loadable.dart';

/// §7 — notifications. The server keeps only what the user hasn't
/// dismissed; `isRead` (2026-09-30) tracks the bell badge separately —
/// a read notification stays in the list until swiped away or "مسح الكل".
class NotificationsProvider extends ChangeNotifier with Loadable {
  NotificationsProvider({required NotificationsService service})
    : _service = service;

  final NotificationsService _service;

  List<AppNotification> _items = const <AppNotification>[];

  List<AppNotification> get items => _items;

  /// Badge count = unread rows only (added 2026-09-30). Before that, the
  /// list itself was the unread set — now a read row stays in the list.
  int get unreadCount => _items.where((AppNotification n) => !n.isRead).length;

  bool get hasUnread => unreadCount > 0;

  Future<void> load({required String userId}) => guard(() async {
    _items = await _service.list(userId: userId);
  });

  /// Swipe-to-dismiss. Removed immediately, restored if the call fails.
  Future<bool> dismiss(AppNotification item, {required String userId}) async {
    final List<AppNotification> previous = _items;
    _items = _items
        .where((AppNotification n) => n.autoId != item.autoId)
        .toList(growable: false);
    notifyListeners();

    final bool ok = await guard(() async {
      _items = await _service.dismiss(userId: userId, autoId: item.autoId);
    }, silent: true);
    if (!ok) {
      _items = previous;
      notifyListeners();
    }
    return ok;
  }

  /// "Clear all".
  Future<bool> clearAll({required String userId}) async {
    final List<AppNotification> previous = _items;
    _items = const <AppNotification>[];
    notifyListeners();

    final bool ok = await guard(() async {
      _items = await _service.clearAll(userId: userId);
    }, silent: true);
    if (!ok) {
      _items = previous;
      notifyListeners();
    }
    return ok;
  }

  /// Marks one row read (tapping it, or its matching push). Never removes
  /// it from the list. Optimistic, like [dismiss]/[clearAll].
  Future<bool> markRead(AppNotification item, {required String userId}) async {
    if (item.isRead) return true;
    final List<AppNotification> previous = _items;
    _items = <AppNotification>[
      for (final AppNotification n in _items)
        if (n.autoId == item.autoId) n.copyWith(isRead: true) else n,
    ];
    notifyListeners();

    final bool ok = await guard(() async {
      await _service.markRead(userId: userId, autoId: item.autoId);
    }, silent: true);
    if (!ok) {
      _items = previous;
      notifyListeners();
    }
    return ok;
  }

  /// "تعليم الكل كمقروء" — and what opening the screen does automatically.
  /// Never removes anything from the list.
  Future<bool> markAllRead({required String userId}) async {
    if (!hasUnread) return true;
    final List<AppNotification> previous = _items;
    _items = <AppNotification>[
      for (final AppNotification n in _items) n.copyWith(isRead: true),
    ];
    notifyListeners();

    final bool ok = await guard(() async {
      await _service.markAllRead(userId: userId);
    }, silent: true);
    if (!ok) {
      _items = previous;
      notifyListeners();
    }
    return ok;
  }

  void reset() {
    _items = const <AppNotification>[];
    resetLoadState();
    notifyListeners();
  }
}
