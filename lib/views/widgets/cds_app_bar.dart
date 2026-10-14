import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import 'common.dart';

/// Inner-screen header: back button, centred title, optional action.
class CdsAppBar extends StatelessWidget {
  const CdsAppBar({
    super.key,
    required this.title,
    this.action,
    this.onBack,
    this.showBack = true,
  });

  final String title;
  final Widget? action;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 34,
            child: showBack
                ? SoftIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: AppLocalizations.of(context).commonBack,
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  )
                : null,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          SizedBox(width: 34, child: action),
        ],
      ),
    );
  }
}
