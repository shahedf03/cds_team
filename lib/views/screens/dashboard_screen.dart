import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/attendance_record.dart';
import '../../models/leave_request.dart';
import '../../models/transportation.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/transportation_provider.dart';
import '../../routes/app_routes.dart';
import '../widgets/brand_logo.dart';
import '../widgets/check_in_card.dart';
import '../widgets/common.dart';

/// Home tab: greeting, fingerprint check-in, stats, quick actions, activity.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  Future<void> _refresh(BuildContext context) async {
    final AuthProvider auth = context.read<AuthProvider>();
    final String? userId = auth.user?.userId;
    if (userId == null) return;

    await Future.wait<void>(<Future<void>>[
      context.read<AttendanceProvider>().load(userId: userId),
      context.read<AttendanceProvider>().loadToday(userId: userId),
      context.read<TasksProvider>().load(userId: userId),
      context.read<LeaveProvider>().load(userId: userId),
      context.read<TransportationProvider>().load(userId: userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final AttendanceProvider attendance = context.watch<AttendanceProvider>();
    final TasksProvider tasks = context.watch<TasksProvider>();
    final LeaveProvider leave = context.watch<LeaveProvider>();

    return RefreshIndicator(
      color: AppColors.green,
      backgroundColor: Colors.white,
      onRefresh: () => _refresh(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          _Greeting(name: auth.user?.firstName ?? '', initials: auth.user?.initials ?? '?'),
          const SizedBox(height: 18),
          const CheckInCard(),
          const SizedBox(height: 20),
          SectionHeading(
            title: 'Overview',
            actionLabel: 'This month',
            actionIcon: Icons.expand_more_rounded,
            onAction: () => onOpenTab(1),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatCard(
                  tone: ToneColor.green,
                  icon: Icons.check_rounded,
                  value: '${attendance.attendancePercent}',
                  suffix: '%',
                  label: 'Attendance',
                  onTap: () => onOpenTab(1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  tone: ToneColor.amber,
                  icon: Icons.event_available_outlined,
                  value: leave.pendingCount.toString().padLeft(2, '0'),
                  label: 'Leave requests',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.leave),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  tone: ToneColor.blue,
                  icon: Icons.checklist_rounded,
                  value: tasks.openCount.toString().padLeft(2, '0'),
                  label: 'Open tasks',
                  onTap: () => onOpenTab(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const SectionHeading(title: 'Quick actions'),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: _ActionTile(
                  tone: ToneColor.amber,
                  icon: Icons.directions_car_filled_outlined,
                  title: 'Daily expenses',
                  subtitle: 'Log KM, clients & totals',
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.transportation),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionTile(
                  tone: ToneColor.blue,
                  icon: Icons.event_note_outlined,
                  title: 'Leave request',
                  subtitle: 'Leaving or vacation',
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.leave),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionHeading(
            title: 'Recent activity',
            actionLabel: 'View all',
            onAction: () => onOpenTab(1),
          ),
          const SizedBox(height: 8),
          _ActivityList(onOpenTab: onOpenTab),
          const SizedBox(height: 28),
          const Center(child: Opacity(opacity: 0.45, child: BrandLogo(scale: 0.9))),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name, required this.initials});

  final String name;
  final String initials;

  String get _partOfDay {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(_partOfDay.toUpperCase(), style: _eyebrow),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: -0.7,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  children: <InlineSpan>[
                    TextSpan(text: name.isEmpty ? 'Welcome' : '$name, '),
                    const TextSpan(
                      text: 'hello',
                      style: TextStyle(color: AppColors.green),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        UserAvatar(initials: initials),
      ],
    );
  }

  static const TextStyle _eyebrow = TextStyle(
    fontSize: 10,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w800,
    color: AppColors.subtleText,
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.tone,
    required this.icon,
    required this.value,
    required this.label,
    this.suffix,
    this.onTap,
  });

  final ToneColor tone;
  final IconData icon;
  final String value;
  final String label;
  final String? suffix;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      radius: 18,
      color: const Color(0xBAFFFFFF),
      padding: const EdgeInsets.fromLTRB(10, 11, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IconWell(icon: icon, tone: tone, size: 23),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  letterSpacing: -1,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              if (suffix != null)
                Text(
                  suffix!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: Color(0xFF84918F)),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.tone,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final ToneColor tone;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      radius: 18,
      padding: const EdgeInsets.fromLTRB(12, 13, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IconWell(icon: icon, tone: tone, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: Color(0xFF8A9693)),
          ),
        ],
      ),
    );
  }
}

/// Real recent activity, stitched from the three data sources the Home
/// screen already has loaded.
class _ActivityList extends StatelessWidget {
  const _ActivityList({required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final AttendanceProvider attendance = context.watch<AttendanceProvider>();
    final TransportationProvider transport =
        context.watch<TransportationProvider>();
    final LeaveProvider leave = context.watch<LeaveProvider>();

    final List<_Activity> items = <_Activity>[];

    if (attendance.records.isNotEmpty) {
      final AttendanceRecord latest = attendance.records.first;
      items.add(
        _Activity(
          icon: Icons.fingerprint_rounded,
          tone: ToneColor.green,
          title: 'Checked in',
          detail: '${latest.monthLabel} ${latest.dayNumber} · ${latest.startLabel}',
          onTap: () => onOpenTab(1),
        ),
      );
    }

    if (transport.entries.isNotEmpty) {
      final Transportation latest = transport.entries.first;
      items.add(
        _Activity(
          icon: Icons.directions_car_filled_outlined,
          tone: ToneColor.amber,
          title: 'Trip submitted',
          detail: '${latest.dateLabel} · ${latest.km} km',
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.transportation),
        ),
      );
    }

    if (leave.requests.isNotEmpty) {
      final LeaveRequest latest = leave.requests.first;
      items.add(
        _Activity(
          icon: Icons.event_available_outlined,
          tone: ToneColor.blue,
          title: '${latest.kind.labelEn} ${latest.statusLabel.toLowerCase()}',
          detail: '${latest.fromDateTime} · ${latest.leavVacTypeName}',
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.leave),
        ),
      );
    }

    if (items.isEmpty) {
      return GlassCard(
        radius: 18,
        color: AppColors.cardSoft,
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: const Center(
          child: Text(
            'No activity yet this month.',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ),
      );
    }

    return Column(
      children: items
          .map(
            (_Activity item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GlassCard(
                onTap: item.onTap,
                radius: 15,
                color: AppColors.cardSoft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 9,
                ),
                child: Row(
                  children: <Widget>[
                    IconWell(icon: item.icon, tone: item.tone, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF8A9693),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFFA2AAA8),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Activity {
  const _Activity({
    required this.icon,
    required this.tone,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final ToneColor tone;
  final String title;
  final String detail;
  final VoidCallback onTap;
}
