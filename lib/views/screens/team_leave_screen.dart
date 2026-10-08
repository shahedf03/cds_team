import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_formats.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/leave_request.dart';
import '../../providers/loadable.dart';
import '../../providers/team_leave_provider.dart';
import '../../providers/team_provider.dart';
import '../../routes/app_routes.dart';
import '../widgets/cds_app_bar.dart';
import '../widgets/common.dart';
import 'leave_screen.dart'
    show LeaveAttachmentsBadge, LeaveClientChips, showLeaveAttachments;

/// §11 — "Team requests": requests from everyone under the manager. Approve /
/// reject only appear on the ones the manager is the direct manager of
/// (`canDecide`).
class TeamLeaveScreen extends StatefulWidget {
  const TeamLeaveScreen({super.key});

  @override
  State<TeamLeaveScreen> createState() => _TeamLeaveScreenState();
}

class _TeamLeaveScreenState extends State<TeamLeaveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() => context.read<TeamLeaveProvider>().load();

  Future<void> _pickRange() async {
    final TeamLeaveProvider provider = context.read<TeamLeaveProvider>();
    final DateRange? current = provider.range;
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDateRange: current == null
          ? null
          : DateTimeRange(start: current.from, end: current.to),
    );
    if (picked == null) return;
    await provider.setRange(DateRange(picked.start, picked.end));
  }

  Future<void> _approve(LeaveRequest request) async {
    final AppLocalizations t = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t.teamLeaveApproveTitle,
          style: const TextStyle(fontSize: 16),
        ),
        content: Text(
          '${request.requesterLabel} · ${request.leavVacTypeName}\n'
          '${request.fromDateTime}  →  ${request.toDateTime}',
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.green),
            child: Text(t.teamLeaveApprove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final (DecisionOutcome outcome, String? message) = await context
        .read<TeamLeaveProvider>()
        .approve(request.transNo);
    if (mounted) _report(outcome, message, success: t.teamLeaveApproved);
  }

  Future<void> _reject(LeaveRequest request) async {
    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _RejectDialog(request: request),
    );
    if (reason == null || !mounted) return;

    final (DecisionOutcome outcome, String? message) = await context
        .read<TeamLeaveProvider>()
        .reject(request.transNo, reason: reason);
    if (mounted) {
      _report(
        outcome,
        message,
        success: AppLocalizations.of(context).teamLeaveRejected,
      );
    }
  }

  Future<void> _forward(LeaveRequest request) async {
    final String? note = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _ForwardDialog(request: request),
    );
    if (note == null || !mounted) return;

    final (DecisionOutcome outcome, String? message) = await context
        .read<TeamLeaveProvider>()
        .forward(request.transNo, note: note.isEmpty ? null : note);
    if (mounted) {
      _report(
        outcome,
        message,
        success: AppLocalizations.of(context).leaveForwarded,
      );
    }
  }

  void _report(
    DecisionOutcome outcome,
    String? message, {
    required String success,
  }) {
    final AppLocalizations t = AppLocalizations.of(context);
    switch (outcome) {
      case DecisionOutcome.done:
        showApiSnack(context, success, isError: false);
      case DecisionOutcome.forbidden:
        showApiSnack(context, t.teamLeaveForbidden);
      case DecisionOutcome.alreadyDecided:
        showApiSnack(context, message ?? t.teamLeaveAlreadyDecided);
      case DecisionOutcome.notFound:
        showApiSnack(context, t.teamLeaveNotFound);
      case DecisionOutcome.failed:
        showApiSnack(context, message ?? t.teamLeaveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final TeamLeaveProvider provider = context.watch<TeamLeaveProvider>();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                CdsAppBar(title: t.teamLeaveTitle),
                _ChoiceRow<ApprovalFilter>(
                  values: ApprovalFilter.values,
                  selected: provider.status,
                  labelOf: (ApprovalFilter f, AppLocalizations t) => f.label(t),
                  onSelected: provider.setStatus,
                ),
                const SizedBox(height: 8),
                _ChoiceRow<LeaveKind?>(
                  values: const <LeaveKind?>[
                    null,
                    LeaveKind.leaving,
                    LeaveKind.vacation,
                  ],
                  selected: provider.kind,
                  labelOf: (LeaveKind? k, AppLocalizations t) =>
                      k?.label(t) ?? t.filterAll,
                  onSelected: provider.setKind,
                ),
                const SizedBox(height: 8),
                _ExtraFilters(provider: provider, onPickRange: _pickRange),
                const SizedBox(height: 14),
                ListLabel(
                  label: t.teamLeaveRequestsLabel,
                  trailing: provider.requests.isEmpty
                      ? null
                      : '${provider.requests.length}',
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.green,
                    backgroundColor: Colors.white,
                    onRefresh: _refresh,
                    child: _Body(
                      provider: provider,
                      onRetry: _refresh,
                      onApprove: _approve,
                      onReject: _reject,
                      onForward: _forward,
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

/// A horizontally scrolling single-choice chip row.
class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T, AppLocalizations) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (BuildContext context, int i) {
          final T value = values[i];
          final bool active = value == selected;
          return GestureDetector(
            onTap: active ? null : () => onSelected(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.ink : const Color(0x99FFFFFF),
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                labelOf(value, t),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.muted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Optional date range + employee picker, each clearable.
class _ExtraFilters extends StatelessWidget {
  const _ExtraFilters({required this.provider, required this.onPickRange});

  final TeamLeaveProvider provider;
  final VoidCallback onPickRange;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final DateRange? range = provider.range;
    final Map<String, String> employees = context
        .watch<TeamProvider>()
        .employees;
    final String? employeeId = provider.employeeId;

    return Row(
      children: <Widget>[
        Expanded(
          child: _FilterPill(
            icon: Icons.date_range_outlined,
            label: range == null
                ? t.teamLeaveAllDates
                : '${ApiFormats.displayDate.format(range.from)} – '
                      '${ApiFormats.displayDate.format(range.to)}',
            onTap: onPickRange,
            onClear: range == null ? null : () => provider.setRange(null),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PopupMenuButton<String>(
            enabled: employees.isNotEmpty,
            color: AppColors.cream,
            onSelected: provider.setEmployee,
            itemBuilder: (BuildContext context) => employees.entries
                .map(
                  (MapEntry<String, String> e) => PopupMenuItem<String>(
                    value: e.key,
                    child: Text(e.value, style: const TextStyle(fontSize: 13)),
                  ),
                )
                .toList(),
            child: _FilterPill(
              icon: Icons.person_outline_rounded,
              label: employeeId == null
                  ? t.teamLeaveAllEmployees
                  : (employees[employeeId] ?? employeeId),
              onClear: employeeId == null
                  ? null
                  : () => provider.setEmployee(null),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    this.onTap,
    this.onClear,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final Widget pill = Container(
      height: 36,
      padding: const EdgeInsets.only(left: 10, right: 4),
      decoration: BoxDecoration(
        color: const Color(0x99FFFFFF),
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 15, color: AppColors.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.ink),
            ),
          ),
          if (onClear != null)
            GestureDetector(
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: AppColors.muted,
                ),
              ),
            ),
        ],
      ),
    );
    return onTap == null ? pill : GestureDetector(onTap: onTap, child: pill);
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.provider,
    required this.onRetry,
    required this.onApprove,
    required this.onReject,
    required this.onForward,
  });

  final TeamLeaveProvider provider;
  final VoidCallback onRetry;
  final void Function(LeaveRequest) onApprove;
  final void Function(LeaveRequest) onReject;
  final void Function(LeaveRequest) onForward;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    if (provider.isLoading && provider.requests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }

    if (provider.hasError && provider.requests.isEmpty) {
      return ListView(
        children: <Widget>[
          StateMessage(
            icon: Icons.cloud_off_rounded,
            tone: ToneColor.red,
            title: t.teamLeaveCouldNotLoad,
            message: provider.error,
            actionLabel: t.commonTryAgain,
            onAction: onRetry,
          ),
        ],
      );
    }

    if (provider.requests.isEmpty) {
      return ListView(
        children: <Widget>[
          StateMessage(
            icon: Icons.inbox_outlined,
            tone: ToneColor.blue,
            title: t.teamLeaveNoRequests,
            message: t.teamLeaveMatchingMsg,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 40),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: provider.requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final LeaveRequest r = provider.requests[index];
        return _TeamRequestCard(
          request: r,
          busy: provider.isDeciding(r.transNo),
          onApprove: () => onApprove(r),
          onReject: () => onReject(r),
          onForward: () => onForward(r),
        );
      },
    );
  }
}

class _TeamRequestCard extends StatelessWidget {
  const _TeamRequestCard({
    required this.request,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onForward,
  });

  final LeaveRequest request;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onForward;

  ToneColor get _statusTone {
    if (request.isApproved) return ToneColor.green;
    if (request.isRejected) return ToneColor.red;
    return ToneColor.amber;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return GlassCard(
      onTap: () => Navigator.of(
        context,
      ).pushNamed(AppRoutes.leaveDetail, arguments: request.transNo),
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  request.requesterLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (request.hasAttachments) ...<Widget>[
                LeaveAttachmentsBadge(request: request),
                const SizedBox(width: 6),
              ],
              StatusChip(label: request.displayStatus(t), tone: _statusTone),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${request.kind.label(t)} · '
            '${request.leavVacTypeName.isEmpty ? request.trTypeName : request.leavVacTypeName}',
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
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
                  '${request.fromDateTime}  →  ${request.toDateTime}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8A9693),
                  ),
                ),
              ),
              Text(
                request.durationLabel(t),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green,
                ),
              ),
            ],
          ),
          if (request.clients.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            LeaveClientChips(request: request),
          ],
          if (request.notes.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              request.notes.trim(),
              style: const TextStyle(
                fontSize: 11,
                height: 1.45,
                color: AppColors.ink,
              ),
            ),
          ],
          if (request.isRejected &&
              request.rejectReason.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              t.rejectionReason(request.rejectReason.trim()),
              style: const TextStyle(fontSize: 10, color: AppColors.red),
            ),
          ],
          // Server says who may decide: the direct manager, while Pending —
          // surface the medical report right above the decision so it's
          // seen before approving/rejecting, not just the small badge above.
          if (request.canDecide && request.hasAttachments) ...<Widget>[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () =>
                  showLeaveAttachments(context, transNo: request.transNo),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blue,
                side: const BorderSide(color: AppColors.blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.attach_file_rounded, size: 16),
              label: Text(t.leaveViewMedicalReport),
            ),
          ],
          if (request.canDecide) ...<Widget>[
            const SizedBox(height: 12),
            if (busy)
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.green,
                  ),
                ),
              )
            else
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
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
                      onPressed: onApprove,
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
            // 2026-10-07 — only alongside Approve/Reject, forwards to the
            // caller's own AttendanceParent ?? Parent.
            if (request.canForward && !busy) ...<Widget>[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onForward,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blue,
                    side: const BorderSide(color: AppColors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.forward_rounded, size: 16),
                  label: Text(t.leaveForwardTo(request.forwardToName)),
                ),
              ),
            ],
          ] else if (request.isPending) ...<Widget>[
            // Someone else decides it now — name them when the server says
            // who (2026-10-07's `pendingWithName`), else the old generic line.
            const SizedBox(height: 8),
            Text(
              request.hasPendingWith
                  ? t.leavePendingWith(request.pendingWithName)
                  : t.teamLeaveWaitingDirectManager,
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Reject needs a reason — the employee sees it in the push and the list.
class _RejectDialog extends StatefulWidget {
  const _RejectDialog({required this.request});

  final LeaveRequest request;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_reason.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        t.teamLeaveRejectDialogTitle,
        style: const TextStyle(fontSize: 16),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${widget.request.requesterLabel} · '
              '${widget.request.leavVacTypeName}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reason,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(hintText: t.teamLeaveRejectionHint),
              validator: (String? v) => (v == null || v.trim().isEmpty)
                  ? t.teamLeaveReasonRequired
                  : null,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            t.commonCancel,
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.red),
          child: Text(t.teamLeaveReject),
        ),
      ],
    );
  }
}

/// Forward — note is optional, unlike reject's reason.
class _ForwardDialog extends StatefulWidget {
  const _ForwardDialog({required this.request});

  final LeaveRequest request;

  @override
  State<_ForwardDialog> createState() => _ForwardDialogState();
}

class _ForwardDialogState extends State<_ForwardDialog> {
  final TextEditingController _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: AppColors.cream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        t.leaveForwardTo(widget.request.forwardToName),
        style: const TextStyle(fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${widget.request.requesterLabel} · '
            '${widget.request.leavVacTypeName}',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            autofocus: true,
            maxLines: 3,
            decoration: InputDecoration(hintText: t.leaveForwardNoteHint),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            t.commonCancel,
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_note.text.trim()),
          style: FilledButton.styleFrom(backgroundColor: AppColors.blue),
          child: Text(t.leaveForwardButton),
        ),
      ],
    );
  }
}
