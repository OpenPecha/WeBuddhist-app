import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigation_bottom_bar.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_navigator.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_navigation/plan_subtask_completion.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/reader/domain/services/navigation_service.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_font_size_bottom_sheet.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_app_bar/reader_font_size_button.dart';
import 'package:flutter_pecha/features/texts/presentation/providers/font_size_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Lightweight reading screen for plan subtasks where
/// `content_type == "TEXT"`. Shares the same bottom navigation strip with
/// `ReaderScreen` so that prev/next/finish work identically across both
/// content types in a mixed-type plan day.
///
/// Compared to `ReaderScreen`, this screen intentionally omits commentary,
/// segment selection, copy/share, search, language switching and audio —
/// inline plan text has no segments to attach those features to.
class PlanTextScreen extends ConsumerWidget {
  /// The current subtask's content + plan-list context. The body renders
  /// `navigationContext.currentItem.inlineContent`.
  final NavigationContext navigationContext;

  const PlanTextScreen({super.key, required this.navigationContext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentItem = navigationContext.currentItem;
    final fontSize = ref.watch(fontSizeProvider);

    if (currentItem == null || currentItem.inlineContent == null) {
      return _buildMissingContentScaffold(context);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: Text(
          currentItem.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          ReaderFontSizeButton(
            onPressed: () => showFontSizeBottomSheet(context),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: SelectableText(
                  currentItem.inlineContent!,
                  style: TextStyle(
                    fontSize: fontSize,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            PlanNavigationBottomBar(
              navigationContext: navigationContext,
              fallbackTitle: currentItem.title,
              onPreviousTap: () => _navigate(context, ref, SwipeDirection.previous),
              onNextTap: () => _navigate(context, ref, SwipeDirection.next),
              onFinishedTap: () => _finish(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingContentScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: const Center(child: Text('No content available')),
    );
  }

  void _navigate(
    BuildContext context,
    WidgetRef ref,
    SwipeDirection direction,
  ) {
    if (direction == SwipeDirection.next) {
      completeCurrentPlanSubtask(ref, navigationContext);
      invalidatePlanProviders(ref, navigationContext);
    }
    PlanNavigator.navigateAdjacent(context, navigationContext, direction);
  }

  void _finish(BuildContext context, WidgetRef ref) {
    completeCurrentPlanSubtask(ref, navigationContext);
    invalidatePlanProviders(ref, navigationContext);
    if (context.mounted) context.pop();
  }
}
