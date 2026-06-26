import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/constants/app_config.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/home/presentation/providers/streak_provider.dart';
import 'package:flutter_pecha/features/home/presentation/providers/today_events_provider.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/today_event_badge.dart';
import 'package:flutter_pecha/features/more/presentation/providers/user_stats_provider.dart';
import 'package:flutter_pecha/features/more/presentation/widgets/streak_share_sheet.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_pecha/shared/widgets/main_tab_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Home tab app bar with greeting and quick actions.
class HomeTabAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const HomeTabAppBar({super.key});

  @override
  Size get preferredSize =>
      const Size.fromHeight(MainTabAppBar.toolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider).user;
    final firstName = user?.firstName ?? user?.username;

    final streakCount = ref
        .watch(streakFutureProvider)
        .maybeWhen(
          data: (either) => either.getOrElse((_) => 0),
          orElse: () => 0,
        );

    return MainTabAppBar(
      titleWidget: _Greeting(firstName: firstName),
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.calendar),
          icon: Icon(
            AppAssets.calendarDots,
            size: 24,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        _StreakBadge(count: streakCount),
        const SizedBox(width: 8),
      ],
    );
  }
}

/// Optional today-event banner shown below the home tab app bar.
class HomeEventBanner extends ConsumerWidget {
  const HomeEventBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayEventName = ref
        .watch(todayEventsFutureProvider)
        .maybeWhen(
          data:
              (eventsEither) => eventsEither.fold(
                (_) => null,
                (events) => events.isNotEmpty ? events.first.name : null,
              ),
          orElse: () => null,
        );

    if (todayEventName == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: TodayEventBadge(label: todayEventName),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.firstName});

  final String? firstName;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final greetingFontSize = getLocalizedFontSize(AppTextSize.titleLarge);
    final greetingStyle = MainTabAppBar.titleStyle(context).copyWith(
      color: colorScheme.onSurface,
    );

    return RichText(
      strutStyle: context.tibetanStrutStyle(greetingFontSize, compact: true),
      text: TextSpan(
        children: [
          TextSpan(
            text: localizations.home_hello_prefix,
            style: greetingStyle,
          ),
          if (firstName != null && firstName!.isNotEmpty)
            TextSpan(
              text: firstName,
              style: greetingStyle,
            ),
        ],
      ),
    );
  }
}

class _StreakBadge extends ConsumerStatefulWidget {
  const _StreakBadge({required this.count});

  final int count;

  @override
  ConsumerState<_StreakBadge> createState() => _StreakBadgeState();
}

class _StreakBadgeState extends ConsumerState<_StreakBadge> {
  static const _flameColor = Color(0xFFE8630A);
  bool _isOpening = false;

  Future<void> _onStreakTap() async {
    if (_isOpening) return;

    setState(() => _isOpening = true);

    try {
      final either = await ref.read(userStatsFutureProvider.future);
      if (!mounted) return;

      either.fold(
        (_) {},
        (stats) => showStreakShareSheet(context, stats.streak),
      );
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _onStreakTap,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppAssets.flame, size: 24, color: _flameColor),
          const SizedBox(width: 4),
          Text(
            '${widget.count}',
            style: TextStyle(
              fontFamily: getSystemFontFamily(AppConfig.englishLanguageCode),
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
