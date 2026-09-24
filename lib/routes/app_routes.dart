import 'package:flutter/material.dart';

import '../models/transportation.dart';
import '../views/screens/attendance_screen.dart';
import '../views/screens/home_shell.dart';
import '../views/screens/leave_screen.dart';
import '../views/screens/login_screen.dart';
import '../views/screens/notifications_screen.dart';
import '../views/screens/profile_screen.dart';
import '../views/screens/tasks_screen.dart';
import '../views/screens/transportation_editor_screen.dart';
import '../views/screens/transportation_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String login = '/login';
  static const String home = '/home';
  static const String attendance = '/attendance';
  static const String tasks = '/tasks';
  static const String profile = '/profile';
  static const String transportation = '/transportation';
  static const String transportationEditor = '/transportation/edit';
  static const String leave = '/leave';
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
        return _slide(const TasksScreen(), settings);
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
