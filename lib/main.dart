import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'core/network/api_client.dart';
import 'core/storage/session_store.dart';
import 'core/storage/token_store.dart';
import 'core/theme/app_theme.dart';
import 'l10n/gen/app_localizations.dart';
import 'providers/attendance_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/leave_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/tasks_provider.dart';
import 'providers/team_leave_provider.dart';
import 'providers/team_provider.dart';
import 'providers/transportation_provider.dart';
import 'routes/app_routes.dart';
import 'services/attendance_service.dart';
import 'services/auth_service.dart';
import 'services/clients_service.dart';
import 'services/dashboard_service.dart';
import 'services/device_check_in_service.dart';
import 'services/device_service.dart';
import 'services/leave_service.dart';
import 'services/notifications_service.dart';
import 'services/push_service.dart';
import 'services/calendar_service.dart';
import 'services/projects_service.dart';
import 'services/system_codes_service.dart';
import 'services/task_chat_service.dart';
import 'services/team_service.dart';
import 'services/tasks_service.dart';
import 'services/transportation_service.dart';
import 'views/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
  late final DashboardProvider _dashboard;
  late final AttendanceProvider _attendance;
  late final TransportationProvider _transportation;
  late final TasksProvider _tasks;
  late final LeaveProvider _leave;
  late final TeamLeaveProvider _teamLeave;
  late final TeamProvider _team;
  late final NotificationsProvider _notifications;
  late final PushService _push;
  late final DeviceService _device;
  late final LocaleProvider _locale;

  // Also handed to the widget tree: a team member's profile builds its own
  // read-only state on top of them.
  late final AttendanceService _attendanceService;
  late final LeaveService _leaveService;
  late final TasksService _tasksService;
  late final TaskChatService _taskChatService;
  late final ProjectsService _projectsService;
  late final CalendarService _calendarService;
  late final CalendarProvider _calendar;
  late final TransportationService _transportationService;
  late final ClientsService _clientsService;

  @override
  void initState() {
    super.initState();

    _tokenStore = TokenStore();
    _sessionStore = SessionStore();
    _api = ApiClient(tokenStore: _tokenStore);

    _push = PushService();
    _device = DeviceService(_api);
    _locale = LocaleProvider()..load();

    _auth = AuthProvider(
      service: AuthService(_api),
      tokenStore: _tokenStore,
      sessionStore: _sessionStore,
      push: _push,
      device: _device,
    );
    _attendanceService = AttendanceService(_api);
    _leaveService = LeaveService(_api);
    _tasksService = TasksService(_api);
    _taskChatService = TaskChatService(_api);
    _projectsService = ProjectsService(_api);
    _calendarService = CalendarService(_api);
    _calendar = CalendarProvider(service: _calendarService);
    _transportationService = TransportationService(_api);
    _clientsService = ClientsService(_api);

    _dashboard = DashboardProvider(service: DashboardService(_api));
    _attendance = AttendanceProvider(
      service: _attendanceService,
      device: DeviceCheckInService(),
      sessionStore: _sessionStore,
    );
    _transportation = TransportationProvider(
      service: _transportationService,
      clientsService: _clientsService,
    );
    _tasks = TasksProvider(service: _tasksService, chatService: _taskChatService);
    _leave = LeaveProvider(
      service: _leaveService,
      systemCodesService: SystemCodesService(_api),
      clientsService: _clientsService,
    );
    _teamLeave = TeamLeaveProvider(service: _leaveService);
    _team = TeamProvider(service: TeamService(_api));
    _notifications = NotificationsProvider(service: NotificationsService(_api));

    _push
      ..onOpened = _openFromPush
      ..onForeground = _refreshFromPush
      ..onTokenRefresh = _auth.handleTokenRefresh;
    _push.start();

    // A 401 anywhere in the app clears the token, wipes every screen's data
    // and drops the user back on login — never a blank or broken screen.
    _api.onUnauthorized = () {
      _dashboard.reset();
      _attendance.reset();
      _transportation.reset();
      _tasks.reset();
      _leave.reset();
      _teamLeave.reset();
      _team.reset();
      _notifications.reset();
      _calendar.reset();
      _auth.handleUnauthorized();
      AppRoutes.toLogin();
    };
  }

  /// Push tapped. Before sign-in (or before Home is up on a cold start) the
  /// tap is parked and Home picks it up.
  void _openFromPush(PushEvent event) {
    if (!_auth.isAuthenticated || AppRoutes.navigatorKey.currentState == null) {
      _push.deferOpen(event);
      return;
    }
    openPushTarget(event);
  }

  /// Push arrived while the app is open: refresh the badge and whichever
  /// list it concerns.
  void _refreshFromPush(PushEvent event) {
    final String? userId = _auth.user?.userId;
    if (userId == null) return;
    _notifications.load(userId: userId);
    switch (event.kind) {
      case PushKind.leaveRequest:
      case PushKind.leaveWithdrawn:
        _teamLeave.load();
      case PushKind.leaveDecision:
        _leave.load(userId: userId);
      case PushKind.leaveForwarded:
        // Goes to both: the new approver (team inbox) and the requester
        // (their own list) — refresh whichever applies to this user.
        _teamLeave.load();
        _leave.load(userId: userId);
      case PushKind.taskDone:
      case PushKind.taskNew:
      case PushKind.taskReminder:
        _tasks.load(userId: userId);
      case PushKind.taskChat:
        _tasks.refreshChatUnread();
      case PushKind.calendarEvent:
      case PushKind.calendarCancelled:
        _calendar.load();
      case PushKind.unknown:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        ChangeNotifierProvider<DashboardProvider>.value(value: _dashboard),
        ChangeNotifierProvider<AttendanceProvider>.value(value: _attendance),
        ChangeNotifierProvider<TransportationProvider>.value(
          value: _transportation,
        ),
        ChangeNotifierProvider<TasksProvider>.value(value: _tasks),
        ChangeNotifierProvider<LeaveProvider>.value(value: _leave),
        ChangeNotifierProvider<TeamLeaveProvider>.value(value: _teamLeave),
        ChangeNotifierProvider<TeamProvider>.value(value: _team),
        Provider<AttendanceService>.value(value: _attendanceService),
        Provider<LeaveService>.value(value: _leaveService),
        Provider<TasksService>.value(value: _tasksService),
        Provider<TaskChatService>.value(value: _taskChatService),
        Provider<ProjectsService>.value(value: _projectsService),
        Provider<CalendarService>.value(value: _calendarService),
        ChangeNotifierProvider<CalendarProvider>.value(value: _calendar),
        Provider<TransportationService>.value(value: _transportationService),
        Provider<PushService>.value(value: _push),
        ChangeNotifierProvider<NotificationsProvider>.value(
          value: _notifications,
        ),
        ChangeNotifierProvider<LocaleProvider>.value(value: _locale),
      ],
      child: Consumer<LocaleProvider>(
        builder: (BuildContext context, LocaleProvider locale, Widget? _) =>
            MaterialApp(
              title: 'CDS Team',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              navigatorKey: AppRoutes.navigatorKey,
              onGenerateRoute: AppRoutes.onGenerateRoute,
              locale: locale.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const <LocalizationsDelegate<Object?>>[
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              home: const SplashScreen(),
            ),
      ),
    );
  }
}
