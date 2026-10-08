import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/app_notification.dart';
import '../../models/dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../routes/app_routes.dart';
import '../widgets/brand_logo.dart';
import '../widgets/check_in_card.dart';
import '../widgets/common.dart';

/// Home tab (2026-10-05) — the whole screen from one call,
/// `GET /api/dashboard`. Layout matches the Portal's home page: header,
/// fingerprint punch, 4 stat cards, 3 overview cards,
/// attendance-today, recent activity.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  Future<void> _refresh(BuildContext context) =>
      context.read<DashboardProvider>().load();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final AuthProvider auth = context.watch<AuthProvider>();
    final DashboardProvider dashboard = context.watch<DashboardProvider>();
    final DashboardDto? data = dashboard.data;

    return RefreshIndicator(
      color: AppColors.green,
      backgroundColor: Colors.white,
      onRefresh: () => _refresh(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        children: <Widget>[
          _Header(
            name: auth.user?.firstName ?? '',
            initials: auth.user?.initials ?? '?',
            isManager: data?.isManager ?? false,
            onAddTask: () => onOpenTab(2),
          ),
          const SizedBox(height: 18),
          const CheckInCard(),
          const SizedBox(height: 20),
          if (dashboard.isLoading && data == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.green),
              ),
            )
          else if (dashboard.hasError && data == null)
            StateMessage(
              icon: Icons.cloud_off_rounded,
              tone: ToneColor.red,
              title: t.dashboardCouldNotLoad,
              message: dashboard.error,
              actionLabel: t.commonTryAgain,
              onAction: () => _refresh(context),
            )
          else if (data != null) ...<Widget>[
            _DateRow(loadedAt: dashboard.loadedAt, onRefresh: () => _refresh(context)),
            const SizedBox(height: 14),
            _StatGrid(data: data, onOpenTab: onOpenTab),
            const SizedBox(height: 14),
            _OverviewCards(data: data, onOpenTab: onOpenTab),
            const SizedBox(height: 14),
            if (data.isManager) ...<Widget>[
              SectionHeading(title: t.dashboardAttendanceToday),
              const SizedBox(height: 8),
              _AttendanceRingCard(data: data, onTap: () => onOpenTab(3)),
              const SizedBox(height: 22),
            ],
            SectionHeading(
              title: t.dashboardRecentActivity,
              actionLabel: t.dashboardViewAll,
              onAction: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
            ),
            const SizedBox(height: 8),
            _RecentNotifications(items: data.recentNotifications),
          ],
          const SizedBox(height: 28),
          const Center(
            child: Opacity(opacity: 0.45, child: BrandLogo(scale: 0.9)),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.initials,
    required this.isManager,
    required this.onAddTask,
  });

  final String name;
  final String initials;
  final bool isManager;
  final VoidCallback onAddTask;

  String _partOfDay(AppLocalizations t) {
    final int hour = DateTime.now().hour;
    if (hour < 12) return t.dashboardGoodMorning;
    if (hour < 17) return t.dashboardGoodAfternoon;
    return t.dashboardGoodEvening;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                (isManager ? t.dashboardManagerEyebrow : t.dashboardEmployeeEyebrow)
                    .toUpperCase(),
                style: _eyebrow,
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 22,
                    letterSpacing: -0.7,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  children: <InlineSpan>[
                    TextSpan(text: '${_partOfDay(t)}، '),
                    TextSpan(
                      text: name.isEmpty ? t.dashboardWelcome : name,
                      style: const TextStyle(color: AppColors.green),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isManager ? t.dashboardManagerSubtitle : t.dashboardEmployeeSubtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.subtleText),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
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

class _DateRow extends StatelessWidget {
  const _DateRow({required this.loadedAt, required this.onRefresh});

  final DateTime? loadedAt;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final String dateLabel = DateFormat('EEEE, d MMMM yyyy', locale).format(DateTime.now());
    final String updated = loadedAt == null ? '--:--' : DateFormat('HH:mm').format(loadedAt!);
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            '$dateLabel · ${t.dashboardDailySummary}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.subtleText),
          ),
        ),
        Text(
          t.dashboardLastUpdated(updated),
          style: const TextStyle(fontSize: 9, color: AppColors.faintText),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: onRefresh,
          borderRadius: BorderRadius.circular(99),
          child: const Padding(
            padding: EdgeInsets.all(2),
            child: Icon(Icons.refresh_rounded, size: 15, color: AppColors.green),
          ),
        ),
      ],
    );
  }
}

