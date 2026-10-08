import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../core/config/app_config.dart';

/// What a push is about, read from `additionalData.type`.
enum PushKind {
  /// `leave_request` — a new request from someone on the manager's team.
  leaveRequest,

  /// `leave_decision` — the employee's own request was approved/rejected.
  leaveDecision,

  /// `task_done` (2026-10-05) — someone moved a task you created to
  /// Done/Delivered.
  taskDone,

  /// `task_new` (2026-10-05) — a task was assigned/reassigned to you.
  taskNew,

  /// `leave_forwarded` (2026-10-07) — to the new approver and the
  /// requester.
  leaveForwarded,

  /// `leave_withdrawn` (2026-10-07) — to the approver; nothing to open,
  /// the request was deleted.
  leaveWithdrawn,

  unknown;

  static PushKind fromType(Object? value) => switch (value?.toString()) {
    'leave_request' => PushKind.leaveRequest,
    'leave_decision' => PushKind.leaveDecision,
    'task_done' => PushKind.taskDone,
    'task_new' => PushKind.taskNew,
    'leave_forwarded' => PushKind.leaveForwarded,
    'leave_withdrawn' => PushKind.leaveWithdrawn,
    _ => PushKind.unknown,
  };
}

/// One push/notification tap: its [kind] plus the id it points at. Pushes
/// and notification rows carry the same values under different names —
/// [linkId] (added 2026-10-07) on both, with `transNo`/`taskId` as the
/// pre-10-07 fallback on a push's `additionalData` — so both places route
/// through the same [kind]/[linkId] pair.
class PushEvent {
  const PushEvent(this.kind, this.linkId);

  final PushKind kind;
  final String? linkId;
}

/// OneSignal wrapper. The server pushes to whatever subscription id was sent
/// as `playerId` on the last login, so the only thing the rest of the app
/// needs from here is that id, plus two hooks: tap and foreground arrival.
class PushService {
  bool _started = false;
  final Completer<String> _firstId = Completer<String>();

  /// Tapped a push (app in background or killed).
  void Function(PushEvent event)? onOpened;

  /// A push arrived while the app is open.
  void Function(PushEvent event)? onForeground;

  bool get isEnabled => AppConfig.oneSignalAppId.isNotEmpty;

  /// A tap that arrived before Home was up (cold start, or signed out).
  /// Home consumes it once it's mounted.
  PushEvent? _pending;

  void deferOpen(PushEvent event) => _pending = event;

  PushEvent? takePendingOpen() {
    final PushEvent? event = _pending;
    _pending = null;
    return event;
  }

  Future<void> start() async {
    if (_started || !isEnabled) return;
    _started = true;

    try {
      await OneSignal.initialize(AppConfig.oneSignalAppId);

      OneSignal.User.pushSubscription.addObserver((
        OSPushSubscriptionChangedState state,
      ) {
        final String? id = state.current.id;
        if (id != null && id.isNotEmpty && !_firstId.isCompleted) {
          _firstId.complete(id);
        }
      });

      OneSignal.Notifications.addClickListener((OSNotificationClickEvent e) {
        onOpened?.call(_eventOf(e.notification));
      });

      OneSignal.Notifications.addForegroundWillDisplayListener((
        OSNotificationWillDisplayEvent e,
      ) {
        // Still show the banner; just let the open screens refresh too.
        onForeground?.call(_eventOf(e.notification));
      });

      await OneSignal.Notifications.requestPermission(true);
    } catch (e) {
      debugPrint('[push] OneSignal init failed: $e');
    }
  }

  /// The subscription id to send as `playerId`. Right after a fresh install
  /// it can still be `null`; wait up to [timeout] for OneSignal to register
  /// rather than logging in with `"0"` and getting no push until next login.
  Future<String?> subscriptionId({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!_started) return null;
    final String? now = OneSignal.User.pushSubscription.id;
    if (now != null && now.isNotEmpty) return now;
    try {
      return await _firstId.future.timeout(timeout);
    } on TimeoutException {
      return null;
    }
  }

  static PushEvent _eventOf(OSNotification notification) {
    final Map<String, dynamic> data =
        notification.additionalData ?? <String, dynamic>{};
    final String? linkId =
        (data['linkId'] ?? data['transNo'] ?? data['taskId'])?.toString();
    return PushEvent(PushKind.fromType(data['type']), linkId);
  }
}
