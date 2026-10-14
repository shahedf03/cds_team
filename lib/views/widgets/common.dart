import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/client.dart';
import 'skeleton.dart';

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
    this.badgeCount = 0,
    this.size = 34,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool showDot;

  /// Number bubble in the corner; `0` hides it. Takes over from [showDot].
  final int badgeCount;
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
              if (badgeCount > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 15),
                    height: 15,
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: AppColors.cream, width: 1.5),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        fontSize: 8,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else if (showDot)
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
  red(AppColors.red, AppColors.redTint),
  purple(AppColors.purple, AppColors.purpleTint);

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
    final AppLocalizations t = AppLocalizations.of(context);
    return GlassCard(
      onTap: onTap,
      radius: 18,
      padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 10, 10),
      child: Row(
        children: <Widget>[
          const IconWell(icon: Icons.date_range_rounded, tone: ToneColor.green, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(t.rangePeriod.toUpperCase(), style: AppTheme.eyebrow.copyWith(fontSize: 9)),
                const SizedBox(height: 3),
                Text(
                  '$fromLabel  →  $toLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppColors.line),
            ),
            child: const Icon(Icons.tune_rounded, size: 17, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget padded = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: _content(),
        );
        // Inside an unbounded parent (e.g. a bare ListView) there is no
        // height to fill or scroll within — just centre at natural size and
        // let the ancestor scrollable handle it.
        if (!constraints.hasBoundedHeight) return Center(child: padded);
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: padded),
          ),
        );
      },
    );
  }

  Widget _content() {
    return Column(
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

/// Removable pill for a picked client — Transportation's "+ Add Client"
/// (§4) and Leave's "work leaving" client field (§F) both show their picks
/// this way.
class ClientChip extends StatelessWidget {
  const ClientChip({super.key, required this.name, required this.onRemove});

  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 7, 5, 7),
      decoration: BoxDecoration(
        color: AppColors.blueTint,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(Icons.close_rounded, size: 13, color: AppColors.blue),
            ),
          ),
        ],
      ),
    );
  }
}

/// Searchable list of `GET /api/clients` (§5), shared by Transportation's
/// "+ Add Client" (§4) and Leave's "work leaving" client field (§F — part of
/// the 2026-10-05 update). Provider-agnostic: the caller supplies the
/// already-loaded [clients]/[isLoading] (typically via a `Consumer` so the
/// sheet still reacts to a retry while it's open) rather than this widget
/// reading a specific provider itself.
class ClientPickerSheet extends StatefulWidget {
  const ClientPickerSheet({
    super.key,
    required this.clients,
    required this.isLoading,
    required this.selectedIds,
    required this.onRetry,
  });

  final List<Client> clients;
  final bool isLoading;
  final Set<String> selectedIds;
  final VoidCallback onRetry;

  @override
  State<ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<ClientPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);

    final List<Client> available = widget.clients
        .where((Client c) => !widget.selectedIds.contains(c.id))
        .where(
          (Client c) =>
              _query.isEmpty ||
              c.name.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 12),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    t.editorAddClientTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    onChanged: (String v) => setState(() => _query = v),
                    style: const TextStyle(fontSize: 13),
                    decoration: _pickerFieldDecoration(
                      label: t.editorSearchClients,
                      icon: Icons.search_rounded,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: widget.isLoading && widget.clients.isEmpty
                  ? SkeletonList(
                      itemCount: 8,
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                      itemBuilder: (_, int i) => SkeletonRow(seed: i, trailingPill: false),
                    )
                  : available.isEmpty
                  ? StateMessage(
                      icon: Icons.business_outlined,
                      tone: ToneColor.blue,
                      title: widget.clients.isEmpty
                          ? t.editorNoClientsAvailable
                          : t.editorNoMatches,
                      message: widget.clients.isEmpty
                          ? t.editorClientListFailed
                          : t.editorTryDifferentSearch,
                      actionLabel: widget.clients.isEmpty ? t.commonRetry : null,
                      onAction: widget.onRetry,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: available.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (BuildContext context, int index) {
                        final Client client = available[index];
                        return GlassCard(
                          radius: 14,
                          color: AppColors.cardSoft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          onTap: () => Navigator.of(context).pop(client),
                          child: Row(
                            children: <Widget>[
                              const IconWell(
                                icon: Icons.business_outlined,
                                tone: ToneColor.blue,
                                size: 30,
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Text(
                                  client.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.add_circle_outline_rounded,
                                size: 18,
                                color: AppColors.green,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _pickerFieldDecoration({
  required String label,
  required IconData icon,
}) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
  prefixIcon: Icon(icon, size: 18, color: AppColors.muted),
  filled: true,
  fillColor: const Color(0x66FFFFFF),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.line),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.line),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: AppColors.green, width: 1.4),
  ),
);
