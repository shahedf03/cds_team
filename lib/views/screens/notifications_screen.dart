import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../widgets/cds_app_bar.dart';
import '../widgets/common.dart';

/// §7 — notifications list. Opening the screen advances the `autoId` cursor.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refresh();
      if (mounted) {
        await context.read<NotificationsProvider>().markAllSeen();
      }
    });
  }

  Future<void> _refresh() async {
    final AuthProvider auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    await context.read<NotificationsProvider>().load(userId: auth.user!.userId);
  }

  @override
  Widget build(BuildContext context) {
    final NotificationsProvider provider = context
        .watch<NotificationsProvider>();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const CdsAppBar(title: 'Notifications'),
                ListLabel(
                  label: 'Updates',
                  trailing: provider.items.isEmpty
                      ? null
                      : '${provider.items.length}',
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.green,
                    backgroundColor: Colors.white,
                    onRefresh: _refresh,
                    child: _Body(provider: provider, onRetry: _refresh),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.provider, required this.onRetry});

  final NotificationsProvider provider;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }

    if (provider.hasError && provider.items.isEmpty) {
      return ListView(
        children: <Widget>[
          StateMessage(
            icon: Icons.cloud_off_rounded,
            tone: ToneColor.red,
            title: 'Could not load notifications',
            message: provider.error,
            actionLabel: 'Try again',
            onAction: onRetry,
          ),
        ],
      );
    }

    if (provider.items.isEmpty) {
      return ListView(
        children: const <Widget>[
          StateMessage(
            icon: Icons.notifications_none_rounded,
            title: 'Nothing new',
            message: 'Announcements and updates will appear here.',
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 40),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: provider.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) =>
          _NotificationCard(item: provider.items[index]),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const IconWell(
            icon: Icons.campaign_outlined,
            tone: ToneColor.green,
            size: 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Text(
                      item.dateLabel,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.faintText,
                      ),
                    ),
                  ],
                ),
                if (item.notificationsDescription.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    item.notificationsDescription,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      color: Color(0xFF8A9693),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
