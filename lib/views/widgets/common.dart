import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// The warm gradient backdrop every screen sits on.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.appBackground),
      child: child,
    );
  }
}

/// Frosted white card used for nearly every surface in the design.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.onTap,
    this.color,
    this.borderColor,
    this.shadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    final BorderRadius border = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? AppColors.cardSolid,
        borderRadius: border,
        border: Border.all(color: borderColor ?? Colors.white),
        boxShadow: shadow ?? AppColors.tinyShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: border,
        child: InkWell(
          onTap: onTap,
          borderRadius: border,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Small translucent square button used in headers.
class SoftIconButton extends StatelessWidget {
  const SoftIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.showDot = false,
    this.size = 34,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool showDot;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Widget button = SizedBox(
      width: size,
      height: size,
      child: Material(
        color: const Color(0x88FFFFFF),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Icon(icon, size: 17, color: color ?? AppColors.ink),
              if (showDot)
                Positioned(
                  right: 7,
                  top: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cream, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// `Overview  ·  This month ›` row.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: const Color(0xFF73817E),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (actionIcon != null) ...<Widget>[
                    const SizedBox(width: 3),
                    Icon(actionIcon, size: 14),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// `DAILY LOG            5 entries`
class ListLabel extends StatelessWidget {
  const ListLabel({super.key, required this.label, this.trailing});

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 9),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label.toUpperCase(), style: AppTheme.eyebrow)),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.faintText,
              ),
            ),
        ],
      ),
    );
  }
}

/// Rounded square icon well (green / amber / blue tints).
class IconWell extends StatelessWidget {
  const IconWell({
    super.key,
    required this.icon,
    required this.tone,
    this.size = 33,
  });

  final IconData icon;
  final ToneColor tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(size * 0.33),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.45, color: tone.foreground),
    );
  }
}

enum ToneColor {
  green(AppColors.green, AppColors.greenTint),
  amber(AppColors.amber, AppColors.amberTint),
  blue(AppColors.blue, AppColors.blueTint),
  red(AppColors.red, AppColors.redTint);

  const ToneColor(this.foreground, this.background);

  final Color foreground;
  final Color background;
}

/// Pill showing the active From–To window, tapping opens a range picker.
class DateRangePill extends StatelessWidget {
  const DateRangePill({
    super.key,
    required this.fromLabel,
    required this.toLabel,
    this.onTap,
  });

  final String fromLabel;
  final String toLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.calendar_month_outlined,
            size: 17,
            color: AppColors.green,
          ),
          const SizedBox(width: 8),
          Text(fromLabel, style: _pillText),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('—', style: TextStyle(color: Color(0xFFAFB6B4))),
          ),
          Text(toLabel, style: _pillText),
          const Spacer(),
          const Icon(
            Icons.expand_more_rounded,
            size: 16,
            color: Color(0xFF8E9895),
          ),
        ],
      ),
    );
  }

  static const TextStyle _pillText = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );
}

/// Empty / error / loading placeholder shared by every list screen.
class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.tone = ToneColor.green,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final ToneColor tone;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconWell(icon: icon, tone: tone, size: 56),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.5,
                  color: AppColors.muted,
                ),
              ),
            ],
            if (actionLabel != null) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Status chip (Pending / Approved / Late / ...).
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
  });

  final String label;
  final ToneColor tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 11, color: tone.foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: tone.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Surfaces the API's own `error` string rather than a generic message.
void showApiSnack(
  BuildContext context,
  String message, {
  bool isError = true,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
              size: 18,
              color: isError ? AppColors.red : AppColors.green,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.all(14),
      ),
    );
}
