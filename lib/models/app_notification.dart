import '../core/utils/api_formats.dart';

/// `GET /api/notifications?userId=&autoId=`
///
/// `isRead` (added 2026-09-30) is separate from being in the list at all —
/// dismissing (`autoId={id}`/`-1`) removes a row for good, `isRead` just
/// tracks whether the user has seen it. See `POST /api/notifications/read`
/// and `/read-all`.
class AppNotification {
  const AppNotification({
    required this.autoId,
    required this.notificationsDate,
    required this.title,
    required this.notificationsDescription,
    this.isRead = false,
    this.linkType,
    this.linkId,
  });

  final String autoId;
  final DateTime? notificationsDate;
  final String title;
  final String notificationsDescription;
  final bool isRead;

  /// 2026-10-07 — what this row is about and the id it points at (same
  /// values a matching push carries as `type`/`linkId`), so a tap can open
  /// the right screen. `null` on older rows — keep those non-tappable.
  final String? linkType;
  final String? linkId;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        autoId: Json.str(json['autoId']),
        notificationsDate: Json.date(json['notificationsDate']),
        title: Json.str(json['title']),
        notificationsDescription: Json.str(json['notificationsDescription']),
        isRead: Json.boolOrNull(json['isRead']) ?? false,
        linkType: Json.strOrNull(json['linkType']),
        linkId: Json.strOrNull(json['linkId']),
      );

  AppNotification copyWith({bool? isRead}) => AppNotification(
    autoId: autoId,
    notificationsDate: notificationsDate,
    title: title,
    notificationsDescription: notificationsDescription,
    isRead: isRead ?? this.isRead,
    linkType: linkType,
    linkId: linkId,
  );

  bool get isTappable => linkType != null && linkType!.trim().isNotEmpty;

  int get autoIdValue => Json.intVal(autoId);

  String get dateLabel => notificationsDate == null
      ? ''
      : ApiFormats.displayDate.format(notificationsDate!);
}
