import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/plans/data/providers/plans_providers.dart';
import 'package:flutter_pecha/features/practice/data/models/session_selection.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_pecha/shared/extensions/typography_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Combined screen for selecting either a Plan or Recitation to add to routine.
/// Returns [SessionSelection] - either [PlanSessionSelection] or [RecitationSessionSelection].
class SelectSessionScreen extends ConsumerStatefulWidget {
  const SelectSessionScreen({super.key});

  @override
  ConsumerState<SelectSessionScreen> createState() =>
      _SelectSessionScreenState();
}

class _SelectSessionScreenState extends ConsumerState<SelectSessionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _plansScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _plansScrollController.addListener(_onPlansScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _plansScrollController.removeListener(_onPlansScroll);
    _plansScrollController.dispose();
    super.dispose();
  }

  void _onPlansScroll() {
    if (_plansScrollController.position.pixels >=
        _plansScrollController.position.maxScrollExtent - 200) {
      ref.read(findPlansPaginatedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.routine_add_session,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        scrolledUnderElevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: localizations.routine_add_plan),
            Tab(text: localizations.routine_add_recitation),
          ],
          labelStyle: context.languageTextStyle(
            languageCode,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: context.languageTextStyle(
            languageCode,
            fontWeight: FontWeight.bold,
          ),
          labelColor: Theme.of(context).colorScheme.secondary,
          unselectedLabelColor:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PlansTab(
            scrollController: _plansScrollController,
            onPlanSelected: (plan) {
              Navigator.of(context).pop(PlanSessionSelection(plan));
            },
          ),
          _RecitationsTab(
            onRecitationSelected: (recitation) {
              Navigator.of(context).pop(RecitationSessionSelection(recitation));
            },
          ),
        ],
      ),
    );
  }
}

/// Tab content for displaying and selecting plans.
class _PlansTab extends ConsumerWidget {
  final ScrollController scrollController;
  final void Function(dynamic plan) onPlanSelected;

  const _PlansTab({
    required this.scrollController,
    required this.onPlanSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final plansState = ref.watch(findPlansPaginatedProvider);

    if (plansState.isLoading && plansState.plans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (plansState.error != null && plansState.plans.isEmpty) {
      return ErrorStateWidget(
        error: plansState.error!,
        onRetry: () => ref.read(findPlansPaginatedProvider.notifier).retry(),
        customMessage: 'Unable to load plans.\nPlease try again later.',
      );
    }

    if (plansState.plans.isEmpty && !plansState.isLoading) {
      return Center(
        child: Text(
          localizations.no_plans_found,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      itemCount: plansState.plans.length + (plansState.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == plansState.plans.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child:
                  plansState.isLoadingMore
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
            ),
          );
        }

        final plan = plansState.plans[index];
        final author = plan.author;
        final authorName =
            author != null
                ? '${author.firstName} ${author.lastName}'.trim()
                : null;
        return _SessionListTile(
          title: plan.title,
          subtitle: authorName,
          imageUrl: plan.imageThumbnail,
          onTap: () => onPlanSelected(plan),
        );
      },
    );
  }
}

/// Tab content for displaying and selecting recitations.
class _RecitationsTab extends ConsumerWidget {
  final void Function(dynamic recitation) onRecitationSelected;

  const _RecitationsTab({required this.onRecitationSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final recitationsAsync = ref.watch(recitationsFutureProvider);

    return recitationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, _) => Center(
            child: Text(
              localizations.recitations_no_content,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
      data: (recitations) {
        if (recitations.isEmpty) {
          return Center(
            child: Text(
              localizations.recitations_no_content,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          itemCount: recitations.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final recitation = recitations[index];
            return _SessionListTile(
              title: recitation.title,
              subtitle: null,
              imageUrl: null,
              onTap: () => onRecitationSelected(recitation),
            );
          },
        );
      },
    );
  }
}

/// Reusable list tile for session selection (plans and recitations).
class _SessionListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final VoidCallback onTap;

  const _SessionListTile({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  imageUrl != null && imageUrl!.isNotEmpty
                      ? CachedNetworkImageWidget(
                        imageUrl: imageUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(8),
                      )
                      : Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.music_note,
                          color: AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
