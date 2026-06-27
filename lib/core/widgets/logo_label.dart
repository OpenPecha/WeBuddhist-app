import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

class LogoLabel extends StatelessWidget {
  const LogoLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      children: [
        Image.asset(AppAssets.weBuddhistLogo, height: 120),
        const SizedBox(height: 12),
        Text(
          context.l10n.appTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: getFontFamily('en'),
            color: onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.onboarding_tagline,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: onSurface,
          ),
        ),
      ],
    );
  }
}
