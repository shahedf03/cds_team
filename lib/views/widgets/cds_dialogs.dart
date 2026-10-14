import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import 'common.dart';

/// The app's single dialog look: icon well, centred title + message, an
/// optional details box, and two equal-width buttons.
class CdsDialog extends StatelessWidget {
  const CdsDialog({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.confirmLabel,
    required this.onConfirm,
    this.message,
    this.details = const <String>[],
    this.body,
    this.cancelLabel,
    this.onCancel,
  });

  final IconData icon;
  final ToneColor tone;
  final String title;
  final String? message;
  final List<String> details;
  final Widget? body;
  final String confirmLabel;
  final String? cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(child: IconWell(icon: icon, tone: tone, size: 54)),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.3,
                  letterSpacing: -0.3,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              if (message != null && message!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.subtleText),
                ),
              ],
              if (details.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      for (int i = 0; i < details.length; i++)
                        Padding(
                          padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
                          child: Text(
                            details[i],
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                              color: i == 0 ? AppColors.ink : AppColors.subtleText,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (body != null) ...<Widget>[
                const SizedBox(height: 14),
                body!,
              ],
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _DialogButton(
                      label: cancelLabel ?? t.commonCancel,
                      background: const Color(0xFFF0F4F2),
                      foreground: AppColors.ink,
                      onPressed: onCancel ?? () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DialogButton(
                      label: confirmLabel,
                      background: tone.foreground,
                      foreground: Colors.white,
                      onPressed: onConfirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

/// Yes/no question. Returns `true` only when the confirm button is pressed.
Future<bool> showCdsConfirm(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? message,
  List<String> details = const <String>[],
  String? cancelLabel,
  IconData icon = Icons.help_outline_rounded,
  ToneColor tone = ToneColor.green,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0x8025333B),
    builder: (BuildContext ctx) => CdsDialog(
      icon: icon,
      tone: tone,
      title: title,
      message: message,
      details: details,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onCancel: () => Navigator.of(ctx).pop(false),
      onConfirm: () => Navigator.of(ctx).pop(true),
    ),
  );
  return result ?? false;
}

/// Asks for a short text (reason / note). `null` = cancelled; when not
/// [required] an empty string means "confirmed without text".
Future<String?> showCdsTextInput(
  BuildContext context, {
  required String title,
  required String hint,
  required String confirmLabel,
  String? message,
  List<String> details = const <String>[],
  bool required = false,
  String? requiredMessage,
  IconData icon = Icons.edit_note_rounded,
  ToneColor tone = ToneColor.green,
}) {
  return showDialog<String>(
    context: context,
    barrierColor: const Color(0x8025333B),
    builder: (BuildContext ctx) => _TextInputDialog(
      title: title,
      hint: hint,
      confirmLabel: confirmLabel,
      message: message,
      details: details,
      required: required,
      requiredMessage: requiredMessage,
      icon: icon,
      tone: tone,
    ),
  );
}

class _TextInputDialog extends StatefulWidget {
  const _TextInputDialog({
    required this.title,
    required this.hint,
    required this.confirmLabel,
    required this.details,
    required this.required,
    required this.icon,
    required this.tone,
    this.message,
    this.requiredMessage,
  });

  final String title;
  final String hint;
  final String confirmLabel;
  final String? message;
  final List<String> details;
  final bool required;
  final String? requiredMessage;
  final IconData icon;
  final ToneColor tone;

  @override
  State<_TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<_TextInputDialog> {
  final TextEditingController _text = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final String value = _text.text.trim();
    if (widget.required && value.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = widget.tone.foreground;
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );

    return CdsDialog(
      icon: widget.icon,
      tone: widget.tone,
      title: widget.title,
      message: widget.message,
      details: widget.details,
      confirmLabel: widget.confirmLabel,
      onConfirm: _submit,
      body: TextField(
        controller: _text,
        autofocus: true,
        minLines: 3,
        maxLines: 5,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) {
          if (_showError) setState(() => _showError = false);
        },
        style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.ink),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.faintText),
          filled: true,
          fillColor: AppColors.cream,
          contentPadding: const EdgeInsets.all(14),
          errorText: _showError ? widget.requiredMessage : null,
          enabledBorder: border(AppColors.line),
          focusedBorder: border(accent, 1.5),
          errorBorder: border(AppColors.red),
          focusedErrorBorder: border(AppColors.red, 1.5),
        ),
      ),
    );
  }
}

/// One row in [showCdsOptionsSheet].
class CdsSheetOption<T> {
  const CdsSheetOption({
    required this.value,
    required this.icon,
    required this.label,
    this.subtitle,
    this.tone = ToneColor.green,
  });

  final T value;
  final IconData icon;
  final String label;
  final String? subtitle;
  final ToneColor tone;
}

/// Action sheet: a title and a grouped list of choices, plus Cancel.
Future<T?> showCdsOptionsSheet<T>(
  BuildContext context, {
  required String title,
  required List<CdsSheetOption<T>> options,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: AppColors.cream,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (BuildContext ctx) {
      final AppLocalizations t = AppLocalizations.of(ctx);
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < options.length; i++) ...<Widget>[
                      if (i > 0) const Divider(height: 1, thickness: 1, indent: 64, color: AppColors.line),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(ctx).pop(options[i].value),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: <Widget>[
                                IconWell(icon: options[i].icon, tone: options[i].tone, size: 38),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        options[i].label,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      if (options[i].subtitle != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            options[i].subtitle!,
                                            style: const TextStyle(fontSize: 11, color: AppColors.subtleText),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.faintText),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.subtleText,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(t.commonCancel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
