import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_formats.dart';
import '../../models/mobile_check_in.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import 'common.dart';

/// §10 — the fingerprint "Check in" / "Check out" control on Home.
///
/// The on-device match must succeed before a check-in call happens. While
/// `GET /api/attendance/today` reports an open session the button flips to
/// "Check out" and a live "checked in since…" timer runs.
class CheckInCard extends StatefulWidget {
  const CheckInCard({super.key});

  @override
  State<CheckInCard> createState() => _CheckInCardState();
}

class _CheckInCardState extends State<CheckInCard> {
  // Repaints the elapsed timer; the value itself comes from the provider.
  late final Timer _ticker;

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
    final AttendanceProvider attendance = context.watch<AttendanceProvider>();
    final AuthProvider auth = context.watch<AuthProvider>();
    final CheckInStatus status = attendance.checkInStatus;
    final bool open = attendance.hasOpenSession;

    final bool busy = status == CheckInStatus.working;

    VoidCallback? onPressed;
    if (!busy && auth.user != null) {
      final String userId = auth.user!.userId;
      final AttendanceProvider provider = context.read<AttendanceProvider>();
      onPressed = open
          ? () => provider.checkOut(userId: userId)
          : () => provider.checkIn(userId: userId);
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
                const Text('ATTENDANCE', style: _kicker),
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
                    const Text(
                      'Live',
                      style: TextStyle(
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
            _FingerprintButton(
              done: open,
              busy: busy,
              onPressed: onPressed,
            ),
            const SizedBox(height: 4),
            Text(
              _title(status, open),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                _titleAr(status, open),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF83908E),
                ),
              ),
            ),
            const SizedBox(height: 11),
            if (open)
              _Elapsed(
                elapsed: attendance.sessionElapsed,
                since: attendance.today.checkInAt,
              )
            else
              _Clock(at: attendance.checkedInAt),
            const SizedBox(height: 10),
            _StatusFooter(
              status: status,
              open: open,
              message: attendance.checkInMessage,
              withinGeofence:
                  attendance.today.withinGeofence ?? attendance.withinGeofence,
              siteName: attendance.today.siteName,
            ),
          ],
        ),
      ),
    );
  }

  static String _title(CheckInStatus status, bool open) {
    if (status == CheckInStatus.working) return 'Verifying…';
    if (open) return 'Checked in · tap to check out';
    return switch (status) {
      CheckInStatus.checkedOut => 'Checked out successfully',
      CheckInStatus.failed => 'Something went wrong',
      _ => 'Tap to check in',
    };
  }

  static String _titleAr(CheckInStatus status, bool open) {
    if (status == CheckInStatus.working) return 'جارٍ التحقق…';
    if (open) return 'تم تسجيل الحضور · اضغط لتسجيل الانصراف';
    return switch (status) {
      CheckInStatus.checkedOut => 'تم تسجيل الانصراف',
      CheckInStatus.failed => 'لم تتم العملية',
      _ => 'بصمة الحضور',
    };
  }

  static const TextStyle _kicker = TextStyle(
    fontSize: 10,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w800,
    color: Color(0xFF82918E),
  );
}

class _FingerprintButton extends StatefulWidget {
  const _FingerprintButton({
    required this.done,
    required this.busy,
    required this.onPressed,
  });

  final bool done;
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
    final bool animate = !widget.done;

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
                    gradient: widget.done
                        ? null
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[AppColors.green, AppColors.deep],
                          ),
                    color: widget.done ? AppColors.deep : null,
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
                      : Icon(
                          widget.done
                              ? Icons.logout_rounded
                              : Icons.fingerprint_rounded,
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
  const _Clock({this.at});

  final DateTime? at;

  @override
  Widget build(BuildContext context) {
    final DateTime value = at ?? DateTime.now();
    final List<String> parts = ApiFormats.clockTime.format(value).split(' ');

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

/// `3h 20m` — live while a session is open.
class _Elapsed extends StatelessWidget {
  const _Elapsed({required this.elapsed, this.since});

  final Duration elapsed;
  final DateTime? since;

  @override
  Widget build(BuildContext context) {
    final int hours = elapsed.inHours;
    final int minutes = elapsed.inMinutes.remainder(60);

    return Column(
      children: <Widget>[
        Text(
          hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: AppColors.ink,
          ),
        ),
        if (since != null)
          Text(
            'since ${ApiFormats.clockTime.format(since!)}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF8C9895)),
          ),
      ],
    );
  }
}

class _StatusFooter extends StatelessWidget {
  const _StatusFooter({
    required this.status,
    required this.open,
    required this.message,
    required this.withinGeofence,
    this.siteName,
  });

  final CheckInStatus status;
  final bool open;
  final String? message;
  final bool? withinGeofence;
  final String? siteName;

  @override
  Widget build(BuildContext context) {
    if (status == CheckInStatus.failed) {
      return _Banner(
        tone: ToneColor.red,
        icon: Icons.error_outline_rounded,
        text: message ?? 'Something went wrong. Please try again.',
      );
    }

    if (open) {
      final bool inside = withinGeofence ?? true;
      final String where = inside ? 'Inside geofence' : 'Outside geofence';
      return StatusChip(
        label: siteName == null ? where : '$where · $siteName',
        tone: inside ? ToneColor.green : ToneColor.amber,
        icon: Icons.location_on_outlined,
      );
    }

    if (status == CheckInStatus.checkedOut) {
      return const StatusChip(
        label: 'Checked out',
        tone: ToneColor.blue,
        icon: Icons.logout_rounded,
      );
    }

    return const StatusChip(
      label: 'Fingerprint required',
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
