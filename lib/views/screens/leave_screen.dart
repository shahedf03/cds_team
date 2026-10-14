import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_formats.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/leave_request.dart';
import '../../models/transportation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/leave_provider.dart';
import '../../providers/loadable.dart';
import '../../routes/app_routes.dart';
import '../../services/leave_service.dart';
import '../widgets/cds_app_bar.dart';
import '../widgets/cds_dialogs.dart';
import '../widgets/common.dart';
import '../widgets/skeleton.dart';
import '../widgets/date_range_sheet.dart';
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
  Future<void> _attachReport(String transNo) async {
    final AppLocalizations t = AppLocalizations.of(context);
    final ImageSource? source = await showCdsOptionsSheet<ImageSource>(
      context,
      title: t.leaveAttachMedicalTitle,
      options: <CdsSheetOption<ImageSource>>[
        CdsSheetOption<ImageSource>(
          value: ImageSource.camera,
          icon: Icons.photo_camera_outlined,
          label: t.leaveTakePhoto,
        ),
        CdsSheetOption<ImageSource>(
          value: ImageSource.gallery,
          icon: Icons.photo_library_outlined,
          tone: ToneColor.blue,
          label: t.leaveChooseFromGallery,
        ),
      ],
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
    final String? attachmentId = await provider.uploadAttachment(
      transNo,
      fileBase64: fileBase64,
      contentType: contentType,
    );
    final bool ok = attachmentId != null;

    if (!mounted) return;
    showApiSnack(
      context,
      ok
          ? t.leaveMedicalReportAttached
          : (provider.error ?? t.leaveCouldNotAttach),
      isError: !ok,
    );
  }

  Future<void> _pickRange() async {
    final LeaveProvider provider = context.read<LeaveProvider>();
    final AuthProvider auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    final DateTimeRange? picked = await showCdsRangeSheet(
      context,
      initial: DateTimeRange(start: provider.range.from, end: provider.range.to),
    );
    if (picked == null) return;

    await provider.setRange(
      DateRange(picked.start, picked.end),
      userId: auth.user!.userId,
    );
  }

  Future<void> _newRequest() async {
    final LeaveSubmitted? saved = await showModalBottomSheet<LeaveSubmitted>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (BuildContext context) => LeaveEditorSheet(initialKind: _kind),
    );

    if (saved == null || !mounted) return;
    showApiSnack(
      context,
      AppLocalizations.of(context).leaveRequestSentToManager,
      isError: false,
    );

    // The create response carries the id, so the report can go straight on
    // without hunting for the new row in the list.
    if (saved.isSickLeave &&
        saved.transNo.isNotEmpty &&
        await _offerAttachNow() &&
        mounted) {
      await _attachReport(saved.transNo);
    }
  }

  Future<bool> _offerAttachNow() async {
    final AppLocalizations t = AppLocalizations.of(context);
    return showCdsConfirm(
      context,
      icon: Icons.medical_information_outlined,
      tone: ToneColor.blue,
      title: t.leaveAttachMedicalTitle,
      message: t.leaveAttachLaterMsg,
      cancelLabel: t.leaveLater,
      confirmLabel: t.leaveAttachNow,
    );
  }

  Future<void> _confirmDelete(LeaveRequest request) async {
    final AppLocalizations t = AppLocalizations.of(context);
    final bool confirmed = await showCdsConfirm(
      context,
      icon: Icons.event_busy_outlined,
      tone: ToneColor.red,
      title: t.leaveCancelRequestTitle,
      details: <String>[request.leavVacTypeName, request.fromDateTime],
      cancelLabel: t.leaveKeep,
      confirmLabel: t.leaveCancelRequest,
    );

    if (!confirmed || !mounted) return;

    final LeaveProvider provider = context.read<LeaveProvider>();
    final bool ok = await provider.delete(request.transNo);

    if (!mounted) return;
    showApiSnack(
      context,
      ok ? t.leaveRequestCancelled : (provider.error ?? t.leaveCouldNotCancel),
      isError: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
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
                CdsAppBar(title: t.leaveTitle),
                _SegmentedControl(
                  value: _kind,
                  onChanged: (LeaveKind kind) => setState(() => _kind = kind),
                ),
                const SizedBox(height: 16),
                if (_kind == LeaveKind.vacation &&
                    provider.balanceLoaded) ...<Widget>[
                  LeaveBalanceCard(balances: provider.balances),
                  const SizedBox(height: 12),
                ],
                DateRangePill(
                  fromLabel: ApiFormats.displayDate.format(provider.range.from),
                  toLabel: ApiFormats.displayDate.format(provider.range.to),
                  onTap: _pickRange,
                ),
                const SizedBox(height: 18),
                ListLabel(
                  label: t.leaveKindRequests(_kind.label(t)),
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
                      onAttach: (LeaveRequest r) => _attachReport(r.transNo),
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
        label: Text(
          t.leaveNewRequest,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Leaving / Vacation — drives `transType`.
class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({required this.value, required this.onChanged});

  final LeaveKind value;
  final ValueChanged<LeaveKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
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
                child: Text(
                  kind.label(t),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: active ? Colors.white : AppColors.muted,
                  ),
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
    final AppLocalizations t = AppLocalizations.of(context);
    if (provider.isLoading && provider.requests.isEmpty) {
      return SkeletonList(
        itemCount: 5,
        itemBuilder: (_, int i) => SkeletonRow(seed: i, thirdLine: true),
      );
    }

    if (provider.hasError && provider.requests.isEmpty) {
      return ListView(
        children: <Widget>[
          StateMessage(
            icon: Icons.cloud_off_rounded,
            tone: ToneColor.red,
            title: t.leaveCouldNotLoadRequests,
            message: provider.error,
            actionLabel: t.commonTryAgain,
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
            title: t.leaveNoKindRequests(kind.label(t).toLowerCase()),
            message: t.requestsInRangeMsg,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 110),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) => LeaveRequestCard(
        request: requests[index],
        onDelete: () => onDelete(requests[index]),
        onAttach: () => onAttach(requests[index]),
      ),
    );
  }
}

/// "11 days remaining of `typeName`" — one line per whole-day type.
/// `typeName` is the system code's own name, sent by the API in Arabic
/// regardless of the app's display language.
class LeaveBalanceCard extends StatelessWidget {
  const LeaveBalanceCard({super.key, required this.balances});

  final List<LeaveBalance> balances;

  static String _days(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1);

  static String _remaining(AppLocalizations t, double value) {
    final num count = value == value.roundToDouble() ? value.round() : value;
    return t.leaveRemainingOf(count);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: balances.isEmpty
          ? Text(
              t.leaveNoVacationBalance,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            )
          : Column(
              children: balances
                  .map(
                    (LeaveBalance b) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '${_remaining(t, b.remainingDays)} ${b.typeName}',
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
                  )
                  .toList(),
            ),
    );
  }
}

/// A leave request row. Delete and attach only appear when their callback
/// is given, so a manager's read-only view of someone else's list passes
/// neither.
class LeaveRequestCard extends StatelessWidget {
  const LeaveRequestCard({
    super.key,
    required this.request,
    this.onDelete,
    this.onAttach,
  });

  final LeaveRequest request;
  final VoidCallback? onDelete;
  final VoidCallback? onAttach;

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
              StatusChip(label: request.displayStatus(t), tone: _statusTone),
              if (request.hasAttachments) ...<Widget>[
                const SizedBox(width: 6),
                LeaveAttachmentsBadge(request: request),
              ],
              if (request.isSickLeave && onAttach != null)
                IconButton(
                  onPressed: onAttach,
                  tooltip: t.leaveAttachMedicalReportTooltip,
                  icon: const Icon(
                    Icons.attach_file_rounded,
                    size: 18,
                    color: AppColors.blue,
                  ),
                ),
              // 2026-10-07: the server says whether this can still be
              // withdrawn — was "Pending and not Approved", now `canWithdraw`.
              if (request.canWithdraw && onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  tooltip: t.leaveWithdraw,
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
                request.durationLabel(t),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
          if (request.clients.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            LeaveClientChips(request: request),
          ],
          if (request.isPending && request.hasPendingWith) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              t.leavePendingWith(request.pendingWithName),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.amber,
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
          ] else if (request.isApproved &&
              request.approvedBy.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              t.leaveApprovedBy(request.approvedBy.trim()),
              style: const TextStyle(fontSize: 10, color: AppColors.green),
            ),
          ],
        ],
      ),
    );
  }
}

