import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_formats.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/attendance_record.dart';
import '../../models/leave_request.dart';
import '../../models/task_item.dart';
import '../../models/team.dart';
import '../../models/transportation.dart';
import '../../providers/loadable.dart';
import '../../providers/member_profile_provider.dart';
import '../../services/attendance_service.dart';
import '../../services/leave_service.dart';
import '../../services/tasks_service.dart';
import '../../services/transportation_service.dart';
import '../widgets/brand_logo.dart';
import '../widgets/cds_app_bar.dart';
import '../widgets/cds_refresh_indicator.dart';
import '../widgets/common.dart';
import '../widgets/skeleton.dart';
import '../widgets/date_range_sheet.dart';
import 'attendance_screen.dart' show AttendanceRow, AttendanceSummaryCard;
import 'leave_screen.dart' show LeaveBalanceCard, LeaveRequestCard;
import 'tasks_screen.dart' show TaskProjectCard, TaskSummary;
import 'transportation_screen.dart'
    show ReportViewer, TransportationEntryCard, TransportationTotals;

/// §12 — a team member's attendance, leaves (+ balance), tasks and
/// transportation (+ PDF), for their manager.
///
/// Read-only: it reuses the own-screens' cards without passing any of their
/// action callbacks, so there is no punch, no add/delete leave and no
/// add/edit transportation here. Every call carries the member's `userId`;
/// anything outside the manager's team comes back `403`, shown as that
/// section's message (never a logout).
class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({super.key, required this.member});

  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MemberProfileProvider>(
      create: (BuildContext context) => MemberProfileProvider(
        member: member,
        attendance: context.read<AttendanceService>(),
        leave: context.read<LeaveService>(),
        tasks: context.read<TasksService>(),
        transportation: context.read<TransportationService>(),
      )..loadAll(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final TeamMember member = context.select<MemberProfileProvider, TeamMember>(
      (MemberProfileProvider p) => p.member,
    );

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  CdsAppBar(title: member.label),
                  _Header(member: member),
                  const SizedBox(height: 12),
                  const _Tabs(),
                  const SizedBox(height: 12),
                  const Expanded(
                    child: TabBarView(
                      children: <Widget>[
                        _AttendanceTab(),
                        _LeavesTab(),
                        _TasksTab(),
                        _TransportationTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.member});

  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          UserAvatar(initials: member.initials, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  member.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  member.userId,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ),
          StatusChip(
            label: AppLocalizations.of(context).memberViewOnly,
            tone: ToneColor.blue,
            icon: Icons.visibility_outlined,
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.cardSoft,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(11),
        ),
        indicatorPadding: const EdgeInsets.all(3),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.muted,
        labelPadding: EdgeInsets.zero,
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
        tabs: <Widget>[
          Tab(text: t.memberTabAttendance),
          Tab(text: t.memberTabLeaves),
          Tab(text: t.memberTabTasks),
          Tab(text: t.memberTabTransportation),
        ],
      ),
    );
  }
}

/// One tab's list: spinner → error → empty → rows, with pull-to-refresh and
/// optional widgets above the rows.
class _SectionList<T> extends StatelessWidget {
  const _SectionList({
    required this.items,
    required this.loading,
    required this.loaded,
    required this.error,
    required this.onRefresh,
    required this.itemBuilder,
    required this.errorTitle,
    required this.empty,
    this.header = const <Widget>[],
    this.skeletonLeading = SkeletonLeading.icon,
  });

