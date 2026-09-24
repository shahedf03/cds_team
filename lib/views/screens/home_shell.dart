import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/transportation_provider.dart';
import '../../routes/app_routes.dart';
import '../widgets/brand_logo.dart';
import '../widgets/common.dart';
import 'attendance_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'tasks_screen.dart';

/// Brand bar + bottom navigation wrapper: Home, Attendance, Tasks, Profile.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEverything());
  }

  /// One warm-up pass so each tab is populated before it is opened.
  Future<void> _loadEverything() async {
    final AuthProvider auth = context.read<AuthProvider>();
    final String? userId = auth.user?.userId;
    if (userId == null) return;

    await Future.wait<void>(<Future<void>>[
      context.read<AttendanceProvider>().load(userId: userId),
      context.read<AttendanceProvider>().loadToday(userId: userId),
      context.read<TasksProvider>().load(userId: userId),
      context.read<LeaveProvider>().load(userId: userId),
      context.read<NotificationsProvider>().load(userId: userId),
      context.read<TransportationProvider>().load(userId: userId),
      context.read<LeaveProvider>().loadSystemCodes(),
    ]);
  }

  void _goToTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final bool hasUnread = context.select<NotificationsProvider, bool>(
      (NotificationsProvider p) => p.hasUnread,
    );

    final List<Widget> tabs = <Widget>[
      DashboardScreen(onOpenTab: _goToTab),
      const AttendanceScreen(embedded: true),
      const TasksScreen(embedded: true),
      const ProfileScreen(embedded: true),
    ];

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
                      tooltip: 'Notifications',
                      showDot: hasUnread,
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.notifications),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(index: _index, children: tabs),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        index: _index,
        onChanged: _goToTab,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const List<({IconData icon, String label})> _items =
      <({IconData icon, String label})>[
        (icon: Icons.home_rounded, label: 'Home'),
        (icon: Icons.schedule_rounded, label: 'Attendance'),
        (icon: Icons.checklist_rounded, label: 'Tasks'),
        (icon: Icons.person_outline_rounded, label: 'Profile'),
      ];

  @override
  Widget build(BuildContext context) {
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
        children: List<Widget>.generate(_items.length, (int i) {
          final bool active = i == index;
          final ({IconData icon, String label}) item = _items[i];
          return Expanded(
            child: InkWell(
              onTap: () => onChanged(i),
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
                        color: active
                            ? AppColors.greenTint
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        item.icon,
                        size: 18,
                        color: active
                            ? AppColors.green
                            : const Color(0xFF9AA4A1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? AppColors.ink
                            : const Color(0xFF9AA4A1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
