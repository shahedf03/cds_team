import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

// ───────────────────────────── Shimmer core ─────────────────────────────

const Color _boneBase = Color(0xFFE5EDEA);
const Color _boneHighlight = Color(0xFFF8FBFA);

/// One shared sweep for every [Bone] below it, so all placeholders on a
/// screen shimmer as a single wave instead of each bone on its own clock.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  static ShimmerState? of(BuildContext context) => context.findAncestorStateOfType<ShimmerState>();

  @override
  ShimmerState createState() => ShimmerState();
}

class ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController.unbounded(vsync: this);

  Listenable get listenable => _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the OS "reduce motion" setting: static bones, no sweep.
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(min: -0.5, max: 1.5, period: const Duration(milliseconds: 1400));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LinearGradient get gradient => LinearGradient(
        colors: const <Color>[_boneBase, _boneHighlight, _boneBase],
        stops: const <double>[0.1, 0.3, 0.45],
        begin: const Alignment(-1.0, -0.3),
        end: const Alignment(1.0, 0.3),
        transform: _SlideGradient(_controller.value),
      );

  bool get isSized => (context.findRenderObject() as RenderBox?)?.hasSize ?? false;

  Size get size => (context.findRenderObject()! as RenderBox).size;

  Offset offsetOf(RenderBox descendant) =>
      descendant.localToGlobal(Offset.zero, ancestor: context.findRenderObject());

  @override
  Widget build(BuildContext context) => widget.child;
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.percent);

  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * percent, 0, 0);
}

/// A placeholder block. Paints the ancestor [Shimmer]'s gradient across
/// itself, positioned so neighbouring bones line up into one sweep.
class Bone extends StatefulWidget {
  const Bone({super.key, this.width, this.height = 12, this.radius = 6, this.circle = false});

  const Bone.circle({super.key, required double size})
      : width = size,
        height = size,
        radius = 0,
        circle = true;

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  State<Bone> createState() => _BoneState();
}

class _BoneState extends State<Bone> {
  Listenable? _listenable;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _listenable?.removeListener(_tick);
    _listenable = Shimmer.of(context)?.listenable;
    _listenable?.addListener(_tick);
  }

  @override
  void dispose() {
    _listenable?.removeListener(_tick);
    super.dispose();
  }

  void _tick() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final Widget box = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: _boneBase,
        shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.circle ? null : BorderRadius.circular(widget.radius),
      ),
    );

    final ShimmerState? shimmer = Shimmer.of(context);
    final RenderObject? self = context.findRenderObject();
    if (shimmer == null || !shimmer.isSized || self is! RenderBox || !self.hasSize) return box;

    final Size area = shimmer.size;
    final Offset at = shimmer.offsetOf(self);
    final Gradient gradient = shimmer.gradient;
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (Rect bounds) =>
          gradient.createShader(Rect.fromLTWH(-at.dx, -at.dy, area.width, area.height)),
      child: box,
    );
  }
}

/// A line of text-height that takes [widthFactor] of the available width.
class BoneLine extends StatelessWidget {
  const BoneLine({super.key, this.widthFactor = 1, this.height = 10});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: widthFactor,
        child: Bone(height: height, radius: height / 2),
      );
}

/// Static white card the bones sit on — same surface as `GlassCard`, but not
/// tappable and without ink.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.radius = 18});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.cardSolid,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white),
          boxShadow: AppColors.tinyShadow,
        ),
        child: child,
      );
}

/// Scrollable skeleton list (keeps pull-to-refresh working) that fades in,
/// so a fast response never flashes placeholders.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    required this.itemBuilder,
    this.itemCount = 6,
    this.header = const <Widget>[],
    this.spacing = 8,
    this.padding = const EdgeInsets.only(bottom: 110),
    this.shrinkWrap = false,
  });

  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final List<Widget> header;
  final double spacing;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return SkeletonFadeIn(
      child: Shimmer(
        child: ListView(
          padding: padding,
          shrinkWrap: shrinkWrap,
          physics: shrinkWrap ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            ...header,
            for (int i = 0; i < itemCount; i++)
              Padding(padding: EdgeInsets.only(bottom: spacing), child: itemBuilder(context, i)),
          ],
        ),
      ),
    );
  }
}

