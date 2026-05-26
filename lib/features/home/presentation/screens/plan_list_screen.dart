import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/core/widgets/skeletons/skeletons.dart';
import 'package:flutter_pecha/features/home/presentation/providers/plans_by_tag_provider.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/plan_list_view.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/user_plans_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PlanListScreen extends ConsumerWidget {
  final String tag;

  const PlanListScreen({super.key, required this.tag});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(myPlansPaginatedProvider); // pre-warm so enrolled state is ready when list items render
    final plansAsync = ref.watch(plansByTagProvider(tag));
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: plansAsync.when(
                data: (plansEither) {
                  return plansEither.fold(
                    (failure) => ErrorStateWidget(
                      error: failure,
                      onRetry: () => ref.refresh(plansByTagProvider(tag)),
                    ),
                    (plans) {
                      if (plans.isEmpty) {
                        return _buildEmptyState(context, localizations, ref);
                      }
                      return PlanListView(plans: plans);
                    },
                  );
                },
                loading: () => const PlanListSkeleton(),
                error:
                    (error, stackTrace) => ErrorStateWidget(
                      error: error,
                      onRetry: () => ref.refresh(plansByTagProvider(tag)),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Center(
              child: Text(
                _capitalizeTag(tag),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }

  String _capitalizeTag(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations localizations,
    WidgetRef ref,
  ) {
    final locale = ref.watch(localeProvider);
    final fontSize = locale.languageCode == 'bo' ? 22.0 : 18.0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Text(
          localizations.no_feature_content,
          style: TextStyle(fontSize: fontSize),
        ),
      ),
    );
  }
}
