import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_formats.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/mobile_check_in.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import 'common.dart';

/// §10 — the one fingerprint button on Home.
///
/// Works like the wall terminal: the day's first punch is Start, every later
/// punch moves End. The button never changes; below it sits
/// "In … — Out …", a live "since …" timer while there's only a Start, or
/// "No punch recorded today".
class CheckInCard extends StatefulWidget {
  const CheckInCard({super.key});

  @override
  State<CheckInCard> createState() => _CheckInCardState();
}

class _CheckInCardState extends State<CheckInCard> {
  // Repaints the live "since…" timer.
  late final Timer _ticker;

  Future<void> _punch(String userId) async {
    final AttendanceProvider provider = context.read<AttendanceProvider>();
    await provider.punch(userId: userId, t: AppLocalizations.of(context));
    if (!mounted) return;
    final String? message = provider.punchMessage;
    if (message == null) return;
    showApiSnack(
      context,
      message,
      isError: provider.punchStatus == PunchStatus.failed,
    );
  }

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final AttendanceProvider attendance = context.watch<AttendanceProvider>();
    final AuthProvider auth = context.watch<AuthProvider>();
    final PunchStatus status = attendance.punchStatus;
    final bool busy = status == PunchStatus.working;

    VoidCallback? onPressed;
    if (!busy && auth.user != null) {
      final String userId = auth.user!.userId;
      onPressed = () => _punch(userId);
    }

    return GlassCard(
      radius: 27,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 19),
      color: null,
      shadow: AppColors.softShadow,
      child: DecoratedBox(
        decoration: const BoxDecoration(),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(t.checkInAttendance, style: _kicker),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.green.withValues(alpha: 0.18),
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      t.checkInLive,
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            _FingerprintButton(busy: busy, onPressed: onPressed),
            const SizedBox(height: 4),
            Text(
              busy ? t.checkInVerifying : t.checkInTapToPunch,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 11),
            if (attendance.dayStart == null)
              const _NoPunchYet()
            else
              _DayPunches(
                start: attendance.dayStart!,
                end: attendance.dayEnd,
                elapsed: attendance.isOpen ? attendance.elapsed : null,
              ),
            const SizedBox(height: 10),
            _StatusFooter(
              status: status,
              message: attendance.punchMessage,
              punchedToday: attendance.dayStart != null,
              pendingCount: attendance.pendingCount,
              withinGeofence: attendance.withinGeofence,
              siteName:
                  attendance.lastResult?.siteName ?? attendance.today.siteName,
            ),
          ],
        ),
      ),
    );
  }

  static const TextStyle _kicker = TextStyle(
    fontSize: 10,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w800,
    color: Color(0xFF82918E),
  );
}

class _FingerprintButton extends StatefulWidget {
  const _FingerprintButton({required this.busy, required this.onPressed});

  final bool busy;
  final VoidCallback? onPressed;

  @override
  State<_FingerprintButton> createState() => _FingerprintButtonState();
}

class _FingerprintButtonState extends State<_FingerprintButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool animate = !widget.busy;

    return SizedBox(
      height: 131,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            AnimatedBuilder(
              animation: _pulse,
              builder: (BuildContext context, Widget? child) {
                final double t = animate ? _pulse.value : 1;
                return Transform.scale(
                  scale: animate ? 0.92 + (0.16 * t) : 1,
                  child: Opacity(opacity: animate ? 0.7 + (0.3 * t) : 1, child: child),
                );
              },
              child: Container(
                width: 106,
                height: 106,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.green.withValues(alpha: 0.08),
                  border: Border.all(
                    color: AppColors.green.withValues(alpha: 0.19),
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: widget.onPressed,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 79,
                  height: 79,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[AppColors.green, AppColors.deep],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.green.withValues(alpha: 0.33),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: widget.busy
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.fingerprint_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Clock extends StatelessWidget {
  const _Clock({required this.at});

  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final List<String> parts = ApiFormats.clockTime.format(at).split(' ');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        Text(
          parts.first,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          parts.length > 1 ? parts[1] : '',
          style: const TextStyle(fontSize: 11, color: Color(0xFF8C9895)),
        ),
      ],
    );
  }
}

/// "No punch recorded today".
class _NoPunchYet extends StatelessWidget {
  const _NoPunchYet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        AppLocalizations.of(context).checkInNoPunchToday,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF8C9895),
        ),
      ),
    );
  }
}

/// "In … — Out …", with a live "since …" timer while there's only a Start.
class _DayPunches extends StatelessWidget {
  const _DayPunches({required this.start, this.end, this.elapsed});

  final DateTime start;
  final DateTime? end;

  /// Set only while the day has a single punch.
  final Duration? elapsed;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                children: <Widget>[
                  _Clock(at: start),
                  Text(t.checkInIn, style: _caption),
                ],
              ),
            ),
            Container(width: 1, height: 34, color: const Color(0x1F17332E)),
            Expanded(
              child: Column(
                children: <Widget>[
                  if (end != null)
                    _Clock(at: end!)
                  else
                    const Text(
                      '--:--',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        color: Color(0xFFB5BEBB),
                      ),
                    ),
                  Text(t.checkInOut, style: _caption),
                ],
              ),
            ),
          ],
        ),
        if (elapsed != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            t.checkInElapsedSince(
              _duration(t, elapsed!),
              ApiFormats.clockTime.format(start),
            ),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.green,
            ),
          ),
        ],
      ],
    );
  }

  static String _duration(AppLocalizations t, Duration d) {
    final int hours = d.inHours;
    final int minutes = d.inMinutes.remainder(60);
    return hours > 0
        ? t.checkInDurationHoursMinutes(hours, minutes)
        : t.checkInDurationMinutes(minutes);
  }

  static const TextStyle _caption = TextStyle(
    fontSize: 11,
    color: Color(0xFF8C9895),
  );
}

class _StatusFooter extends StatelessWidget {
  const _StatusFooter({
    required this.status,
    required this.message,
    required this.punchedToday,
    required this.pendingCount,
    required this.withinGeofence,
    this.siteName,
  });

  final PunchStatus status;
  final String? message;
  final bool punchedToday;
  final int pendingCount;
  final bool? withinGeofence;
  final String? siteName;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    if (status == PunchStatus.failed) {
      return _Banner(
        tone: ToneColor.red,
        icon: Icons.error_outline_rounded,
        text: message ?? t.checkInSomethingWrong,
      );
    }

    if (pendingCount > 0) {
      return _Banner(
        tone: ToneColor.amber,
        icon: Icons.cloud_upload_outlined,
        text: t.checkInPending(pendingCount),
      );
    }

    // `null` on terminal-only days — nothing to claim either way. A phone
    // punch can no longer be outside every site (§H, 2026-10-05: the server
    // rejects it with a 400 instead of saving it), so there's no "outside"
    // case left to show here.
    if (punchedToday && withinGeofence == true) {
      return StatusChip(
        label: siteName == null ? t.checkInInsideGeofence : t.checkInInsideSite(siteName!),
        tone: ToneColor.green,
        icon: Icons.location_on_outlined,
      );
    }

    return StatusChip(
      label: t.checkInFingerprintRequired,
      tone: ToneColor.green,
      icon: Icons.verified_user_outlined,
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.tone, required this.icon, required this.text});

  final ToneColor tone;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 15, color: tone.foreground),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: tone.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