/// Short delay + fade so sub-200ms loads don't flicker a skeleton.
class SkeletonFadeIn extends StatelessWidget {
  const SkeletonFadeIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: const Interval(0.35, 1, curve: Curves.easeOut),
      builder: (BuildContext context, double v, Widget? c) => Opacity(opacity: v, child: c),
      child: child,
    );
  }
}

// ───────────────────────────── Presets ─────────────────────────────

enum SkeletonLeading { icon, avatar, date, none }

/// Generic list row: leading block · two lines · optional trailing pill.
/// Width factors vary by [seed] so a list doesn't look like a barcode.
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({
    super.key,
    this.seed = 0,
    this.leading = SkeletonLeading.icon,
    this.trailingPill = true,
    this.thirdLine = false,
  });

  final int seed;
  final SkeletonLeading leading;
  final bool trailingPill;
  final bool thirdLine;

  static const List<double> _wide = <double>[0.72, 0.55, 0.64, 0.48, 0.68, 0.58];
  static const List<double> _narrow = <double>[0.42, 0.34, 0.5, 0.38, 0.3, 0.46];

  @override
  Widget build(BuildContext context) {
    final Widget? lead = switch (leading) {
      SkeletonLeading.icon => const Bone(width: 38, height: 38, radius: 12),
      SkeletonLeading.avatar => const Bone.circle(size: 40),
      SkeletonLeading.date => const Bone(width: 46, height: 50, radius: 13),
      SkeletonLeading.none => null,
    };
    return SkeletonCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      child: Row(
        children: <Widget>[
          if (lead != null) ...<Widget>[lead, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                BoneLine(widthFactor: _wide[seed % _wide.length], height: 11),
                const SizedBox(height: 8),
                BoneLine(widthFactor: _narrow[seed % _narrow.length], height: 9),
                if (thirdLine) ...<Widget>[
                  const SizedBox(height: 8),
                  BoneLine(widthFactor: _narrow[(seed + 2) % _narrow.length] + 0.15, height: 9),
                ],
              ],
            ),
          ),
          if (trailingPill) ...<Widget>[
            const SizedBox(width: 10),
            const Bone(width: 54, height: 22, radius: 11),
          ],
        ],
      ),
    );
  }
}

/// Four stats + a progress bar — matches `AttendanceSummaryCard`.
class SkeletonSummaryCard extends StatelessWidget {
  const SkeletonSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              for (int i = 0; i < 4; i++)
                const Expanded(
                  child: Column(
                    children: <Widget>[
                      Bone(width: 30, height: 18),
                      SizedBox(height: 6),
                      Bone(width: 44, height: 8),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Bone(height: 6, radius: 3),
          const SizedBox(height: 8),
          const BoneLine(widthFactor: 0.25, height: 8),
        ],
      ),
    );
  }
}

/// Header line + three task lines — matches `TaskProjectCard`.
class SkeletonGroupCard extends StatelessWidget {
  const SkeletonGroupCard({super.key, this.seed = 0, this.rows = 3});

  final int seed;
  final int rows;

