import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'core/network/api_client.dart';
import 'core/storage/session_store.dart';
import 'core/storage/token_store.dart';
import 'core/theme/app_theme.dart';
import 'providers/attendance_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/leave_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/tasks_provider.dart';
import 'providers/transportation_provider.dart';
import 'routes/app_routes.dart';
import 'services/attendance_service.dart';
import 'services/auth_service.dart';
import 'services/clients_service.dart';
import 'services/device_check_in_service.dart';
import 'services/leave_service.dart';
import 'services/notifications_service.dart';
import 'services/system_codes_service.dart';
import 'services/tasks_service.dart';
import 'services/transportation_service.dart';
import 'views/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const CdsTeamApp());
}

class CdsTeamApp extends StatefulWidget {
  const CdsTeamApp({super.key});

  @override
  State<CdsTeamApp> createState() => _CdsTeamAppState();
}

class _CdsTeamAppState extends State<CdsTeamApp> {
  late final TokenStore _tokenStore;
  late final SessionStore _sessionStore;
  late final ApiClient _api;

  late final AuthProvider _auth;
  late final AttendanceProvider _attendance;
  late final TransportationProvider _transportation;
  late final TasksProvider _tasks;
  late final LeaveProvider _leave;
  late final NotificationsProvider _notifications;

  @override
  void initState() {
    super.initState();

    _tokenStore = TokenStore();
    _sessionStore = SessionStore();
    _api = ApiClient(tokenStore: _tokenStore);

    _auth = AuthProvider(
      service: AuthService(_api),
      tokenStore: _tokenStore,
      sessionStore: _sessionStore,
    );
    _attendance = AttendanceProvider(
      service: AttendanceService(_api),
      device: DeviceCheckInService(),
      sessionStore: _sessionStore,
    );
    _transportation = TransportationProvider(
      service: TransportationService(_api),
      clientsService: ClientsService(_api),
    );
    _tasks = TasksProvider(service: TasksService(_api));
    _leave = LeaveProvider(
      service: LeaveService(_api),
      systemCodesService: SystemCodesService(_api),
    );
    _notifications = NotificationsProvider(
      service: NotificationsService(_api),
      sessionStore: _sessionStore,
    );

    // A 401 anywhere in the app clears the token, wipes every screen's data
    // and drops the user back on login — never a blank or broken screen.
    _api.onUnauthorized = () {
      _attendance.reset();
      _transportation.reset();
      _tasks.reset();
      _leave.reset();
      _notifications.reset();
      _auth.handleUnauthorized();
      AppRoutes.toLogin();
    };
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        ChangeNotifierProvider<AttendanceProvider>.value(value: _attendance),
        ChangeNotifierProvider<TransportationProvider>.value(
          value: _transportation,
        ),
        ChangeNotifierProvider<TasksProvider>.value(value: _tasks),
        ChangeNotifierProvider<LeaveProvider>.value(value: _leave),
        ChangeNotifierProvider<NotificationsProvider>.value(
          value: _notifications,
        ),
      ],
      child: MaterialApp(
        title: 'CDS Team',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        navigatorKey: AppRoutes.navigatorKey,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: const SplashScreen(),
      ),
    );
  }
}
