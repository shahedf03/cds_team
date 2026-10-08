import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/leave_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/transportation_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/push_service.dart';
import '../widgets/brand_logo.dart';
import '../widgets/common.dart';
import 'attendance_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'tasks_screen.dart';
import 'team_screen.dart';

/// The bottom-nav destinations. Home/Attendance/Tasks keep indices 0..2, which
/// is what the dashboard's `onOpenTab` links to; [team] is managers-only.
enum _HomeTab {
  home(Icons.home_rounded),
  attendance(Icons.schedule_rounded),
  tasks(Icons.checklist_rounded),
  team(Icons.groups_rounded),
  profile(Icons.person_outline_rounded);

  const _HomeTab(this.icon);

  final IconData icon;

  String label(AppLocalizations t) => switch (this) {
    _HomeTab.home => t.navHome,
    _HomeTab.attendance => t.dashboardAttendance,
    _HomeTab.tasks => t.navTasks,
    _HomeTab.team => t.teamTitle,
    _HomeTab.profile => t.profileTitle,
  };
}

/// Brand bar + bottom navigation wrapper: Home, Attendance, Tasks, My Team
/// (only when the user has a team) and Profile.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  _HomeTab _selected = _HomeTab.home;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // A push tapped on a cold start (or before sign-in) lands here.
      final PushEvent? pending = context.read<PushService>().takePendingOpen();
      if (pending != null) openPushTarget(pending);
      _loadEverything();
    });
  }

  /// One warm-up pass so each tab is populated before it is opened.
  Future<void> _loadEverything() async {
    final AuthProvider auth = context.read<AuthProvider>();
    final String? userId = auth.user?.userId;
    if (userId == null) return;

    final TeamProvider team = context.read<TeamProvider>();
    await Future.wait<void>(<Future<void>>[
      context.read<DashboardProvider>().load(),
      context.read<AttendanceProvider>().load(userId: userId),
      context.read<AttendanceProvider>().loadToday(userId: userId),
      context.read<AttendanceProvider>().loadMonthSummary(userId: userId),
      context.read<TasksProvider>().load(userId: userId),
      context.read<LeaveProvider>().load(userId: userId),
      context.read<NotificationsProvider>().load(userId: userId),
      context.read<TransportationProvider>().load(userId: userId),
      context.read<LeaveProvider>().loadSystemCodes(),
      // An empty list = not a manager: no "My Team" tab, no "Team requests".
      team.loadMembers(),
    ]);
    // Home's "punched today" stat needs the board too — only once we know
    // there's a team to fetch one for.
    if (team.hasTeam) await team.loadBoard();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from the background: today's punches may have changed (the wall
  /// terminal, another day starting) and queued punches may now go out.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final String? userId = context.read<AuthProvider>().user?.userId;
    if (userId == null) return;
    context.read<AttendanceProvider>().loadToday(userId: userId);
    context.read<NotificationsProvider>().load(userId: userId);
    final TeamProvider team = context.read<TeamProvider>();
    team.loadMembers();
    if (team.hasTeam) team.loadBoard();
  }

  void _select(_HomeTab tab) {
    setState(() => _selected = tab);
    // The board is live data — refresh it each time it is opened.
    if (tab == _HomeTab.team) context.read<TeamProvider>().loadBoard();
  }

  /// Indices 0..2 are the fixed tabs the dashboard links to.
  void _goToTab(int index) => _select(_HomeTab.values[index]);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    // Badge = length of the list; the server drops dismissed items.
    final int unread = context.select<NotificationsProvider, int>(
      (NotificationsProvider p) => p.unreadCount,
    );
    final bool hasTeam = context.select<TeamProvider, bool>(
      (TeamProvider p) => p.hasTeam,
    );

    final List<_HomeTab> visible = <_HomeTab>[
      for (final _HomeTab tab in _HomeTab.values)
        if (tab != _HomeTab.team || hasTeam) tab,
    ];
    // Signed out / not a manager any more while parked on the team tab.
    final _HomeTab current = visible.contains(_selected)
        ? _selected
        : _HomeTab.home;

    Widget screenFor(_HomeTab tab) => switch (tab) {
      _HomeTab.home => DashboardScreen(onOpenTab: _goToTab),
      _HomeTab.attendance => const AttendanceScreen(embedded: true),
      _HomeTab.tasks => const TasksScreen(embedded: true),
      _HomeTab.team => const TeamScreen(),
      _HomeTab.profile => const ProfileScreen(embedded: true),
    };

    return Scaffold(
      extendBody: true,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: Row(
                  children: <Widget>[
                    const BrandLogo(),
                    const Spacer(),
                    SoftIconButton(
                      icon: Icons.notifications_none_rounded,
                      tooltip: t.notificationsTitle,
                      badgeCount: unread,
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.notifications),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: visible.indexOf(current),
                  // Keyed so a tab appearing mid-list (My Team) never hands
                  // its neighbour's state to the wrong screen.
                  children: <Widget>[
                    for (final _HomeTab tab in visible)
                      KeyedSubtree(
                        key: ValueKey<_HomeTab>(tab),
                        child: screenFor(tab),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        tabs: visible,
        selected: current,
        onChanged: _select,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.tabs,
    required this.selected,
    required this.onChanged,
  });

  final List<_HomeTab> tabs;
  final _HomeTab selected;
  final ValueChanged<_HomeTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF0FFFDFB),
        border: Border(top: BorderSide(color: Colors.white)),
      ),
      padding: EdgeInsets.only(
        top: 7,
        bottom: 8 + MediaQuery.of(context).padding.bottom * 0.4,
      ),
      child: Row(
        children: <Widget>[
          for (final _HomeTab tab in tabs)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(tab),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 40,
                        height: 28,
                        decoration: BoxDecoration(
                          color: tab == selected
                              ? AppColors.greenTint
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          tab.icon,
                          size: 18,
                          color: tab == selected
                              ? AppColors.green
                              : const Color(0xFF9AA4A1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab.label(t),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: tab == selected
                              ? AppColors.ink
                              : const Color(0xFF9AA4A1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