/// 4 stat cards, 2×2 on a phone.
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.data, required this.onOpenTab});

  final DashboardDto data;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _StatCard(
                tone: ToneColor.blue,
                icon: Icons.calendar_month_rounded,
                value: '${data.tasksThisMonth}',
                label: t.dashboardTasksThisMonth,
                note: t.dashboardDoneCount(data.doneTasksThisMonth),
                onTap: () => onOpenTab(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                tone: data.overdueTasks > 0 ? ToneColor.amber : ToneColor.green,
                icon: Icons.checklist_rounded,
                value: '${data.openTasks}',
                label: t.dashboardOpenTasks,
                note: data.overdueTasks > 0
                    ? t.dashboardOverdueCount(data.overdueTasks)
                    : null,
                noteColor: data.overdueTasks > 0 ? AppColors.red : null,
                onTap: () => onOpenTab(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: _StatCard(
                tone: ToneColor.green,
                icon: Icons.schedule_rounded,
                value: data.myToday.hasPunchedToday
                    ? DashboardDto.hhmm(data.myToday.elapsedMinutes)
                    : '--:--',
                label: t.dashboardWorkHoursToday,
                note: data.myToday.hasPunchedToday ? null : t.dashboardNoPunchToday,
                onTap: () => onOpenTab(1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: data.isManager
                  ? _StatCard(
                      tone: ToneColor.green,
                      icon: Icons.groups_rounded,
                      value: '${data.presentToday}/${data.teamSize}',
                      label: t.dashboardAttendanceToday,
                      note: t.dashboardOfTeam(data.attendanceRate.round()),
                      onTap: () => onOpenTab(3),
                    )
                  : _StatCard(
                      tone: ToneColor.blue,
                      icon: Icons.notifications_none_rounded,
                      value: '${data.unreadNotifications}',
                      label: t.notificationsTitle,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.tone,
    required this.icon,
    required this.value,
    required this.label,
    this.note,
    this.noteColor,
    this.onTap,
  });

  final ToneColor tone;
  final IconData icon;
  final String value;
  final String label;
  final String? note;
  final Color? noteColor;
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              letterSpacing: -1,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: Color(0xFF84918F)),
          ),
          if (note != null) ...<Widget>[
            const SizedBox(height: 1),
            Text(
              note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: noteColor ?? AppColors.subtleText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 3 overview cards: completion rate (everyone), pending approvals + team
/// snapshot (manager), or leave/transportation shortcuts (employee).
class _OverviewCards extends StatelessWidget {
  const _OverviewCards({required this.data, required this.onOpenTab});

  final DashboardDto data;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final double rate = (data.completionRate.clamp(0, 100)) / 100;
    return Column(
      children: <Widget>[
        GlassCard(
          onTap: () => onOpenTab(2),
          radius: 18,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      t.dashboardCompletionRate,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Text(
                    '${data.completionRate}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: rate,
                  minHeight: 6,
                  backgroundColor: AppColors.line,
                  color: AppColors.green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (data.isManager) ...<Widget>[
          GlassCard(
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.leaveTeam),
            radius: 18,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        t.dashboardPendingApprovals,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: data.pendingApprovals > 0 ? 1 : 0,
                          minHeight: 6,
                          backgroundColor: AppColors.line,
                          color: AppColors.amber,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${data.pendingApprovals}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.amber,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GlassCard(
            onTap: () => onOpenTab(3),
            radius: 18,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  t.dashboardTeamToday,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t.dashboardOnLeaveAbsent(data.onLeaveToday, data.absentToday),
                  style: const TextStyle(fontSize: 9, color: AppColors.subtleText),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      _MiniBar(
                        value: data.presentToday,
                        total: data.teamSize,
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 6),
                      _MiniBar(
                        value: data.onLeaveToday,
                        total: data.teamSize,
                        color: AppColors.blue,
                      ),
                      const SizedBox(width: 6),
                      _MiniBar(
                        value: data.absentToday,
                        total: data.teamSize,
                        color: AppColors.red,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else
          Row(
            children: <Widget>[
              Expanded(
                child: _ActionTile(
                  tone: ToneColor.blue,
                  icon: Icons.event_note_outlined,
                  title: t.dashboardLeaveRequest,
                  subtitle: t.dashboardLeaveRequestSub,
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.leave),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionTile(
                  tone: ToneColor.amber,
                  icon: Icons.directions_car_filled_outlined,
                  title: t.dashboardDailyExpenses,
                  subtitle: t.dashboardDailyExpensesSub,
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.transportation),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.value, required this.total, required this.color});

  final int value;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double fraction = total <= 0 ? 0 : (value / total).clamp(0, 1);
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Text(
            '$value',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: FractionallySizedBox(
              heightFactor: fraction < 0.08 && value > 0 ? 0.08 : fraction,
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
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

/// Manager-only dark "mini dashboard" card — ring = `attendanceRate`, legend
/// حاضر / لم يبصم / إجازة / الفريق.
class _AttendanceRingCard extends StatelessWidget {
  const _AttendanceRingCard({required this.data, required this.onTap});

  final DashboardDto data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final double rate = (data.attendanceRate.clamp(0, 100)) / 100;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: rate.clamp(0, 1),
                        strokeWidth: 6,
                        backgroundColor: Colors.white24,
                        color: AppColors.green,
                      ),
                    ),
                    Text(
                      '${data.attendanceRate.round()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: <Widget>[
                    _LegendDot(
                      color: AppColors.green,
                      label: '${t.dashboardPresent} ${data.presentToday}',
                    ),
                    _LegendDot(
                      color: AppColors.red,
                      label: '${t.dashboardNotPunched} ${data.absentToday}',
                    ),
                    _LegendDot(
                      color: AppColors.blue,
                      label: '${t.dashboardOnLeave} ${data.onLeaveToday}',
                    ),
                    _LegendDot(
                      color: Colors.white54,
                      label: '${t.dashboardTeamLabel} ${data.teamSize}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }
}

/// `recentNotifications` (max 5), bell icon for unread.
class _RecentNotifications extends StatelessWidget {
  const _RecentNotifications({required this.items});

  final List<AppNotification> items;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    if (items.isEmpty) {
      return GlassCard(
        radius: 18,
        color: AppColors.cardSoft,
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            t.notificationsNothingNew,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ),
      );
    }
    return Column(
      children: items
          .take(5)
          .map(
            (AppNotification item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GlassCard(
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
                radius: 15,
                color: AppColors.cardSoft,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                child: Row(
                  children: <Widget>[
                    IconWell(
                      icon: Icons.campaign_outlined,
                      tone: item.isRead ? ToneColor.blue : ToneColor.green,
                      size: 32,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.notificationsDescription,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 9, color: Color(0xFF8A9693)),
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
