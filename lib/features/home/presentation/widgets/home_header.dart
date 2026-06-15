import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/home/presentation/providers/streak_provider.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Home screen header that shows a personalised greeting and the user's
/// current streak count.
class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final user = ref.watch(userProvider).user;
    final firstName =
        user?.firstName ??
        user?.username ??
        localizations.home_greeting_fallback_name;

    final streakCount = ref
        .watch(streakFutureProvider)
        .maybeWhen(
          data: (either) => either.getOrElse((_) => 0),
          orElse: () => 0,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Greeting(firstName: firstName),
          _StreakBadge(count: streakCount),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _Greeting extends StatelessWidget {
  final String firstName;

  const _Greeting({required this.firstName});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final greetingFontSize = context.isTibetanLocale ? 18.0 : 24.0;
    final greetingStyle = textTheme.headlineMedium?.copyWith(
      color: colorScheme.onSurface,
      fontSize: greetingFontSize,
      height: context.isTibetanLocale ? 1.2 : null,
    );

    return RichText(
      strutStyle: context.tibetanStrutStyle(greetingFontSize),
      text: TextSpan(
        children: [
          TextSpan(
            text: localizations.home_hello_prefix,
            style: greetingStyle?.copyWith(fontWeight: FontWeight.w400),
          ),
          TextSpan(
            text: firstName,
            style: greetingStyle?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int count;

  const _StreakBadge({required this.count});

  static const _flameColor = Color(0xFFE8630A);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AppAssets.flame, size: 24.0, color: _flameColor),
        const SizedBox(width: 4.0),
        Text(
          '$count',
          style: TextStyle(
            fontFamily: getSystemFontFamily(AppConfig.englishLanguageCode),
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20.0,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