  final SkeletonLeading skeletonLeading;
  final List<T> items;
  final bool loading;
  final bool loaded;
  final String? error;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext context, int index, T item) itemBuilder;
  final String errorTitle;
  final StateMessage empty;
  final List<Widget> header;

  @override
  Widget build(BuildContext context) {
    final bool firstLoad = loading && !loaded && items.isEmpty;

    final List<Widget> children = <Widget>[
      ...header,
      if (firstLoad)
        SkeletonFadeIn(
          child: Shimmer(
            child: Column(
              children: <Widget>[
                for (int i = 0; i < 5; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SkeletonRow(seed: i, leading: skeletonLeading),
                  ),
              ],
            ),
          ),
        )
      else if (error != null && items.isEmpty)
        StateMessage(
          icon: Icons.lock_outline_rounded,
          tone: ToneColor.red,
          title: errorTitle,
          message: error,
          actionLabel: AppLocalizations.of(context).commonTryAgain,
          onAction: onRefresh,
        )
      else if (items.isEmpty)
        empty
      else
        for (int i = 0; i < items.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 8),
          itemBuilder(context, i, items[i]),
        ],
      const SizedBox(height: 40),
    ];

    return CdsRefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: children,
      ),
    );
  }
}

/// The open window, shared by attendance, leaves and transportation.
class _RangePill extends StatelessWidget {
  const _RangePill();

  Future<void> _pick(BuildContext context) async {
    final MemberProfileProvider provider = context
        .read<MemberProfileProvider>();
    final DateTimeRange? picked = await showCdsRangeSheet(
      context,
      initial: DateTimeRange(start: provider.range.from, end: provider.range.to),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    await provider.setRange(DateRange(picked.start, picked.end));
  }

  @override
  Widget build(BuildContext context) {
    final DateRange range = context.select<MemberProfileProvider, DateRange>(
      (MemberProfileProvider p) => p.range,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DateRangePill(
        fromLabel: ApiFormats.displayDate.format(range.from),
        toLabel: ApiFormats.displayDate.format(range.to),
        onTap: () => _pick(context),
      ),
    );
  }
}

class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final MemberProfileProvider p = context.watch<MemberProfileProvider>();
    final AttendanceRecord? today = p.todayRecord;
    final DateTime now = DateTime.now();
    final DateTime today0 = DateTime(now.year, now.month, now.day);
    final DateTime to0 = DateTime(p.range.to.year, p.range.to.month, p.range.to.day);
    // The card only makes sense while today falls inside the open window —
    // picking an older month hides it instead of showing a stale "Not punched".
    final bool rangeHasToday =
        !today0.isBefore(p.range.from) && !today0.isAfter(to0);

    final bool hasPunched = today?.start != null;
    final bool hasOpenSession = hasPunched && today?.end == null;
    final String statusLabel = !hasPunched
        ? t.statusNotPunched
        : hasOpenSession
        ? t.statusInSince(today!.start!)
        : t.statusInOut(today!.start!, today.end!);

    return _SectionList<AttendanceRecord>(
      skeletonLeading: SkeletonLeading.date,
      items: p.history.data,
      loading: p.history.loading,
      loaded: p.history.loaded,
      error: p.history.error,
      onRefresh: p.loadAttendance,
      errorTitle: t.attendanceCouldNotLoad,
      empty: StateMessage(
        icon: Icons.event_busy_rounded,
        title: t.attendanceNoRecords,
        message: t.attendanceNoRecordsMsg,
      ),
      header: <Widget>[
        const _RangePill(),
        if (p.history.loaded && p.history.error == null && rangeHasToday)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GlassCard(
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      t.memberToday,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  StatusChip(
                    label: statusLabel,
                    tone: !hasPunched
                        ? ToneColor.red
                        : hasOpenSession
                        ? ToneColor.green
                        : ToneColor.blue,
                    icon: Icons.fingerprint_rounded,
                  ),
                ],
              ),
            ),
          ),
        if (p.history.data.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: AttendanceSummaryCard(records: p.history.data),
          ),
      ],
      itemBuilder: (BuildContext context, int _, AttendanceRecord record) =>
          AttendanceRow(record: record),
    );
  }
}

class _LeavesTab extends StatelessWidget {
  const _LeavesTab();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final MemberProfileProvider p = context.watch<MemberProfileProvider>();

