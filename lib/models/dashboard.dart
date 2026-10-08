import '../core/utils/api_formats.dart';
import 'app_notification.dart';
import 'mobile_check_in.dart';
import 'task_item.dart';

/// `GET /api/dashboard` (2026-10-05) — one call for the whole Home screen.
/// The user comes from the token, so there's no `userId` param.
class DashboardDto {
  const DashboardDto({
    required this.myToday,
    required this.tasksThisMonth,
    required this.openTasks,
    required this.doneTasksThisMonth,
    required this.overdueTasks,
    required this.completionRate,
    required this.recentTasks,
    required this.isManager,
    required this.teamSize,
    required this.presentToday,
    required this.onLeaveToday,
    required this.absentToday,
    required this.attendanceRate,
    required this.pendingApprovals,
    required this.unreadNotifications,
    required this.recentNotifications,
  });

  final TodaySession myToday;

  /// My own tasks only (assigned to me).
  final int tasksThisMonth;
  final int openTasks;
  final int doneTasksThisMonth;
  final int overdueTasks;
  final int completionRate;

  /// My 8 open tasks, nearest deadline first.
  final List<TaskItem> recentTasks;

  /// `false` means every team field below is `0` — hide the manager cards.
  final bool isManager;
  final int teamSize;
  final int presentToday;
  final int onLeaveToday;
  final int absentToday;
  final double attendanceRate;
  final int pendingApprovals;

  final int unreadNotifications;
  final List<AppNotification> recentNotifications;

  factory DashboardDto.fromJson(Map<String, dynamic> json) => DashboardDto(
    myToday: TodaySession.fromJson(_obj(json['myToday'])),
    tasksThisMonth: Json.intVal(json['tasksThisMonth']),
    openTasks: Json.intVal(json['openTasks']),
    doneTasksThisMonth: Json.intVal(json['doneTasksThisMonth']),
    overdueTasks: Json.intVal(json['overdueTasks']),
    completionRate: Json.intVal(json['completionRate']),
    recentTasks: Json.objects(json['recentTasks']).map(TaskItem.fromJson).toList(),
    isManager: Json.boolOrNull(json['isManager']) ?? false,
    teamSize: Json.intVal(json['teamSize']),
    presentToday: Json.intVal(json['presentToday']),
    onLeaveToday: Json.intVal(json['onLeaveToday']),
    absentToday: Json.intVal(json['absentToday']),
    attendanceRate: Json.doubleVal(json['attendanceRate']),
    pendingApprovals: Json.intVal(json['pendingApprovals']),
    unreadNotifications: Json.intVal(json['unreadNotifications']),
    recentNotifications: Json.objects(
      json['recentNotifications'],
    ).map(AppNotification.fromJson).toList(),
  );

  static Map<String, dynamic> _obj(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : const <String, dynamic>{};

  static String hhmm(int? minutes) {
    if (minutes == null) return '00:00';
    final int h = minutes ~/ 60;
    final int m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