/// 📍 chips for a "work leaving"'s client(s) (§F). Shared by the employee's
/// own list, the manager's "طلبات الفريق" inbox (so they can see it before
/// deciding) and the read-only member profile. Renders nothing for every
/// other type/category — `request.clients` is only ever non-empty here.
class LeaveClientChips extends StatelessWidget {
  const LeaveClientChips({super.key, required this.request});

  final LeaveRequest request;

  @override
  Widget build(BuildContext context) {
    if (request.clients.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: request.clients
          .map(
            (TransportationClient c) => StatusChip(
              label: c.clientName,
              tone: ToneColor.blue,
              icon: Icons.place_outlined,
            ),
          )
          .toList(),
    );
  }
}

/// 📎 count — tap opens the viewer. Shared by the employee's own list, the
/// manager's "طلبات الفريق" inbox (so they can see it before deciding) and
/// the read-only member profile.
class LeaveAttachmentsBadge extends StatelessWidget {
  const LeaveAttachmentsBadge({super.key, required this.request});

  final LeaveRequest request;

  @override
  Widget build(BuildContext context) {
    if (!request.hasAttachments) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => showLeaveAttachments(context, transNo: request.transNo),
      child: StatusChip(
        label: '${request.attachmentCount}',
        tone: ToneColor.blue,
        icon: Icons.attach_file_rounded,
      ),
    );
  }
}

