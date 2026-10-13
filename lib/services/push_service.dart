import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// What a push is about, read from the message's `data.type`.
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

  /// `task_reminder` (2026-10-08 part A) — someone pressed Remind on a
  /// task you created or are assigned to.
  taskReminder,

  /// `task_chat` (2026-10-08 part C) — a new message on a task's chat; one
  /// per run of unread messages, not one per message.
  taskChat,

  /// `calendar_event` (2026-10-08 part E) — new/changed/starting-soon.
  calendarEvent,

  /// `calendar_cancelled` — nothing to open, the event/invite is gone.
  calendarCancelled,

  unknown;

  static PushKind fromType(Object? value) => switch (value?.toString()) {
    'leave_request' => PushKind.leaveRequest,
    'leave_decision' => PushKind.leaveDecision,
    'task_done' => PushKind.taskDone,
    'task_new' => PushKind.taskNew,
    'leave_forwarded' => PushKind.leaveForwarded,
    'leave_withdrawn' => PushKind.leaveWithdrawn,
    'task_reminder' => PushKind.taskReminder,
    'task_chat' => PushKind.taskChat,
    'calendar_event' => PushKind.calendarEvent,
    'calendar_cancelled' => PushKind.calendarCancelled,
    _ => PushKind.unknown,
  };
}

/// One push/notification tap: its [kind] plus the id it points at. Pushes
/// and notification rows carry the same values under different names —
/// [linkId] on both, with `transNo`/`taskId` as the pre-2026-10-07 fallback
/// on a push's data — so both places route through the same [kind]/[linkId]
/// pair.
class PushEvent {
  const PushEvent(this.kind, this.linkId);

  final PushKind kind;
  final String? linkId;
}

/// Android notification channel every push/local notification posts to.
/// Must match `com.google.firebase.messaging.default_notification_channel_id`
/// in `AndroidManifest.xml`.
const String _androidChannelId = 'cds_team_default';
const String _androidChannelName = 'إشعارات CDS Team';

/// Runs in a background isolate for a push that arrives while the app is
/// backgrounded or killed. The OS already shows the push's own `notification`
/// payload in that case, so there's nothing to do here — this only exists so
/// Firebase doesn't log a missing-handler warning, and leaves room for a
/// future data-only (silent) push.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Firebase Cloud Messaging wrapper (replaces OneSignal — 2026-10-08 part E).
/// The app only hands its own API the FCM token (see `DeviceService`); it
/// never talks to the company's Push Gateway directly.
class PushService {
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _started = false;

  /// Tapped a push (app in background or killed).
  void Function(PushEvent event)? onOpened;

  /// A push arrived while the app is open.
  void Function(PushEvent event)? onForeground;

  /// The FCM token changed (rotation, app reinstall…) — re-register it.
  void Function(String token)? onTokenRefresh;

  /// A tap that arrived before Home was up (cold start, or signed out).
  /// Home consumes it once it's mounted.
  PushEvent? _pending;

  void deferOpen(PushEvent event) => _pending = event;

  PushEvent? takePendingOpen() {
    final PushEvent? event = _pending;
    _pending = null;
    return event;
  }

  /// `"android"` / `"ios"`, as `POST /api/devices` expects.
  String get platform => Platform.isIOS ? 'ios' : 'android';

  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );

      await _initLocalNotifications();

      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      // Android 13+: a no-op on iOS/older Android.
      await _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(
        (RemoteMessage m) => onOpened?.call(_eventOf(m.data)),
      );
      FirebaseMessaging.instance.onTokenRefresh.listen(
        (String token) => onTokenRefresh?.call(token),
      );

      final RemoteMessage? initial = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initial != null) onOpened?.call(_eventOf(initial.data));
    } catch (e) {
      debugPrint('[push] Firebase init failed: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String? payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final Map<String, dynamic> data = Map<String, dynamic>.from(
            jsonDecode(payload) as Map,
          );
          onOpened?.call(_eventOf(data));
        } catch (_) {
          // Malformed/old payload — nothing to open.
        }
      },
    );

    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _androidChannelId,
            _androidChannelName,
            importance: Importance.high,
          ),
        );
  }

  /// Android doesn't show a push's `notification` payload while the app is
  /// in the foreground — show it ourselves, with the original `data` as the
  /// payload so a tap on it can still route like any other push.
  Future<void> _onForegroundMessage(RemoteMessage message) async {
    onForeground?.call(_eventOf(message.data));

    final RemoteNotification? notification = message.notification;
    if (notification == null) return;

    await _local.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannelId,
          _androidChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// The current FCM token, to send as `POST /api/devices`. `null` if it
  /// couldn't be obtained (e.g. push permission denied).
  Future<String?> currentToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('[push] getToken failed: $e');
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      debugPrint('[push] deleteToken failed: $e');
    }
  }

  static PushEvent _eventOf(Map<String, dynamic> data) {
    final String? linkId =
        (data['linkId'] ?? data['transNo'] ?? data['taskId'])?.toString();
    return PushEvent(PushKind.fromType(data['type']), linkId);
  }
}
