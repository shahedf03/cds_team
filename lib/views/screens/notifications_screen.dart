import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/app_notification.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/push_service.dart';
import '../widgets/cds_app_bar.dart';
import '../widgets/common.dart';

/// §7 — notifications list: pull to refresh, swipe to dismiss, clear all.
/// Dismissing is server-side (`autoId`), so a dismissed item stays gone.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final AuthProvider auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    final String userId = auth.user!.userId;
    final NotificationsProvider provider = context
        .read<NotificationsProvider>();
    await provider.load(userId: userId);
    // Opening the screen reads everything currently loaded — badge → 0,
    // nothing disappears from the list.
    await provider.markAllRead(userId: userId);
  }

  Future<void> _markAllRead() async {
    final String? userId = context.read<AuthProvider>().user?.userId;
    if (userId == null) return;
    final NotificationsProvider provider = context
        .read<NotificationsProvider>();
    final bool ok = await provider.markAllRead(userId: userId);
    if (!ok && mounted) {
      showApiSnack(
        context,
        provider.error ??
            AppLocalizations.of(context).notificationsCouldNotMarkRead,
      );
    }
  }

  Future<void> _dismiss(AppNotification item) async {
    final String? userId = context.read<AuthProvider>().user?.userId;
    if (userId == null) return;
    final NotificationsProvider provider = context
        .read<NotificationsProvider>();
    final bool ok = await provider.dismiss(item, userId: userId);
    if (!ok && mounted) {
      showApiSnack(
        context,
        provider.error ??
            AppLocalizations.of(context).notificationsCouldNotDismiss,
      );
    }
  }

  Future<void> _clearAll() async {
    final AppLocalizations t = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t.notificationsClearAllTitle,
          style: const TextStyle(fontSize: 16),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              t.commonCancel,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: Text(t.notificationsClearAll),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final String? userId = context.read<AuthProvider>().user?.userId;
    if (userId == null) return;
    final NotificationsProvider provider = context
        .read<NotificationsProvider>();
    final bool ok = await provider.clearAll(userId: userId);
    if (!ok && mounted) {
      showApiSnack(context, provider.error ?? t.notificationsCouldNotClear);
    }
  }

  /// 2026-10-07 — `linkType`/`linkId` hold the same values a matching push
  /// carries as `type`/`linkId`, so this shares [openPushTarget] with the
  /// push-tap handler. Older rows (`linkType: null`) stay non-tappable, see
  /// [AppNotification.isTappable].
  void _open(AppNotification item) {
    if (!item.isTappable) return;
    final String? userId = context.read<AuthProvider>().user?.userId;
    if (userId != null) {
      context.read<NotificationsProvider>().markRead(item, userId: userId);
    }
    openPushTarget(PushEvent(PushKind.fromType(item.linkType), item.linkId));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
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
                CdsAppBar(
                  title: t.notificationsTitle,
                  action: provider.items.isEmpty
                      ? null
                      : _NotificationsMenu(
                          hasUnread: provider.hasUnread,
                          onMarkAllRead: _markAllRead,
                          onClearAll: _clearAll,
                        ),
                ),
                ListLabel(
                  label: t.notificationsUpdates,
                  trailing: provider.items.isEmpty
                      ? null
                      : '${provider.items.length}',
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.green,
                    backgroundColor: Colors.white,
                    onRefresh: _refresh,
                    child: _Body(
                      provider: provider,
                      onRetry: _refresh,
                      onDismiss: _dismiss,
                      onOpen: _open,
                    ),
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

enum _NotificationsMenuAction { markAllRead, clearAll }

/// One "more" button holding both "تعليم الكل كمقروء" (read, keeps the rows)
/// and "مسح الكل" (destructive, deletes) — kept as two distinct actions per
/// the API split between `POST /read-all` and `autoId=-1`.
class _NotificationsMenu extends StatelessWidget {
  const _NotificationsMenu({
    required this.hasUnread,
    required this.onMarkAllRead,
    required this.onClearAll,
  });

  final bool hasUnread;
  final VoidCallback onMarkAllRead;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return PopupMenuButton<_NotificationsMenuAction>(
      tooltip: t.commonMore,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: AppColors.cream,
      onSelected: (_NotificationsMenuAction action) {
        switch (action) {
          case _NotificationsMenuAction.markAllRead:
            onMarkAllRead();
          case _NotificationsMenuAction.clearAll:
            onClearAll();
        }
      },
      itemBuilder: (BuildContext context) =>
          <PopupMenuEntry<_NotificationsMenuAction>>[
            PopupMenuItem<_NotificationsMenuAction>(
              value: _NotificationsMenuAction.markAllRead,
              enabled: hasUnread,
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.done_all_rounded,
                    size: 18,
                    color: AppColors.ink,
                  ),
                  const SizedBox(width: 10),
                  Text(t.notificationsReadAll),
                ],
              ),
            ),
            PopupMenuItem<_NotificationsMenuAction>(
              value: _NotificationsMenuAction.clearAll,
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.clear_all_rounded,
                    size: 18,
                    color: AppColors.red,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    t.notificationsClearAll,
                    style: const TextStyle(color: AppColors.red),
                  ),
                ],
              ),
            ),
          ],
      child: SizedBox(
        width: 34,
        height: 34,
        child: Material(
          color: const Color(0x88FFFFFF),
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              const Icon(
                Icons.more_vert_rounded,
                size: 17,
                color: AppColors.ink,
              ),
              if (hasUnread)
                Positioned(
                  right: 7,
                  top: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cream, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.provider,
    required this.onRetry,
    required this.onDismiss,
    required this.onOpen,
  });

  final NotificationsProvider provider;
  final VoidCallback onRetry;
  final ValueChanged<AppNotification> onDismiss;
  final ValueChanged<AppNotification> onOpen;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
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
            title: t.notificationsCouldNotLoad,
            message: provider.error,
            actionLabel: t.commonTryAgain,
            onAction: onRetry,
          ),
        ],
      );
    }

    if (provider.items.isEmpty) {
      return ListView(
        children: <Widget>[
          StateMessage(
            icon: Icons.notifications_none_rounded,
            title: t.notificationsNothingNew,
            message: t.notificationsNothingNewMsg,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 40),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: provider.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final AppNotification item = provider.items[index];
        return Dismissible(
          key: ValueKey<String>('notification-${item.autoId}'),
          direction: DismissDirection.horizontal,
          onDismissed: (_) => onDismiss(item),
          background: const _DismissBackground(),
          child: _NotificationCard(item: item, onTap: () => onOpen(item)),
        );
      },
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ToneColor.red.background,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerRight,
      child: Icon(
        Icons.delete_outline_rounded,
        color: ToneColor.red.foreground,
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: item.isTappable ? onTap : null,
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IconWell(
            icon: Icons.campaign_outlined,
            tone: item.isRead ? ToneColor.blue : ToneColor.green,
            size: 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    if (!item.isRead) ...<Widget>[
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          color: AppColors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: item.isRead
                              ? FontWeight.w600
                              : FontWeight.w800,
                          color: item.isRead ? AppColors.muted : AppColors.ink,
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