/// Bottom sheet: thumbnails of every attachment on [transNo], tap for a
/// full-screen zoomable view. Read-only — no attach action here, that stays
/// on [LeaveRequestCard]'s own paperclip button.
Future<void> showLeaveAttachments(
  BuildContext context, {
  required String transNo,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (BuildContext context) => _AttachmentsSheet(transNo: transNo),
  );
}

class _AttachmentsSheet extends StatefulWidget {
  const _AttachmentsSheet({required this.transNo});

  final String transNo;

  @override
  State<_AttachmentsSheet> createState() => _AttachmentsSheetState();
}

class _AttachmentsSheetState extends State<_AttachmentsSheet> {
  late final Future<List<LeaveAttachment>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<LeaveService>().attachments(widget.transNo);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              t.leaveAttachmentsTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            FutureBuilder<List<LeaveAttachment>>(
              future: _future,
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<LeaveAttachment>> snapshot,
                  ) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: SkeletonThumbs(),
                      );
                    }
                    final List<LeaveAttachment>? items = snapshot.data;
                    if (snapshot.hasError || items == null) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          t.leaveCouldNotLoadAttachments,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.red,
                          ),
                        ),
                      );
                    }
                    if (items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          t.leaveNoAttachments,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 104,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (BuildContext context, int index) =>
                            _AttachmentThumb(attachment: items[index]),
                      ),
                    );
                  },
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentThumb extends StatefulWidget {
  const _AttachmentThumb({required this.attachment});

  final LeaveAttachment attachment;

  @override
  State<_AttachmentThumb> createState() => _AttachmentThumbState();
}

class _AttachmentThumbState extends State<_AttachmentThumb> {
  late final Future<Uint8List> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = context.read<LeaveService>().attachmentBytes(widget.attachment.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _thumbFrame(
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.green,
                ),
              ),
            ),
          );
        }
        final Uint8List? bytes = snapshot.data;
        if (snapshot.hasError || bytes == null) {
          return _thumbFrame(
            const Icon(Icons.broken_image_outlined, color: AppColors.muted),
          );
        }
        return GestureDetector(
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => _AttachmentViewer(bytes: bytes),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              bytes,
              width: 96,
              height: 96,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _thumbFrame(Widget child) => Container(
    width: 96,
    height: 96,
    decoration: BoxDecoration(
      color: AppColors.cardSoft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
}

/// Full-screen pinch-to-zoom view of one attachment.
class _AttachmentViewer extends StatelessWidget {
  const _AttachmentViewer({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.memory(bytes),
        ),
      ),
    );
  }
}
