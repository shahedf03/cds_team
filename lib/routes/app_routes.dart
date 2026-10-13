import 'package:flutter/material.dart';

import '../models/team.dart';
import '../models/transportation.dart';
import '../services/push_service.dart';
import '../views/screens/attendance_screen.dart';
import '../views/screens/calendar_screen.dart';
import '../views/screens/finished_tasks_screen.dart';
import '../views/screens/home_shell.dart';
import '../views/screens/leave_detail_screen.dart';
import '../views/screens/leave_screen.dart';
import '../views/screens/login_screen.dart';
import '../views/screens/member_profile_screen.dart';
import '../views/screens/notifications_screen.dart';
import '../views/screens/profile_screen.dart';
import '../views/screens/projects_screen.dart';
import '../views/screens/tasks_screen.dart';
import '../views/screens/team_leave_screen.dart';
import '../views/screens/transportation_editor_screen.dart';
import '../views/screens/transportation_screen.dart';

/// Where a tapped push or notification row lands — shared by both (2026-10-07:
/// "they hold the same values, so handle both places with one function").
/// `leave_request`/`leave_forwarded`/`leave_decision` open that request's
/// detail; `leave_withdrawn` has nothing to open (the request was deleted),
/// just the team list; `task_done`/`task_new` open that task.
void openPushTarget(PushEvent event) {
  switch (event.kind) {
    case PushKind.leaveRequest:
    case PushKind.leaveForwarded:
    case PushKind.leaveDecision:
      AppRoutes.openLeaveDetail(event.linkId);
    case PushKind.leaveWithdrawn:
      AppRoutes.open(AppRoutes.leaveTeam);
    case PushKind.taskDone:
    case PushKind.taskNew:
    case PushKind.taskReminder:
    case PushKind.taskChat:
      AppRoutes.openTask(event.linkId);
    case PushKind.calendarEvent:
      AppRoutes.open(AppRoutes.calendar);
    case PushKind.calendarCancelled:
    case PushKind.unknown:
      AppRoutes.open(AppRoutes.notifications);
  }
}

class AppRoutes {
  const AppRoutes._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String login = '/login';
  static const String home = '/home';
  static const String attendance = '/attendance';
  static const String tasks = '/tasks';
  /// "منجزة هذا الشهر" — the dashboard's `finishedThisMonth` card.
  static const String tasksFinished = '/tasks/finished';
  static const String projects = '/projects';
  static const String calendar = '/calendar';
  static const String profile = '/profile';
  static const String transportation = '/transportation';
  static const String transportationEditor = '/transportation/edit';
  static const String leave = '/leave';
  static const String leaveTeam = '/leave/team';
  /// One request's detail/timeline; takes its `transNo` (`String`) as
  /// arguments.
  static const String leaveDetail = '/leave/detail';
  /// A team member's read-only profile; takes a [TeamMember] as arguments.
  static const String teamMember = '/team/member';
  static const String notifications = '/notifications';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _fade(const LoginScreen(), settings);
      case home:
        return _fade(const HomeShell(), settings);
      case attendance:
        return _slide(const AttendanceScreen(), settings);
      case tasks:
        return _slide(
          TasksScreen(initialTaskId: settings.arguments as String?),
          settings,
        );
      case tasksFinished:
        return _slide(const FinishedTasksScreen(), settings);
      case projects:
        return _slide(const ProjectsScreen(), settings);
      case calendar:
        return _slide(const CalendarScreen(), settings);
      case profile:
        return _slide(const ProfileScreen(), settings);
      case transportation:
        return _slide(const TransportationScreen(), settings);
      case transportationEditor:
        // Typed `<bool>` on purpose: the editor pops `true` on a successful
        // save and the caller uses `pushNamed<bool>`, which casts whatever
        // this returns to `Route<bool?>`. An untyped `_slide` would build a
        // `PageRouteBuilder<dynamic>` and blow up on that cast.
        return _slide<bool>(
          TransportationEditorScreen(entry: settings.arguments as Transportation?),
          settings,
        );
      case leave:
        return _slide(const LeaveScreen(), settings);
      case leaveTeam:
        return _slide(const TeamLeaveScreen(), settings);
      case leaveDetail:
        final Object? transNo = settings.arguments;
        if (transNo is! String || transNo.isEmpty) return null;
        return _slide(LeaveDetailScreen(transNo: transNo), settings);
      case teamMember:
        final Object? member = settings.arguments;
        if (member is! TeamMember) return null;
        return _slide(MemberProfileScreen(member: member), settings);
      case notifications:
        return _slide(const NotificationsScreen(), settings);
      default:
        return null;
    }
  }

  /// Drops the whole stack and shows login. Safe to call from the 401
  /// interceptor, i.e. from outside any widget's context.
  static void toLogin() {
    final NavigatorState? nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.pushNamedAndRemoveUntil(login, (Route<dynamic> _) => false);
  }

  /// Opens [name] on top of whatever is showing, from outside any widget
  /// (push taps). If that screen is already on top, it isn't stacked twice.
  static void open(String name) {
    final NavigatorState? nav = navigatorKey.currentState;
    if (nav == null) return;
    String? top;
    nav.popUntil((Route<dynamic> route) {
      top = route.settings.name;
      return true;
    });
    if (top == name) return;
    nav.pushNamed(name);
  }

  /// A `task_done`/`task_new` push — opens the Tasks screen with that task's
  /// details sheet, or the plain list when [taskId] is missing (an older
  /// push build).
  static void openTask(String? taskId) {
    final NavigatorState? nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.popUntil((Route<dynamic> route) => route.isFirst);
    nav.pushNamed(tasks, arguments: taskId);
  }

  /// A `leave_request`/`leave_forwarded`/`leave_decision` push or
  /// notification tap — opens that request's detail, or the team inbox when
  /// [transNo] is missing (an older push build, or a dismissed row).
  static void openLeaveDetail(String? transNo) {
    final NavigatorState? nav = navigatorKey.currentState;
    if (nav == null) return;
    if (transNo == null || transNo.isEmpty) {
      open(leaveTeam);
      return;
    }
    nav.popUntil((Route<dynamic> route) => route.isFirst);
    nav.pushNamed(leaveDetail, arguments: transNo);
  }

  static void toHome() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      home,
      (Route<dynamic> _) => false,
    );
  }

  static PageRoute<T> _fade<T>(Widget child, RouteSettings settings) =>
      PageRouteBuilder<T>(
        settings: settings,
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => child,
        transitionsBuilder:
            (_, Animation<double> animation, _, Widget page) =>
                FadeTransition(opacity: animation, child: page),
      );

  static PageRoute<T> _slide<T>(Widget child, RouteSettings settings) =>
      PageRouteBuilder<T>(
        settings: settings,
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, _, _) => child,
        transitionsBuilder:
            (_, Animation<double> animation, _, Widget page) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.06, 0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
                  child: page,
                ),
              );
            },
      );
}
