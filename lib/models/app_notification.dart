import '../core/utils/api_formats.dart';

/// `GET /api/notifications?userId=&autoId=`
class AppNotification {
  const AppNotification({
    required this.autoId,
    required this.notificationsDate,
    required this.title,
    required this.notificationsDescription,
  });

  final String autoId;
  final DateTime? notificationsDate;
  final String title;
  final String notificationsDescription;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        autoId: Json.str(json['autoId']),
        notificationsDate: Json.date(json['notificationsDate']),
        title: Json.str(json['title']),
        notificationsDescription: Json.str(json['notificationsDescription']),
      );

  int get autoIdValue => Json.intVal(autoId);

  String get dateLabel => notificationsDate == null
      ? ''
      : ApiFormats.displayDate.format(notificationsDate!);
}
