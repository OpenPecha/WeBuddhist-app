import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/plans/data/providers/plans_providers.dart';
import 'package:flutter_pecha/features/plans/presentation/providers/find_plans_paginated_provider.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectPlanScreen extends ConsumerStatefulWidget {
  const SelectPlanScreen({super.key});

  @override
  ConsumerState<SelectPlanScreen> createState() => _SelectPlanScreenState();
}

class _SelectPlanScreenState extends ConsumerState<SelectPlanScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(findPlansPaginatedProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final plansState = ref.watch(findPlansPaginatedProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.routine_add_plan,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold),
        ),
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      body: _buildContent(context, plansState),
    );
  }

  Widget _buildContent(BuildContext context, FindPlansState plansState) {
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
          AppLocalizations.of(context)!.no_plans_found,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      itemCount: plansState.plans.length + (plansState.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == plansState.plans.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: plansState.isLoadingMore
                  ? const CircularProgressIndicator()
                  : const SizedBox.shrink(),
            ),
          );
        }

        final plan = plansState.plans[index];
        return _SelectablePlanCard(
          title: plan.title,
          subtitle: '${plan.totalDays} Days',
          imageUrl: plan.imageThumbnail,
          onTap: () => Navigator.of(context).pop(plan),
        );
      },
    );
  }
}

class _SelectablePlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback onTap;

  const _SelectablePlanCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              CachedNetworkImageWidget(
                imageUrl: imageUrl ?? '',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