  @override
  Widget build(BuildContext context) {
    return SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Bone(width: 30, height: 30, radius: 10),
              const SizedBox(width: 10),
              Expanded(child: BoneLine(widthFactor: seed.isEven ? 0.5 : 0.62, height: 12)),
              const Bone(width: 36, height: 18, radius: 9),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < rows; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: <Widget>[
                  const Bone.circle(size: 14),
                  const SizedBox(width: 10),
                  Expanded(child: BoneLine(widthFactor: <double>[0.8, 0.6, 0.7][(i + seed) % 3])),
                  const SizedBox(width: 10),
                  const Bone(width: 44, height: 16, radius: 8),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Dashboard: 2×2 stats, overview card, activity rows.
class SkeletonDashboard extends StatelessWidget {
  const SkeletonDashboard({super.key});

  Widget _stat() => const Expanded(
        child: SkeletonCard(
          padding: EdgeInsets.fromLTRB(10, 11, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Bone(width: 23, height: 23, radius: 8),
              SizedBox(height: 12),
              Bone(width: 46, height: 18),
              SizedBox(height: 6),
              BoneLine(widthFactor: 0.7, height: 8),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SkeletonFadeIn(
      child: Shimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const BoneLine(widthFactor: 0.55, height: 9),
            const SizedBox(height: 14),
            Row(children: <Widget>[_stat(), const SizedBox(width: 8), _stat()]),
            const SizedBox(height: 8),
            Row(children: <Widget>[_stat(), const SizedBox(width: 8), _stat()]),
            const SizedBox(height: 14),
            const SkeletonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(child: BoneLine(widthFactor: 0.4, height: 11)),
                      Bone(width: 30, height: 12),
                    ],
                  ),
                  SizedBox(height: 10),
                  Bone(height: 6, radius: 3),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              children: <Widget>[
                Expanded(child: SkeletonCard(child: _TileBones())),
                SizedBox(width: 8),
                Expanded(child: SkeletonCard(child: _TileBones())),
              ],
            ),
            const SizedBox(height: 22),
            const BoneLine(widthFactor: 0.35, height: 12),
            const SizedBox(height: 10),
            for (int i = 0; i < 3; i++)
              Padding(padding: const EdgeInsets.only(bottom: 6), child: SkeletonRow(seed: i, trailingPill: false)),
          ],
        ),
      ),
    );
  }
}

class _TileBones extends StatelessWidget {
  const _TileBones();

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Bone(width: 30, height: 30, radius: 10),
          SizedBox(height: 12),
          BoneLine(widthFactor: 0.7, height: 11),
          SizedBox(height: 6),
          BoneLine(widthFactor: 0.5, height: 8),
        ],
      );
}

/// Detail page: hero card (icon + title + meta) then field rows.
class SkeletonDetail extends StatelessWidget {
  const SkeletonDetail({super.key, this.avatar = false, this.sections = 2});

  final bool avatar;
  final int sections;

  @override
  Widget build(BuildContext context) {
    return SkeletonFadeIn(
      child: Shimmer(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 110),
          children: <Widget>[
            SkeletonCard(
              radius: 20,
              child: Row(
                children: <Widget>[
                  if (avatar) const Bone.circle(size: 46) else const Bone(width: 46, height: 46, radius: 15),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        BoneLine(widthFactor: 0.65, height: 14),
                        SizedBox(height: 8),
                        BoneLine(widthFactor: 0.4, height: 9),
                      ],
                    ),
                  ),
                  const Bone(width: 60, height: 22, radius: 11),
                ],
              ),
            ),
            const SizedBox(height: 14),
            for (int s = 0; s < sections; s++) ...<Widget>[
              SkeletonCard(
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < 4; i++)
                      Padding(
                        padding: EdgeInsets.only(bottom: i == 3 ? 0 : 14),
                        child: Row(
                          children: <Widget>[
                            const Bone(width: 18, height: 18, radius: 6),
                            const SizedBox(width: 12),
                            const Expanded(child: BoneLine(widthFactor: 0.35, height: 9)),
                            Bone(width: <double>[90, 70, 110, 60][(i + s) % 4], height: 10),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

/// Chat: alternating incoming / outgoing bubbles.
class SkeletonChat extends StatelessWidget {
  const SkeletonChat({super.key});

  @override
  Widget build(BuildContext context) {
    const List<(bool, double, double)> bubbles = <(bool, double, double)>[
      (false, 0.62, 44),
      (true, 0.5, 36),
      (false, 0.45, 36),
      (false, 0.7, 58),
      (true, 0.58, 44),
      (false, 0.4, 36),
      (true, 0.66, 58),
    ];
    return SkeletonFadeIn(
      child: Shimmer(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            for (final (bool mine, double w, double h) in bubbles)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    if (!mine) ...<Widget>[const Bone.circle(size: 28), const SizedBox(width: 8)],
                    Flexible(
                      child: FractionallySizedBox(
                        widthFactor: w,
                        alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                        child: Bone(height: h, radius: 16),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Square thumbnails for attachment grids.
class SkeletonThumbs extends StatelessWidget {
  const SkeletonThumbs({super.key, this.count = 3, this.size = 84});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: <Widget>[
          for (int i = 0; i < count; i++) Bone(width: size, height: size, radius: 14),
        ],
      ),
    );
  }
}