    return _SectionList<LeaveRequest>(
      items: p.leaves.data,
      loading: p.leaves.loading,
      loaded: p.leaves.loaded,
      error: p.leaves.error,
      onRefresh: p.loadLeaves,
      errorTitle: t.memberCouldNotLoadLeaveRequests,
      empty: StateMessage(
        icon: Icons.event_available_outlined,
        tone: ToneColor.blue,
        title: t.memberNoLeaveRequests,
        message: t.requestsInRangeMsg,
      ),
      header: <Widget>[
        const _RangePill(),
        if (p.balances.loaded && p.balances.error == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: LeaveBalanceCard(balances: p.balances.data),
          ),
      ],
      // No delete / attach callbacks: this list is read-only.
      itemBuilder: (BuildContext context, int _, LeaveRequest request) =>
          LeaveRequestCard(request: request),
    );
  }
}

class _TasksTab extends StatelessWidget {
  const _TasksTab();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final MemberProfileProvider p = context.watch<MemberProfileProvider>();

    return _SectionList<TaskProject>(
      items: p.projects,
      loading: p.tasks.loading,
      loaded: p.tasks.loaded,
      error: p.tasks.error,
      onRefresh: p.loadTasks,
      errorTitle: t.tasksCouldNotLoad,
      empty: StateMessage(
        icon: Icons.task_alt_rounded,
        title: t.tasksNoneAssigned,
        message: t.tasksNoneAssignedMemberMsg,
      ),
      header: <Widget>[
        TaskSummary(done: p.doneTasks, total: p.tasks.data.length),
        const SizedBox(height: 18),
        ListLabel(label: t.tasksProjects),
      ],
      itemBuilder: (BuildContext context, int index, TaskProject project) =>
          TaskProjectCard(
            project: project,
            initiallyExpanded: index == 0,
            tone: index.isEven ? ToneColor.green : ToneColor.amber,
          ),
    );
  }
}

class _TransportationTab extends StatelessWidget {
  const _TransportationTab();

  Future<void> _openReport(BuildContext context) async {
    final MemberProfileProvider p = context.read<MemberProfileProvider>();
    try {
      final bytes = await p.report();
      if (!context.mounted) return;
      final String filename =
          'transportation_${p.member.userId}'
          '_${ApiFormats.toQueryDate(p.range.from)}'
          '_${ApiFormats.toQueryDate(p.range.to)}.pdf';
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ReportViewer(bytes: bytes, filename: filename),
        ),
      );
    } on ApiException catch (e) {
      // 403 = not on this manager's team; a message, never a logout.
      if (context.mounted) showApiSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final MemberProfileProvider p = context.watch<MemberProfileProvider>();

    return _SectionList<Transportation>(
      skeletonLeading: SkeletonLeading.date,
      items: p.trips.data,
      loading: p.trips.loading,
      loaded: p.trips.loaded,
      error: p.trips.error,
      onRefresh: p.loadTrips,
      errorTitle: t.transportationCouldNotLoadEntries,
      empty: StateMessage(
        icon: Icons.directions_car_filled_outlined,
        tone: ToneColor.amber,
        title: t.transportationNoEntriesMember,
        message: t.transportationNoTripsMemberMsg,
      ),
      header: <Widget>[
        const _RangePill(),
        TransportationTotals(
          km: p.totalKm,
          amount: p.totalAmount,
          count: p.trips.data.length,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: p.isExportingReport
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.green,
                    ),
                  ),
                )
              : TextButton.icon(
                  onPressed: () => _openReport(context),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: Text(t.transportationOpenReportPdf),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.green,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        ListLabel(label: t.transportationEntriesLabel),
      ],
      // No edit / delete callbacks: this list is read-only.
      itemBuilder: (BuildContext context, int _, Transportation entry) =>
          TransportationEntryCard(entry: entry),
    );
  }
}
