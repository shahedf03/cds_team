import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/team.dart';
import '../../providers/team_provider.dart';
import '../../routes/app_routes.dart';
import '../widgets/brand_logo.dart';
import '../widgets/common.dart';
import '../widgets/skeleton.dart';

/// §12 — "My Team": today's punch board for everyone under the manager. Tap a
/// person for their read-only profile.
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() => context.read<TeamProvider>().loadBoard();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final TeamProvider provider = context.watch<TeamProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              t.teamTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          ListLabel(
            label: t.memberToday,
            trailing: provider.board.isEmpty
                ? null
                : '${provider.punchedCount} / ${provider.board.length}',
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
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.provider, required this.onRetry});

  final TeamProvider provider;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    if (provider.isLoading && provider.board.isEmpty) {
      return SkeletonList(
        itemCount: 7,
        itemBuilder: (_, int i) => SkeletonRow(seed: i, leading: SkeletonLeading.avatar),
      );
    }

    if (provider.hasError && provider.board.isEmpty) {
      return ListView(
        children: <Widget>[
          StateMessage(
            icon: Icons.cloud_off_rounded,
            tone: ToneColor.red,
            title: t.teamCouldNotLoadBoard,
            message: provider.error,
            actionLabel: t.commonTryAgain,
            onAction: onRetry,
          ),
        ],
      );
    }

    if (provider.board.isEmpty) {
      return ListView(
        children: <Widget>[
          StateMessage(
            icon: Icons.groups_outlined,
            tone: ToneColor.blue,
            title: t.teamNoMembers,
            message: t.teamNoMembersMsg,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 100),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: provider.board.length,
      separatorBuilder: (_, _) => const SizedBox(height: 7),
      itemBuilder: (BuildContext context, int index) {
        final TeamMemberToday entry = provider.board[index];
        return _MemberRow(
          entry: entry,
          onTap: () => Navigator.of(
            context,
          ).pushNamed(AppRoutes.teamMember, arguments: entry.member),
        );
      },
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.entry, required this.onTap});

  final TeamMemberToday entry;
  final VoidCallback onTap;

  ToneColor get _tone {
    if (!entry.hasPunched) return ToneColor.red;
    return entry.today.hasOpenSession ? ToneColor.green : ToneColor.blue;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return GlassCard(
      onTap: onTap,
      radius: 17,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      child: Row(
        children: <Widget>[
          UserAvatar(initials: entry.member.initials, size: 40),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  entry.member.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 5),
                Align(
                  alignment: Alignment.centerLeft,
                  child: StatusChip(
                    label: entry.statusLabel(t),
                    tone: _tone,
                    icon: entry.hasPunched
                        ? Icons.fingerprint_rounded
                        : Icons.hourglass_empty_rounded,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: Color(0xFF9AA5A1),
          ),
        ],
      ),
    );
  }
}
