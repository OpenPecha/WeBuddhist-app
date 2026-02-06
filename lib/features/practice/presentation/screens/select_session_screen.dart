import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/plans/data/providers/plans_providers.dart';
import 'package:flutter_pecha/features/plans/data/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/practice/data/models/session_selection.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_pecha/shared/extensions/typography_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Combined screen for selecting either a Plan or Recitation to add to routine.
/// Returns [SessionSelection] - either [PlanSessionSelection] or [RecitationSessionSelection].
///
/// Automatically enrolls plans / saves recitations on selection.
/// Filters out already enrolled/saved items and items already in the routine.
class SelectSessionScreen extends ConsumerStatefulWidget {
  /// IDs of plans already in the routine (across all blocks).
  final Set<String> excludedPlanIds;

  /// IDs of recitations already in the routine (across all blocks).
  final Set<String> excludedRecitationIds;

  const SelectSessionScreen({
    super.key,
    this.excludedPlanIds = const {},
    this.excludedRecitationIds = const {},
  });

  @override
  ConsumerState<SelectSessionScreen> createState() =>
      _SelectSessionScreenState();
}

class _SelectSessionScreenState extends ConsumerState<SelectSessionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _plansScrollController = ScrollController();

  /// ID of the item currently being enrolled/saved (null if idle).
  String? _enrollingItemId;

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

  Future<void> _onPlanSelected(dynamic plan) async {
    if (_enrollingItemId != null) return;
    setState(() => _enrollingItemId = plan.id);
    try {
      final success = await ref.read(
        userPlanSubscribeFutureProvider(plan.id).future,
      );
      if (!mounted) return;
      if (success) {
        ref.invalidate(myPlansPaginatedProvider);
        Navigator.of(context).pop(PlanSessionSelection(plan));
      } else {
        setState(() => _enrollingItemId = null);
        _showErrorSnackbar('Unable to enroll in plan. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _enrollingItemId = null);
      _showErrorSnackbar('Unable to enroll in plan. Please try again.');
    }
  }

  Future<void> _onRecitationSelected(dynamic recitation) async {
    if (_enrollingItemId != null) return;
    setState(() => _enrollingItemId = recitation.textId);
    try {
      final success = await ref.read(
        saveRecitationProvider(recitation.textId).future,
      );
      if (!mounted) return;
      if (success) {
        ref.invalidate(savedRecitationsFutureProvider);
        Navigator.of(context).pop(RecitationSessionSelection(recitation));
      } else {
        setState(() => _enrollingItemId = null);
        _showErrorSnackbar('Unable to save recitation. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _enrollingItemId = null);
      _showErrorSnackbar('Unable to save recitation. Please try again.');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;

    // Get enrolled plan IDs from paginated provider (already loaded by app)
    final myPlansState = ref.watch(myPlansPaginatedProvider);
    final enrolledPlanIds = myPlansState.plans.map<String>((e) => e.id).toSet();

    // Get saved recitation IDs from backend
    final savedRecitationIds = ref
            .watch(savedRecitationsFutureProvider)
            .whenData((data) => data.map((e) => e.textId).toSet())
            .valueOrNull ??
        <String>{};

    // Combine backend enrolled/saved + items already in routine blocks
    final allExcludedPlanIds = {...enrolledPlanIds, ...widget.excludedPlanIds};
    final allExcludedRecitationIds = {
      ...savedRecitationIds,
      ...widget.excludedRecitationIds,
    };

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
            fontWeight: FontWeight.normal,
          ),
          labelColor:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
          unselectedLabelColor:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.5),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PlansTab(
            scrollController: _plansScrollController,
            excludedPlanIds: allExcludedPlanIds,
            enrollingItemId: _enrollingItemId,
            onPlanSelected: _onPlanSelected,
          ),
          _RecitationsTab(
            excludedRecitationIds: allExcludedRecitationIds,
            enrollingItemId: _enrollingItemId,
            onRecitationSelected: _onRecitationSelected,
          ),
        ],
      ),
    );
  }
}

/// Tab content for displaying and selecting plans.
/// Filters out plans that are already enrolled or in the routine.
class _PlansTab extends ConsumerWidget {
  final ScrollController scrollController;
  final Set<String> excludedPlanIds;
  final String? enrollingItemId;
  final void Function(dynamic plan) onPlanSelected;

  const _PlansTab({
    required this.scrollController,
    required this.excludedPlanIds,
    required this.enrollingItemId,
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

    // Filter out enrolled plans and plans already in routine
    final availablePlans =
        plansState.plans
            .where((plan) => !excludedPlanIds.contains(plan.id))
            .toList();

    if (availablePlans.isEmpty && !plansState.isLoading) {
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
      itemCount: availablePlans.length + (plansState.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == availablePlans.length) {
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

        final plan = availablePlans[index];
        final author = plan.author;
        final authorName =
            author != null
                ? '${author.firstName} ${author.lastName}'.trim()
                : null;
        final isEnrolling = enrollingItemId == plan.id;

        return _SessionListTile(
          title: plan.title,
          subtitle: authorName,
          imageUrl: plan.imageThumbnail,
          isLoading: isEnrolling,
          isDisabled: enrollingItemId != null,
          onTap: () => onPlanSelected(plan),
        );
      },
    );
  }
}

/// Tab content for displaying and selecting recitations.
/// Filters out recitations that are already saved or in the routine.
class _RecitationsTab extends ConsumerWidget {
  final Set<String> excludedRecitationIds;
  final String? enrollingItemId;
  final void Function(dynamic recitation) onRecitationSelected;

  const _RecitationsTab({
    required this.excludedRecitationIds,
    required this.enrollingItemId,
    required this.onRecitationSelected,
  });

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
        // Filter out saved recitations and recitations already in routine
        final availableRecitations =
            recitations
                .where((r) => !excludedRecitationIds.contains(r.textId))
                .toList();

        if (availableRecitations.isEmpty) {
          return Center(
            child: Text(
              localizations.recitations_no_content,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          itemCount: availableRecitations.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final recitation = availableRecitations[index];
            final isEnrolling = enrollingItemId == recitation.textId;

            return _SessionListTile(
              title: recitation.title,
              subtitle: null,
              imageUrl: null,
              isLoading: isEnrolling,
              isDisabled: enrollingItemId != null,
              onTap: () => onRecitationSelected(recitation),
            );
          },
        );
      },
    );
  }
}

/// Reusable list tile for session selection (plans and recitations).
/// Supports loading and disabled states for enrollment/save feedback.
class _SessionListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final VoidCallback onTap;
  final bool isLoading;
  final bool isDisabled;

  const _SessionListTile({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: AnimatedOpacity(
        opacity: isDisabled && !isLoading ? 0.5 : 1.0,
        duration: const Duration(milliseconds: 200),
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
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(left: 12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
