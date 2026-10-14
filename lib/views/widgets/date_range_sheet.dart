import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import 'common.dart';

/// The app's period filter: quick presets + an inline month range picker,
/// replacing Material's full-screen `showDateRangePicker`.
Future<DateTimeRange?> showCdsRangeSheet(
  BuildContext context, {
  required DateTimeRange initial,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showModalBottomSheet<DateTimeRange>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.cream,
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
    builder: (_) => _RangeSheet(
      initial: initial,
      firstDate: DateUtils.dateOnly(firstDate ?? DateTime(2020)),
      lastDate: DateUtils.dateOnly(lastDate ?? DateTime.now().add(const Duration(days: 730))),
    ),
  );
}

enum _Preset { today, thisWeek, last7, thisMonth, lastMonth, last30 }

class _RangeSheet extends StatefulWidget {
  const _RangeSheet({required this.initial, required this.firstDate, required this.lastDate});

  final DateTimeRange initial;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_RangeSheet> createState() => _RangeSheetState();
}

class _RangeSheetState extends State<_RangeSheet> {
  late DateTime _start;
  DateTime? _end;
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    _start = DateUtils.dateOnly(widget.initial.start);
    _end = DateUtils.dateOnly(widget.initial.end);
    _month = DateTime(_start.year, _start.month);
  }

  static DateTime _add(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

  DateTimeRange _presetRange(_Preset p) {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    return switch (p) {
      _Preset.today => DateTimeRange(start: today, end: today),
      _Preset.thisWeek => DateTimeRange(
          start: _add(today, -(today.weekday - DateTime.monday)),
          end: today,
        ),
      _Preset.last7 => DateTimeRange(start: _add(today, -6), end: today),
      _Preset.thisMonth => DateTimeRange(
          start: DateTime(today.year, today.month, 1),
          end: DateTime(today.year, today.month + 1, 0),
        ),
      _Preset.lastMonth => DateTimeRange(
          start: DateTime(today.year, today.month - 1, 1),
          end: DateTime(today.year, today.month, 0),
        ),
      _Preset.last30 => DateTimeRange(start: _add(today, -29), end: today),
    };
  }

  String _presetLabel(AppLocalizations t, _Preset p) => switch (p) {
        _Preset.today => t.rangeToday,
        _Preset.thisWeek => t.rangeThisWeek,
        _Preset.last7 => t.rangeLast7,
        _Preset.thisMonth => t.rangeThisMonth,
        _Preset.lastMonth => t.rangeLastMonth,
        _Preset.last30 => t.rangeLast30,
      };

  bool _isPreset(_Preset p) {
    final DateTimeRange r = _presetRange(p);
    return _end != null && r.start == _start && r.end == _end;
  }

  void _applyPreset(_Preset p) {
    final DateTimeRange r = _presetRange(p);
    setState(() {
      _start = r.start;
      _end = r.end;
      _month = DateTime(r.start.year, r.start.month);
    });
  }

  void _tapDay(DateTime day) {
    setState(() {
      if (_end != null || day.isBefore(_start)) {
        _start = day;
        _end = null;
      } else {
        _end = day;
      }
    });
  }

  bool get _canPrev => DateTime(_month.year, _month.month).isAfter(DateTime(widget.firstDate.year, widget.firstDate.month));
  bool get _canNext => DateTime(_month.year, _month.month).isBefore(DateTime(widget.lastDate.year, widget.lastDate.month));

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final DateFormat boxFmt = DateFormat('d MMM yyyy', locale);
    final int? days = _end == null ? null : (_end!.difference(_start).inHours / 24).round() + 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 16, 12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  t.rangeTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
              SoftIconButton(
                icon: Icons.close_rounded,
                tooltip: t.commonCancel,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final _Preset p in _Preset.values)
                      _PresetChip(
                        label: _presetLabel(t, p),
                        selected: _isPreset(p),
                        onTap: () => _applyPreset(p),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _EndBox(
                        label: t.rangeFrom,
                        value: boxFmt.format(_start),
                        active: _end != null,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.faintText),
                    ),
                    Expanded(
                      child: _EndBox(
                        label: t.rangeTo,
                        value: _end == null ? '—' : boxFmt.format(_end!),
                        active: _end == null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GlassCard(
                  radius: 22,
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          SoftIconButton(
                            icon: Icons.chevron_left_rounded,
                            onPressed: _canPrev
                                ? () => setState(() => _month = DateTime(_month.year, _month.month - 1))
                                : null,
                          ),
                          Expanded(
                            child: Text(
                              DateFormat('MMMM yyyy', locale).format(_month),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
                            ),
                          ),
                          SoftIconButton(
                            icon: Icons.chevron_right_rounded,
                            onPressed: _canNext
                                ? () => setState(() => _month = DateTime(_month.year, _month.month + 1))
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _RangeMonth(
                        month: _month,
                        start: _start,
                        end: _end,
                        firstDate: widget.firstDate,
                        lastDate: widget.lastDate,
                        onTap: _tapDay,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          decoration: const BoxDecoration(
            color: AppColors.cream,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _end == null
                  ? null
                  : () => Navigator.of(context).pop(DateTimeRange(start: _start, end: _end!)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                disabledBackgroundColor: AppColors.line,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                days == null ? t.rangeApply : '${t.rangeApply} · ${t.rangeDays(days)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.green : Colors.white,
      shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.green : AppColors.line)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// "FROM · 1 Oct 2026" — [active] marks the end the next tap will set.
class _EndBox extends StatelessWidget {
  const _EndBox({required this.label, required this.value, required this.active});

  final String label;
  final String value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: active ? AppColors.green : AppColors.line, width: active ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 9, letterSpacing: 1, fontWeight: FontWeight.w800, color: AppColors.faintText),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

class _RangeMonth extends StatelessWidget {
  const _RangeMonth({
    required this.month,
    required this.start,
    required this.end,
    required this.firstDate,
    required this.lastDate,
    required this.onTap,
  });

  final DateTime month;
  final DateTime start;
  final DateTime? end;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final String locale = Localizations.localeOf(context).toString();
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final DateTime first = DateTime(month.year, month.month, 1);
    final int leading = first.weekday - DateTime.monday;
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final int weeks = ((leading + daysInMonth) / 7).ceil();
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final DateTime? rangeEnd = end;

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            for (int i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat('EEEEE', locale).format(DateTime(2024, 1, 1 + i)),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.faintText),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (int w = 0; w < weeks; w++)
          Row(
            children: <Widget>[
              for (int d = 0; d < 7; d++)
                Expanded(
                  child: Builder(
                    builder: (BuildContext context) {
                      final int dayNum = w * 7 + d - leading + 1;
                      if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox(height: 44);
                      final DateTime day = DateTime(month.year, month.month, dayNum);
                      final bool disabled = day.isBefore(firstDate) || day.isAfter(lastDate);
                      final bool isStart = day == start;
                      final bool isEnd = rangeEnd != null && day == rangeEnd;
                      final bool inRange = rangeEnd != null && day.isAfter(start) && day.isBefore(rangeEnd);
                      final bool endpoint = isStart || isEnd;
                      final bool hasBand = rangeEnd != null && rangeEnd != start && (inRange || endpoint);

                      // Band runs edge-to-edge between start and end; rounded
                      // only on the endpoints (direction-aware).
                      BorderRadiusGeometry bandRadius = BorderRadius.zero;
                      if (isStart) {
                        bandRadius = BorderRadiusDirectional.horizontal(start: const Radius.circular(22));
                      } else if (isEnd) {
                        bandRadius = BorderRadiusDirectional.horizontal(end: const Radius.circular(22));
                      }

                      return SizedBox(
                        height: 44,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            if (hasBand)
                              Positioned.fill(
                                top: 4,
                                bottom: 4,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.greenTint,
                                    borderRadius: bandRadius.resolve(rtl ? TextDirection.rtl : TextDirection.ltr),
                                  ),
                                ),
                              ),
                            Material(
                              color: endpoint ? AppColors.green : Colors.transparent,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: disabled ? null : () => onTap(day),
                                child: SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: Center(
                                    child: Text(
                                      '$dayNum',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: endpoint || day == today ? FontWeight.w800 : FontWeight.w600,
                                        color: endpoint
                                            ? Colors.white
                                            : disabled
                                                ? AppColors.faintText.withValues(alpha: 0.5)
                                                : day == today
                                                    ? AppColors.green
                                                    : AppColors.ink,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
