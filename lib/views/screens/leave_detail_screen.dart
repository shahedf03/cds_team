import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/leave_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../providers/team_leave_provider.dart';
import '../../services/leave_service.dart';
import '../widgets/cds_app_bar.dart';
import '../widgets/cds_dialogs.dart';
import '../widgets/common.dart';
import '../widgets/skeleton.dart';
import 'leave_screen.dart' show LeaveAttachmentsBadge, LeaveClientChips;

/// 2026-10-07 — one leave/leaving request: fields, status, "بانتظار: …",
/// the steps timeline, and whichever of Approve / Reject / Forward /
/// Withdraw its flags allow. Reachable by tapping a request in either list,
/// or deep-linked from a push/notification by `transNo`.
class LeaveDetailScreen extends StatefulWidget {
  const LeaveDetailScreen({super.key, required this.transNo});

  final String transNo;

  @override
  State<LeaveDetailScreen> createState() => _LeaveDetailScreenState();
}

class _LeaveDetailScreenState extends State<LeaveDetailScreen> {
  LeaveDetail? _detail;
  String? _error;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final LeaveDetail detail = await context.read<LeaveService>().detail(
        widget.transNo,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      // 404 (withdrawn meanwhile) or 403 (no longer yours to see): don't
      // strand the user on a dead detail screen, bounce back with the
      // message instead of showing an inline retry.
      if (e.isNotFound || e.isForbidden) {
        Navigator.of(context).maybePop();
        showApiSnack(context, e.message);
        return;
      }
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Both lists may now be stale — refresh whichever is relevant rather
  /// than guessing which one brought the user here.
  void _refreshLists() {
    final String? userId = context.read<AuthProvider>().user?.userId;
    context.read<TeamLeaveProvider>().load();
    if (userId != null) context.read<LeaveProvider>().load(userId: userId);
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String success,
  }) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      showApiSnack(context, success, isError: false);
      _refreshLists();
      await _load();
    } on ApiException catch (e) {
      if (mounted) showApiSnack(context, e.message);
    } catch (e) {
      if (mounted) showApiSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve() async {
    final AppLocalizations t = AppLocalizations.of(context);
    await _run(
      () => context.read<LeaveService>().approve(widget.transNo),
      success: t.teamLeaveApproved,
    );
  }

  Future<void> _reject() async {
    final AppLocalizations t = AppLocalizations.of(context);
    final String? reason = await showCdsTextInput(
      context,
      icon: Icons.block_rounded,
      tone: ToneColor.red,
      title: t.teamLeaveRejectDialogTitle,
      hint: t.teamLeaveRejectionHint,
      required: true,
      requiredMessage: t.teamLeaveReasonRequired,
      confirmLabel: t.teamLeaveReject,
    );
    if (reason == null || !mounted) return;
    await _run(
      () => context.read<LeaveService>().reject(widget.transNo, reason: reason),
      success: t.teamLeaveRejected,
    );
  }

  Future<void> _forward() async {
    final AppLocalizations t = AppLocalizations.of(context);
    final String toName = _detail?.request.forwardToName ?? '';
    final String? note = await showCdsTextInput(
      context,
      icon: Icons.forward_to_inbox_outlined,
      tone: ToneColor.blue,
      title: t.leaveForwardTo(toName),
      hint: t.leaveForwardNoteHint,
      confirmLabel: t.leaveForwardButton,
    );
    if (note == null || !mounted) return;
    await _run(
      () => context.read<LeaveService>().forward(
        widget.transNo,
        note: note.isEmpty ? null : note,
      ),
      success: t.leaveForwarded,
    );
  }

  Future<void> _withdraw() async {
    final AppLocalizations t = AppLocalizations.of(context);
    final bool confirmed = await showCdsConfirm(
      context,
      icon: Icons.undo_rounded,
      tone: ToneColor.red,
      title: t.leaveWithdrawConfirmTitle,
      cancelLabel: t.leaveKeep,
      confirmLabel: t.leaveWithdraw,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await context.read<LeaveService>().delete(widget.transNo);
      if (!mounted) return;
      showApiSnack(context, t.leaveRequestCancelled, isError: false);
      _refreshLists();
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) showApiSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  ToneColor _statusTone(LeaveRequest r) {
    if (r.isApproved) return ToneColor.green;
    if (r.isRejected) return ToneColor.red;
    return ToneColor.amber;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                CdsAppBar(title: t.leaveDetailTitle),
                Expanded(child: _body(context, t)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations t) {
    if (_loading) return const SkeletonDetail(avatar: true);
    if (_error != null || _detail == null) {
      return ListView(
        children: <Widget>[
          StateMessage(
            icon: Icons.cloud_off_rounded,
            tone: ToneColor.red,
            title: t.leaveDetailCouldNotLoad,
            message: _error,
            actionLabel: t.commonTryAgain,
            onAction: _load,
          ),
        ],
      );
    }

    final LeaveRequest r = _detail!.request;
    final List<LeaveStep> steps = _detail!.steps;

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: <Widget>[
        GlassCard(
          radius: 18,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      r.leavVacTypeName.isEmpty
                          ? r.trTypeName
                          : r.leavVacTypeName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  StatusChip(label: r.displayStatus(t), tone: _statusTone(r)),
                ],
              ),
              if (r.userName.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  r.requesterLabel,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${r.fromDateTime}  →  ${r.toDateTime}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.subtleText,
                      ),
                    ),
                  ),
                  Text(
                    r.durationLabel(t),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
              if (r.notes.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  r.notes.trim(),
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.ink,
                  ),
                ),
              ],
              if (r.clients.isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                LeaveClientChips(request: r),
              ],
              if (r.isPending && r.hasPendingWith) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  t.leavePendingWith(r.pendingWithName),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.amber,
                  ),
                ),
              ],
              if (r.isRejected && r.rejectReason.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  t.rejectionReason(r.rejectReason.trim()),
                  style: const TextStyle(fontSize: 11, color: AppColors.red),
                ),
              ],
              if (r.hasAttachments) ...<Widget>[
                const SizedBox(height: 10),
                LeaveAttachmentsBadge(request: r),
              ],
            ],
          ),
        ),
        if (steps.isNotEmpty) ...<Widget>[
          const SizedBox(height: 18),
          ListLabel(label: t.leaveStepsTitle),
          _StepsTimeline(steps: steps, t: t),
        ],
        const SizedBox(height: 18),
        if (_busy)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.green,
              ),
            ),
          )
        else ...<Widget>[
          if (r.canDecide) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _reject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text(t.teamLeaveReject),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _approve,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: Text(t.teamLeaveApprove),
                  ),
                ),
              ],
            ),
            if (r.canForward) ...<Widget>[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _forward,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blue,
                    side: const BorderSide(color: AppColors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.forward_rounded, size: 16),
                  label: Text(t.leaveForwardTo(r.forwardToName)),
                ),
              ),
            ],
          ],
          if (r.canWithdraw) ...<Widget>[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _withdraw,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: const BorderSide(color: AppColors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.undo_rounded, size: 16),
                label: Text(t.leaveWithdraw),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// `steps`: `Submitted` / `Forwarded` / `Approved` / `Rejected`, e.g.
/// "دعاء حوّلته لأسامة · 10:15".
class _StepsTimeline extends StatelessWidget {
  const _StepsTimeline({required this.steps, required this.t});

  final List<LeaveStep> steps;
  final AppLocalizations t;

  String _line(LeaveStep s) => switch (s.action) {
    LeaveStepAction.submitted => t.leaveStepSubmitted(s.byLabel),
    LeaveStepAction.forwarded => t.leaveStepForwarded(s.byLabel, s.toLabel),
    LeaveStepAction.approved => t.leaveStepApproved(s.byLabel),
    LeaveStepAction.rejected => t.leaveStepRejected(s.byLabel),
    LeaveStepAction.unknown => s.byLabel,
  };

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: <Widget>[
          for (final (int i, LeaveStep s) in steps.indexed)
            Padding(
              padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          s.timeLabel.isEmpty
                              ? _line(s)
                              : '${_line(s)} · ${s.timeLabel}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.ink,
                          ),
                        ),
                        if (s.reason.trim().isNotEmpty) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(
                            s.reason.trim(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
