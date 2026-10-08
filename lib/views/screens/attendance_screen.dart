import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_formats.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/attendance_record.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loadable.dart';
import '../widgets/cds_app_bar.dart';
import '../widgets/common.dart';

/// §3 — attendance history with From/To pickers and red-highlighted late rows.
class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key, this.embedded = false});

  /// True when hosted inside the bottom-nav shell (no back button, no
  /// Scaffold of its own).
  final bool embedded;

  Future<void> _pickRange(BuildContext context) async {
    final AttendanceProvider provider = context.read<AttendanceProvider>();
    final AuthProvider auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: provider.range.from,
        end: provider.range.to,
      ),
      builder: (BuildContext context, Widget? child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.green),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;
    await provider.setRange(
      DateRange(picked.start, picked.end),
      userId: auth.user!.userId,
    );
  }

  Future<void> _refresh(BuildContext context) async {
    final AuthProvider auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    await context.read<AttendanceProvider>().load(userId: auth.user!.userId);
  }

  Future<void> _setSource(BuildContext context, AttendanceSource source) async {
    final AuthProvider auth = context.read<AuthProvider>();
    if (auth.user == null) return;
    await context.read<AttendanceProvider>().setSource(
      source,
      userId: auth.user!.userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final AttendanceProvider provider = context.watch<AttendanceProvider>();

    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!embedded) CdsAppBar(title: t.attendanceScreenTitle),
        DateRangePill(
          fromLabel: ApiFormats.displayDate.format(provider.range.from),
          toLabel: ApiFormats.displayDate.format(provider.range.to),
          onTap: () => _pickRange(context),
        ),
        const SizedBox(height: 12),
        _SourceTabs(
          value: provider.source,
          onChanged: (AttendanceSource source) => _setSource(context, source),
        ),
        const SizedBox(height: 12),
        ListLabel(
          label: t.attendanceDailyLog,
          trailing: provider.records.isEmpty
              ? null
              : t.attendanceEntriesCount(provider.records.length),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.green,
            backgroundColor: Colors.white,
            onRefresh: () => _refresh(context),
            child: _Body(provider: provider, onRetry: () => _refresh(context)),
          ),
        ),
      ],
    );

    if (embedded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
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

/// بصمة الجهاز / بصمة الموبايل — each tab is its own `source=` call
/// ([AttendanceProvider.setSource]), same From/To range for both.
class _SourceTabs extends StatelessWidget {
  const _SourceTabs({required this.value, required this.onChanged});

  final AttendanceSource value;
  final ValueChanged<AttendanceSource> onChanged;

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
        children: AttendanceSource.values.map((AttendanceSource source) {
          final bool active = source == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(source),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: active ? AppColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  source == AttendanceSource.device
                      ? t.attendanceByDevice
                      : t.attendanceByMobile,
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
  const _Body({required this.provider, required this.onRetry});

  final AttendanceProvider provider;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    if (provider.isLoading && provider.records.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
    }

    if (provider.hasError && provider.records.isEmpty) {
      return ListView(
        children: <Widget>[
          StateMessage(
            icon: Icons.cloud_off_rounded,
            tone: ToneColor.red,
            title: t.attendanceCouldNotLoad,
            // The API's own `error` message, not a generic one.
            message: provider.error,
            actionLabel: t.commonTryAgain,
            onAction: onRetry,
          ),
        ],
      );
    }

    if (provider.records.isEmpty) {
      return ListView(
        children: <Widget>[
          StateMessage(
            icon: Icons.event_busy_rounded,
            title: t.attendanceNoRecords,
            message: t.attendanceNoRecordsMsg,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 100),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: provider.records.length,
      separatorBuilder: (_, _) => const SizedBox(height: 7),
      itemBuilder: (BuildContext context, int index) =>
          AttendanceRow(record: provider.records[index]),
    );
  }
}

class AttendanceRow extends StatelessWidget {
  const AttendanceRow({super.key, required this.record});

  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    // Server-computed since 2026-10-05 (Start after Attendance:LateAfter).
    final bool late = record.isLate;

    // Only phone punches carry this — always null on a pure device-tab row.
    final bool outsideSite = record.withinGeofence == false;

    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: late ? AppColors.lateRow : AppColors.cardSolid,
        border: Border.all(
          color: late ? AppColors.red : AppColors.green,
          width: 1.4,
        ),
        borderRadius: BorderRadius.circular(17),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: (late ? AppColors.red : AppColors.green).withValues(
              alpha: late ? 0.22 : 0.14,
            ),
            blurRadius: late ? 16 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                padding: const EdgeInsets.only(right: 10),
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: AppColors.line)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      record.dayNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      record.monthLabel,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF8B9693),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LogTime(
                  label: t.attendanceStart,
                  value: record.startLabel,
                ),
              ),
              Expanded(
                child: _LogTime(label: t.attendanceEnd, value: record.endLabel),
              ),
              if (late)
                StatusChip(
                  label: t.attendanceLate,
                  tone: ToneColor.red,
                  icon: Icons.bolt_rounded,
                )
              else
                const Icon(
                  Icons.check_rounded,
                  size: 17,
                  color: AppColors.green,
                ),
            ],
          ),
          if (outsideSite) ...<Widget>[
            const SizedBox(height: 8),
            StatusChip(
              label: t.appOutsideWorkSite,
              tone: ToneColor.red,
              icon: Icons.location_off_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _LogTime extends StatelessWidget {
  const _LogTime({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 8,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w800,
            color: AppColors.faintText,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
