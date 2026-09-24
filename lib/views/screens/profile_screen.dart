import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/transportation_provider.dart';
import '../../routes/app_routes.dart';
import '../widgets/brand_logo.dart';
import '../widgets/cds_app_bar.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.embedded = false});

  final bool embedded;

  Future<void> _logout(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Sign out?', style: TextStyle(fontSize: 17)),
        content: const Text(
          'You will need your username and password to sign back in.',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    context.read<AttendanceProvider>().reset();
    context.read<TransportationProvider>().reset();
    context.read<TasksProvider>().reset();
    context.read<LeaveProvider>().reset();
    context.read<NotificationsProvider>().reset();
    await context.read<AuthProvider>().logout();

    AppRoutes.toLogin();
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    final Widget body = ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: <Widget>[
        if (!embedded) const CdsAppBar(title: 'Profile'),
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
        const ListLabel(label: 'Workspace'),
        _MenuRow(
          tone: ToneColor.amber,
          icon: Icons.receipt_long_outlined,
          title: 'Daily expenses',
          subtitle: 'Trips, KM and client visits',
          onTap: () =>
              Navigator.of(context).pushNamed(AppRoutes.transportation),
        ),
        _MenuRow(
          tone: ToneColor.blue,
          icon: Icons.event_note_outlined,
          title: 'Leave & vacation',
          subtitle: 'Request time off and track status',
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.leave),
        ),
        _MenuRow(
          tone: ToneColor.green,
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: 'Announcements and updates',
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.notifications),
        ),
        const SizedBox(height: 18),
        const ListLabel(label: 'Account'),
        _MenuRow(
          tone: ToneColor.blue,
          icon: Icons.badge_outlined,
          title: 'User ID',
          subtitle: auth.user?.userId ?? '—',
        ),
        _MenuRow(
          tone: ToneColor.green,
          icon: Icons.dns_outlined,
          title: 'Server',
          subtitle: AppConfig.apiBaseUrl,
        ),
        _MenuRow(
          tone: ToneColor.red,
          icon: Icons.logout_rounded,
          title: 'Sign out',
          subtitle: 'End this session on this device',
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
