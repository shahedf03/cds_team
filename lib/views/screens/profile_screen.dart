import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/team_leave_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/transportation_provider.dart';
import '../../routes/app_routes.dart';
import '../widgets/brand_logo.dart';
import '../widgets/cds_app_bar.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.embedded = false});

  final bool embedded;

  Future<void> _logout(BuildContext context) async {
    final AppLocalizations t = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(t.profileSignOutTitle, style: const TextStyle(fontSize: 17)),
        content: Text(
          t.profileSignOutMsg,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.commonCancel, style: const TextStyle(color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: Text(t.profileSignOut),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    context.read<AttendanceProvider>().reset();
    context.read<TransportationProvider>().reset();
    context.read<TasksProvider>().reset();
    context.read<LeaveProvider>().reset();
    context.read<TeamLeaveProvider>().reset();
    context.read<TeamProvider>().reset();
    context.read<NotificationsProvider>().reset();
    await context.read<AuthProvider>().logout();

    AppRoutes.toLogin();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final AuthProvider auth = context.watch<AuthProvider>();
    final bool isManager = context.select<TeamProvider, bool>(
      (TeamProvider p) => p.hasTeam,
    );

    final Widget body = ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: <Widget>[
        if (!embedded) CdsAppBar(title: t.profileTitle),
        GlassCard(
          radius: 23,
          padding: const EdgeInsets.all(17),
          child: Row(
            children: <Widget>[
              UserAvatar(initials: auth.user?.initials ?? '?', size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      auth.user?.userName ?? '—',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.user?.userPosition ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7F8B88),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Cloud Data Solutions',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        ListLabel(label: t.profileWorkspace),
        _MenuRow(
          tone: ToneColor.amber,
          icon: Icons.receipt_long_outlined,
          title: t.dashboardDailyExpenses,
          subtitle: t.dashboardDailyExpensesSub,
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.transportation),
        ),
        _MenuRow(
          tone: ToneColor.blue,
          icon: Icons.event_note_outlined,
          title: t.leaveTitle,
          subtitle: t.dashboardLeaveRequestSub,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.leave),
        ),
        // Managers only: hidden when GET /api/team/members comes back empty.
        if (isManager)
          _MenuRow(
            tone: ToneColor.amber,
            icon: Icons.groups_outlined,
            title: t.teamLeaveTitle,
            subtitle: t.profileTeamRequestsSub,
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.leaveTeam),
          ),
        _MenuRow(
          tone: ToneColor.green,
          icon: Icons.notifications_none_rounded,
          title: t.notificationsTitle,
          subtitle: t.notificationsNothingNewMsg,
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
        ),
        const SizedBox(height: 18),
        ListLabel(label: t.profileAccount),
        _LanguageRow(),
        _MenuRow(
          tone: ToneColor.blue,
          icon: Icons.badge_outlined,
          title: t.profileUserId,
          subtitle: auth.user?.userId ?? '—',
        ),
        _MenuRow(
          tone: ToneColor.green,
          icon: Icons.dns_outlined,
          title: t.profileServer,
          subtitle: AppConfig.apiBaseUrl,
        ),
        _MenuRow(
          tone: ToneColor.red,
          icon: Icons.logout_rounded,
          title: t.profileSignOut,
          subtitle: t.profileSignOutSub,
          onTap: () => _logout(context),
        ),
        const SizedBox(height: 40),
        const Center(child: Opacity(opacity: 0.5, child: BrandLogo(scale: 0.95))),
      ],
    );

    if (embedded) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: body,
      );
    }

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: body,
          ),
        ),
      ),
    );
  }
}

/// The real language toggle: English ↔ Arabic, persisted and applied app-wide
/// via [LocaleProvider] / `MaterialApp.locale`.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final LocaleProvider locale = context.watch<LocaleProvider>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: GlassCard(
        radius: 16,
        color: const Color(0x9EFFFFFF),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: <Widget>[
            const IconWell(icon: Icons.translate_rounded, tone: ToneColor.blue),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    t.profileLanguage,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.profileLanguageSub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9, color: Color(0xFF929D9A)),
                  ),
                ],
              ),
            ),
            _LanguageSwitch(
              isArabic: locale.isArabic,
              onChanged: (bool arabic) => context
                  .read<LocaleProvider>()
                  .setLocale(arabic ? LocaleProvider.arabic : LocaleProvider.english),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageSwitch extends StatelessWidget {
  const _LanguageSwitch({required this.isArabic, required this.onChanged});

  final bool isArabic;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _LanguagePill(label: 'EN', selected: !isArabic, onTap: () => onChanged(false)),
          _LanguagePill(label: 'AR', selected: isArabic, onTap: () => onChanged(true)),
        ],
      ),
    );
  }
}

class _LanguagePill extends StatelessWidget {
  const _LanguagePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.tone,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final ToneColor tone;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: GlassCard(
        onTap: onTap,
        radius: 16,
        color: const Color(0x9EFFFFFF),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: <Widget>[
            IconWell(icon: icon, tone: tone),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF929D9A),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: Color(0xFF9AA5A1),
              ),
          ],
        ),
      ),
    );
  }
}
