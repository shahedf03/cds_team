import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ───────────────────────────── Logo geometry ─────────────────────────────

/// The CDS mark as three stroked centre-lines, measured off the master
/// artwork (1376×768 canvas, stroke 38). Drawn in this order: green "c"
/// (with the cloud bump), green "d", dark reversed "c".
class CdsLogoGeometry {
  CdsLogoGeometry._();

  static const Color green = Color(0xFF2BA580);
  static const Color dark = Color(0xFF283539);

  static const double strokeWidth = 38;

  /// Bounding box of the stroked mark in artwork units.
  static const Rect bounds = Rect.fromLTRB(317, 22, 1071, 410);

  static double _rad(double deg) => deg * math.pi / 180;

  static final List<(Path, Color)> strokes = <(Path, Color)>[
    (
      Path()
        // Bottom bar → big bowl round the left → top, ending in the cusp.
        ..moveTo(536, 391)
        ..lineTo(468, 391)
        ..arcTo(Rect.fromCircle(center: const Offset(468, 259), radius: 132), _rad(90), _rad(199), false)
        // Cloud bump: rises out of the bowl and ends in a vertical cut.
        ..moveTo(508, 150)
        ..lineTo(508, 145)
        ..arcTo(Rect.fromCircle(center: const Offset(610, 145), radius: 102), _rad(180), _rad(90), false),
      green,
    ),
    (
      Path()
        // Top bar → bowl → stem → stem tip curling up-left (diagonal cut).
        ..moveTo(740, 129)
        ..lineTo(703, 129)
        ..arcTo(Rect.fromCircle(center: const Offset(703, 260), radius: 131), _rad(270), _rad(-180), false)
        ..arcTo(Rect.fromCircle(center: const Offset(703, 280), radius: 111), _rad(90), _rad(-90), false)
        ..lineTo(814, 128)
        ..quadraticBezierTo(812, 70, 787.5, 45),
      green,
    ),
    (
      Path()
        // Diagonal cut at the top → round the right → bottom bar.
        ..addArc(Rect.fromCircle(center: const Offset(920.5, 258.5), radius: 131.5), _rad(252), _rad(198))
        ..lineTo(852, 390),
      dark,
    ),
  ];

  static final List<ui.PathMetric> _metrics = <ui.PathMetric>[
    for (final (Path p, Color _) in strokes) ...p.computeMetrics(),
  ];

  static final List<Color> _metricColors = <Color>[
    for (final (Path p, Color c) in strokes)
      for (final ui.PathMetric _ in p.computeMetrics()) c,
  ];

  static final double totalLength = _metrics.fold<double>(0, (double s, ui.PathMetric m) => s + m.length);
}

/// Paints the part of the mark between [start] and [end] (0..1 of the total
/// stroke length), so it can be drawn on and wiped off in sequence.
class CdsLogoPainter extends CustomPainter {
  CdsLogoPainter({required this.start, required this.end});

  final double start;
  final double end;

  @override
  void paint(Canvas canvas, Size size) {
    if (end <= start) return;
    const Rect b = CdsLogoGeometry.bounds;
    final double scale = math.min(size.width / b.width, size.height / b.height);
    canvas
      ..save()
      ..translate((size.width - b.width * scale) / 2, (size.height - b.height * scale) / 2)
      ..scale(scale)
      ..translate(-b.left, -b.top);

    final double total = CdsLogoGeometry.totalLength;
    final double from = start * total;
    final double to = end * total;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = CdsLogoGeometry.strokeWidth
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    double offset = 0;
    for (int i = 0; i < CdsLogoGeometry._metrics.length; i++) {
      final ui.PathMetric m = CdsLogoGeometry._metrics[i];
      final double s = (from - offset).clamp(0, m.length);
      final double e = (to - offset).clamp(0, m.length);
      if (e > s) {
        paint.color = CdsLogoGeometry._metricColors[i];
        canvas.drawPath(m.extractPath(s, e), paint);
      }
      offset += m.length;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CdsLogoPainter old) => old.start != start || old.end != end;
}

// ───────────────────────────── Pull to refresh ─────────────────────────────

enum _Mode { idle, drag, refresh, done }

/// Drop-in for `RefreshIndicator`: pulling down draws the CDS logo stroke by
/// stroke; past the trigger it locks in (with a haptic tick), and while
/// [onRefresh] runs the logo draws on and wipes off in a loop.
class CdsRefreshIndicator extends StatefulWidget {
  const CdsRefreshIndicator({super.key, required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  State<CdsRefreshIndicator> createState() => _CdsRefreshIndicatorState();
}

class _CdsRefreshIndicatorState extends State<CdsRefreshIndicator> with TickerProviderStateMixin {
  /// Visual pull needed to trigger, the height held while refreshing, and
  /// the cap the rubber-band approaches.
  static const double _trigger = 84;
  static const double _hold = 76;
  static const double _max = 140;

  static const double _logoWidth = 60;
  static final double _logoHeight = _logoWidth * CdsLogoGeometry.bounds.height / CdsLogoGeometry.bounds.width;

  late final AnimationController _extent = AnimationController.unbounded(vsync: this);
  late final AnimationController _loop = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
  late final AnimationController _exit = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));

  _Mode _mode = _Mode.idle;
  bool _dragging = false;
  bool _armed = false;

