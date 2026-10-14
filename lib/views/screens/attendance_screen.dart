import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_formats.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/attendance_record.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loadable.dart';
import '../widgets/cds_app_bar.dart';
import '../widgets/cds_refresh_indicator.dart';
import '../widgets/common.dart';
import '../widgets/skeleton.dart';
import '../widgets/date_range_sheet.dart';

/// §3 — attendance history: period filter, device/mobile source, a summary
/// of the period and one row per day.
class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key, this.embedded = false});

  /// True when hosted inside the bottom-nav shell (no back button, no
  /// Scaffold of its own).
  final bool embedded;

  Future<void> _pickRange(BuildContext context) async {
    final AttendanceProvider provider = context.read<AttendanceProvider>();
    final AuthProvider auth = context.read<AuthProvider>();
    if (auth.user == null) return;

    final DateTimeRange? picked = await showCdsRangeSheet(
      context,
      initial: DateTimeRange(start: provider.range.from, end: provider.range.to),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
        const SizedBox(height: 10),
        _SourceTabs(
          value: provider.source,
          onChanged: (AttendanceSource source) => _setSource(context, source),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: CdsRefreshIndicator(
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

  static const Duration _duration = Duration(milliseconds: 320);
  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final bool deviceActive = value == AttendanceSource.device;

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x99FFFFFF),
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: <Widget>[
          // One thumb that slides between the halves (direction-aware).
          AnimatedAlign(
            duration: _duration,
            curve: _curve,
            alignment: deviceActive ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(color: Color(0x3325333B), blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: <Widget>[
              for (final AttendanceSource source in AttendanceSource.values)
                Expanded(
                  child: _SourceTab(
                    icon: source == AttendanceSource.device ? Icons.fingerprint_rounded : Icons.smartphone_rounded,
                    label: source == AttendanceSource.device ? t.attendanceByDevice : t.attendanceByMobile,
                    active: source == value,
                    onTap: source == value ? null : () => onChanged(source),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SourceTab extends StatelessWidget {
  const _SourceTab({required this.icon, required this.label, required this.active, this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = active ? Colors.white : AppColors.muted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.transparent,
        highlightColor: AppColors.ink.withValues(alpha: 0.04),
        child: Center(
          child: TweenAnimationBuilder<Color?>(
            duration: _SourceTabs._duration,
            curve: _SourceTabs._curve,
            tween: ColorTween(end: color),
            builder: (BuildContext context, Color? c, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AnimatedScale(
                  duration: _SourceTabs._duration,
                  curve: Curves.easeOutBack,
                  scale: active ? 1.12 : 1,
                  child: Icon(icon, size: 17, color: c),
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: c),
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

  final AttendanceProvider provider;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    if (provider.isLoading && provider.records.isEmpty) {
      return SkeletonList(
        itemCount: 6,
        header: const <Widget>[
          SkeletonSummaryCard(),
          SizedBox(height: 18),
          Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: BoneLine(widthFactor: 0.25, height: 9),
          ),
        ],
        itemBuilder: (_, int i) => SkeletonRow(seed: i, leading: SkeletonLeading.date),
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

    final List<AttendanceRecord> records = provider.records;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 110),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: records.length + 2,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: AttendanceSummaryCard(records: records),
          );
        }
        if (index == 1) {
          return ListLabel(
            label: t.attendanceDailyLog,
            trailing: t.attendanceEntriesCount(records.length),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AttendanceRow(record: records[index - 2]),
        );
      },
    );
  }
}

/// Worked time between the day's first and last punch, or `null`.
Duration? _worked(AttendanceRecord r) {
  final DateTime? a = r.startedAt;
  final DateTime? b = r.endedAt;
  if (a == null || b == null || !b.isAfter(a)) return null;
  return b.difference(a);
}

String _hm(Duration d) => '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}';

/// Days · On time · Late · Avg. hours for the visible period.
class AttendanceSummaryCard extends StatelessWidget {
  const AttendanceSummaryCard({super.key, required this.records});

  final List<AttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final int days = records.length;
    final int late = records.where((AttendanceRecord r) => r.isLate).length;
    final int onTime = days - late;
    final List<Duration> worked = records.map(_worked).whereType<Duration>().toList();
    final Duration? avg = worked.isEmpty
        ? null
        : Duration(minutes: worked.fold<int>(0, (int s, Duration d) => s + d.inMinutes) ~/ worked.length);
    final double onTimeRate = days == 0 ? 0 : onTime / days;

    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              _Stat(value: '$days', label: t.attendanceDaysWorked, color: AppColors.ink),
              _divider(),
              _Stat(value: '$onTime', label: t.attendanceOnTime, color: AppColors.green),
              _divider(),
              _Stat(value: '$late', label: t.attendanceLate, color: late > 0 ? AppColors.red : AppColors.ink),
              _divider(),
              _Stat(value: avg == null ? '--' : _hm(avg), label: t.attendanceAvgHours, color: AppColors.ink),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 6,
              child: Row(
                children: <Widget>[
                  if (onTime > 0) Expanded(flex: onTime, child: Container(color: AppColors.green)),
                  if (late > 0) Expanded(flex: late, child: Container(color: AppColors.red)),
                  if (days == 0) Expanded(child: Container(color: AppColors.line)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(onTimeRate * 100).round()}% ${t.attendanceOnTime}',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.subtleText),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 30, color: AppColors.line);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: TextStyle(fontSize: 19, letterSpacing: -0.5, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: AppColors.subtleText),
          ),
        ],
      ),
    );
  }
}

enum _DayStatus { onTime, late, inProgress, noCheckout }

/// One day: date tile · in → out times + worked hours · status pill, with a
/// thin status-coloured edge instead of a fully tinted card.
class AttendanceRow extends StatelessWidget {
  const AttendanceRow({super.key, required this.record});

  final AttendanceRecord record;

  _DayStatus get _status {
    if (record.isLate) return _DayStatus.late;
    if (record.end == null) {
      final DateTime? d = record.date;
      final DateTime now = DateTime.now();
      final bool isToday = d != null && d.year == now.year && d.month == now.month && d.day == now.day;
      return isToday ? _DayStatus.inProgress : _DayStatus.noCheckout;
    }
    return _DayStatus.onTime;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final _DayStatus status = _status;
    final Duration? worked = _worked(record);
    // Only phone punches carry this — always null on a pure device-tab row.
    final bool outsideSite = record.withinGeofence == false;

    final (ToneColor tone, String label, IconData icon) = switch (status) {
      _DayStatus.late => (ToneColor.red, t.attendanceLate, Icons.bolt_rounded),
      _DayStatus.onTime => (ToneColor.green, t.attendanceOnTime, Icons.check_rounded),
      _DayStatus.inProgress => (ToneColor.blue, t.attendanceInProgress, Icons.timelapse_rounded),
      _DayStatus.noCheckout => (ToneColor.amber, t.attendanceNoCheckout, Icons.logout_rounded),
    };

    return GlassCard(
      radius: 18,
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: tone.foreground,
                borderRadius: const BorderRadiusDirectional.horizontal(start: Radius.circular(18))
                    .resolve(Directionality.of(context)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 12, 10),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 46,
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            record.date == null ? '' : DateFormat('EEE', locale).format(record.date!).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 8.5,
                              letterSpacing: 0.6,
                              fontWeight: FontWeight.w800,
                              color: AppColors.subtleText,
                            ),
                          ),
                          Text(
                            record.dayNumber,
                            style: const TextStyle(
                              fontSize: 17,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              _Punch(icon: Icons.login_rounded, value: record.startLabel, color: AppColors.green),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.faintText),
                              ),
                              _Punch(
                                icon: Icons.logout_rounded,
                                value: record.endLabel,
                                color: record.end == null ? AppColors.faintText : AppColors.blue,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              if (worked != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Icon(Icons.schedule_rounded, size: 12, color: AppColors.faintText),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${_hm(worked)} h',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.subtleText,
                                      ),
                                    ),
                                  ],
                                ),
                              if (outsideSite)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Icon(Icons.location_off_rounded, size: 12, color: AppColors.red),
                                    const SizedBox(width: 3),
                                    Text(
                                      t.appOutsideWorkSite,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.red,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: tone.background,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(icon, size: 12, color: tone.foreground),
                          const SizedBox(width: 3),
                          Text(
                            label,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: tone.foreground),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Punch extends StatelessWidget {
  const _Punch({required this.icon, required this.value, required this.color});

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
      ],
    );
  }
}
