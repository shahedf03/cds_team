import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_formats.dart';
import '../../models/leave_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../providers/loadable.dart';
import '../widgets/cds_app_bar.dart';
import '../widgets/common.dart';
import 'leave_editor_sheet.dart';

/// §9 — Leaving/Vacation segmented control, request list, delete.
class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  LeaveKind _kind = LeaveKind.leaving;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaveProvider>().loadSystemCodes();
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final AuthProvider auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    final LeaveProvider provider = context.read<LeaveProvider>();
    await Future.wait<void>(<Future<void>>[
      provider.load(userId: auth.user!.userId),
      provider.loadBalance(userId: auth.user!.userId),
    ]);
  }

  /// Medical report for a sick-leave request: camera or gallery → base64.
  Future<void> _attachReport(LeaveRequest request) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.ink,
                ),
                title: const Text('Take a photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.ink,
                ),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    final XFile? file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 75,
    );
    if (file == null || !mounted) return;

    final String contentType = file.path.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';
    final String fileBase64 = base64Encode(await file.readAsBytes());
    if (!mounted) return;

    final LeaveProvider provider = context.read<LeaveProvider>();
    final bool ok = await provider.uploadAttachment(
      request.transNo,
      fileBase64: fileBase64,
      contentType: contentType,
    );

    if (!mounted) return;
    showApiSnack(
      context,
      ok
          ? 'Medical report attached.'
          : (provider.error ?? 'Could not attach the report.'),
      isError: !ok,
    );
  }

  Future<void> _pickRange() async {
    final LeaveProvider provider = context.read<LeaveProvider>();
    final AuthProvider auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDateRange: DateTimeRange(
        start: provider.range.from,
        end: provider.range.to,
      ),
    );
    if (picked == null) return;

    await provider.setRange(
      DateRange(picked.start, picked.end),
      userId: auth.user!.userId,
    );
  }

  Future<void> _newRequest() async {
    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (BuildContext context) => LeaveEditorSheet(initialKind: _kind),
    );

    if (saved == true && mounted) {
      showApiSnack(context, 'Request submitted.', isError: false);
    }
  }

  Future<void> _confirmDelete(LeaveRequest request) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel this request?', style: TextStyle(fontSize: 16)),
        content: Text(
          '${request.leavVacTypeName} · ${request.fromDateTime}',
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep', style: TextStyle(color: AppColors.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final LeaveProvider provider = context.read<LeaveProvider>();
    final bool ok = await provider.delete(request.transNo);

    if (!mounted) return;
    showApiSnack(
      context,
      ok
          ? 'Request cancelled.'
          : (provider.error ?? 'Could not cancel the request.'),
      isError: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final LeaveProvider provider = context.watch<LeaveProvider>();
    final List<LeaveRequest> visible = provider.ofKind(_kind);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const CdsAppBar(title: 'Leave & vacation'),
                _SegmentedControl(
                  value: _kind,
                  onChanged: (LeaveKind kind) => setState(() => _kind = kind),
                ),
                const SizedBox(height: 16),
                if (_kind == LeaveKind.vacation && provider.balanceLoaded) ...<Widget>[
                  _BalanceCard(balances: provider.balances),
                  const SizedBox(height: 12),
                ],
                DateRangePill(
                  fromLabel: ApiFormats.displayDate.format(provider.range.from),
                  toLabel: ApiFormats.displayDate.format(provider.range.to),
                  onTap: _pickRange,
                ),
                const SizedBox(height: 18),
                ListLabel(
                  label: '${_kind.labelEn} requests',
                  trailing: visible.isEmpty ? null : '${visible.length}',
                ),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.green,
                    backgroundColor: Colors.white,
                    onRefresh: _refresh,
                    child: _Body(
                      provider: provider,
                      requests: visible,
                      kind: _kind,
                      onRetry: _refresh,
                      onDelete: _confirmDelete,
                      onAttach: _attachReport,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newRequest,
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'New request',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Leaving (مغادرة) / Vacation (إجازة) — drives `transType`.
class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({required this.value, required this.onChanged});

  final LeaveKind value;
  final ValueChanged<LeaveKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x99FFFFFF),
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: LeaveKind.values.map((LeaveKind kind) {
          final bool active = kind == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(kind),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: active ? AppColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      kind.labelEn,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: active ? Colors.white : AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      kind.labelAr,
                      style: TextStyle(
                        fontSize: 11,
                        color: active ? Colors.white70 : AppColors.faintText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.provider,
    required this.requests,
    required this.kind,
    required this.onRetry,
    required this.onDelete,
    required this.onAttach,
  });

  final LeaveProvider provider;
  final List<LeaveRequest> requests;
  final LeaveKind kind;
  final VoidCallback onRetry;
  final void Function(LeaveRequest) onDelete;
  final void Function(LeaveRequest) onAttach;

  @override
  Widget build(BuildContext context) {
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
            title: 'Could not load requests',
            message: provider.error,
            actionLabel: 'Try again',
            onAction: onRetry,
          ),
        ],
      );
    }

    if (requests.isEmpty) {
      return ListView(
        children: <Widget>[
          StateMessage(
            icon: Icons.event_available_outlined,
            tone: ToneColor.blue,
            title: 'No ${kind.labelEn.toLowerCase()} requests',
            message: 'Requests in the selected dates will appear here.',
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 110),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) => _RequestCard(
        request: requests[index],
        onDelete: () => onDelete(requests[index]),
        onAttach: () => onAttach(requests[index]),
      ),
    );
  }
}

/// "11 يوم متبقي من الإجازة السنوية" — one line per whole-day type.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balances});

  final List<LeaveBalance> balances;

  static String _days(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: balances.isEmpty
          ? const Text(
              'No vacation balance set for this year.',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            )
          : Column(
              children: balances
                  .map(
                    (LeaveBalance b) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                '${_days(b.remainingDays)} يوم متبقي من ${b.typeName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            Text(
                              '${_days(b.usedDays)} / ${_days(b.totalDays)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onDelete,
    required this.onAttach,
  });

  final LeaveRequest request;
  final VoidCallback onDelete;
  final VoidCallback onAttach;

  ToneColor get _statusTone {
    if (request.isApproved) return ToneColor.green;
    if (request.isRejected) return ToneColor.red;
    return ToneColor.amber;
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  request.leavVacTypeName.isEmpty
                      ? request.trTypeName
                      : request.leavVacTypeName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              StatusChip(label: request.statusLabel, tone: _statusTone),
              if (request.isSickLeave)
                IconButton(
                  onPressed: onAttach,
                  tooltip: 'Attach medical report',
                  icon: const Icon(
                    Icons.attach_file_rounded,
                    size: 18,
                    color: AppColors.blue,
                  ),
                ),
              // Only a pending request can still be withdrawn.
              if (request.isPending)
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Cancel request',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: AppColors.red,
                  ),
                )
              else
                const SizedBox(width: 8),
            ],
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
                request.durationLabel,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
          if (request.isRejected && request.rejectReason.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Rejected'
              '${request.approvedBy.trim().isEmpty ? '' : ' by ${request.approvedBy.trim()}'}'
              ': ${request.rejectReason.trim()}',
              style: const TextStyle(fontSize: 10, color: AppColors.red),
            ),
          ] else if (request.isApproved &&
              request.approvedBy.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              'Approved by ${request.approvedBy.trim()}',
              style: const TextStyle(fontSize: 10, color: AppColors.green),
            ),
          ],
        ],
      ),
    );
  }
}