  /// Raw finger travel past the top edge.
  double _drag = 0;

  /// How far a bouncing (iOS) list itself is pulled past 0 — that part of
  /// the gap is already open, so the content isn't shifted for it again.
  double _bounce = 0;

  @override
  void dispose() {
    _extent.dispose();
    _loop.dispose();
    _exit.dispose();
    super.dispose();
  }

  /// Rubber band: 1:1-ish at first, easing towards [_max].
  double _visual(double drag) => _max * (1 - math.exp(-drag / (_max * 1.15)));

  void _setDrag(double value) {
    _drag = math.max(0, value);
    final double v = _visual(_drag);
    _extent.value = v;
    final bool armed = v >= _trigger;
    if (armed != _armed) {
      _armed = armed;
      if (armed) unawaited(HapticFeedback.mediumImpact());
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;

    final double pixels = n.metrics.pixels - n.metrics.minScrollExtent;
    final double bounce = pixels < 0 ? -pixels : 0;
    if (bounce != _bounce) setState(() => _bounce = bounce);

    if (_mode == _Mode.refresh || _mode == _Mode.done) return false;

    if (n is ScrollStartNotification) {
      if (n.dragDetails != null && n.metrics.extentBefore == 0) {
        _dragging = true;
        _mode = _Mode.drag;
        _armed = false;
        _drag = 0;
      }
    } else if (n is OverscrollNotification) {
      // Clamping (Android): the list can't move, so collect the overscroll.
      if (_dragging && n.dragDetails != null && n.overscroll < 0) _setDrag(_drag - n.overscroll);
    } else if (n is ScrollUpdateNotification) {
      if (_dragging && n.dragDetails == null) {
        _release();
      } else if (_dragging) {
        if (bounce > 0) {
          // Bouncing (iOS): the list moves by itself; follow it.
          _setDrag(bounce * 1.2);
        } else if (_drag > 0 && (n.scrollDelta ?? 0) > 0) {
          _setDrag(_drag - n.scrollDelta!);
        }
      }
    } else if (n is ScrollEndNotification) {
      if (_dragging) _release();
    }
    return false;
  }

  bool _onIndicator(OverscrollIndicatorNotification n) {
    // No glow/stretch while the logo owns the gesture.
    if (n.depth == 0 && (_dragging || _mode != _Mode.idle) && n.leading) n.disallowIndicator();
    return false;
  }

  void _release() {
    _dragging = false;
    if (_armed) {
      _startRefresh();
    } else {
      _mode = _Mode.idle;
      unawaited(_extent.animateTo(0, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic));
    }
  }

  Future<void> _startRefresh() async {
    setState(() => _mode = _Mode.refresh);
    unawaited(_extent.animateTo(_hold, duration: const Duration(milliseconds: 260), curve: Curves.easeOutBack));
    unawaited(_loop.repeat());
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) await _finish();
    }
  }

  Future<void> _finish() async {
    setState(() => _mode = _Mode.done);
    _loop.stop();
    await Future.wait<void>(<Future<void>>[
      _exit.forward(from: 0),
      _extent.animateTo(0, duration: const Duration(milliseconds: 320), curve: Curves.easeInOutCubic),
    ]);
    if (!mounted) return;
    _exit.reset();
    _loop.reset();
    setState(() {
      _mode = _Mode.idle;
      _armed = false;
      _drag = 0;
    });
  }

  /// Which slice of the logo is visible right now.
  (double, double) _segment(bool reduceMotion) {
    switch (_mode) {
      case _Mode.idle:
      case _Mode.drag:
        return (0, (_extent.value / _trigger).clamp(0.0, 1.0));
      case _Mode.refresh:
      case _Mode.done:
        if (reduceMotion) return (0, 1);
        // First half draws on, second half wipes off from the start.
        final double t = _loop.value;
        return t < 0.5
            ? (0, Curves.easeInOutCubic.transform(t * 2))
            : (Curves.easeInOutCubic.transform((t - 0.5) * 2), 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;

    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: _onIndicator,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_extent, _loop, _exit]),
          child: widget.child,
          builder: (BuildContext context, Widget? child) {
            final double extent = math.max(0, _extent.value);
            final double contentOffset = math.max(0, extent - _bounce);
            final (double start, double end) = _segment(reduceMotion);

            final double appear = (extent / 36).clamp(0.0, 1.0);
            final double exit = Curves.easeIn.transform(_exit.value);
            final double pulse = reduceMotion && _mode == _Mode.refresh
                ? 0.55 + 0.45 * (0.5 + 0.5 * math.sin(_loop.value * 2 * math.pi))
                : 1;
            final double grow = _mode == _Mode.drag || _mode == _Mode.idle
                ? 0.85 + 0.15 * (extent / _trigger).clamp(0.0, 1.0)
                : 1;

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: <Widget>[
                Transform.translate(offset: Offset(0, contentOffset), child: child),
                if (extent > 0.5)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: extent,
                    child: IgnorePointer(
                      child: Center(
                        child: Opacity(
                          opacity: (appear * (1 - exit) * pulse).clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: grow * (1 - 0.35 * exit),
                            child: CustomPaint(
                              size: Size(_logoWidth, _logoHeight),
                              painter: CdsLogoPainter(start: start, end: end),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
