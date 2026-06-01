import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/onboarding/application/onboarding_provider.dart';
import 'package:flutter_pecha/features/onboarding/domain/entities/onboarding_preferences.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_back_button.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_checkbox_option.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_continue_button.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_question_title.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Fourth onboarding screen: "Which traditions do you follow?"
class OnboardingScreen4 extends ConsumerWidget {
  const OnboardingScreen4({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  static const List<String> _allPathIds = [
    BuddhistPath.theravada,
    BuddhistPath.zen,
    BuddhistPath.tibetanBuddhism,
    BuddhistPath.pureLand,
    BuddhistPath.ambedkarBuddhism,
  ];

  String _pathLabel(AppLocalizations l10n, String id) {
    switch (id) {
      case BuddhistPath.theravada:
        return l10n.tradition_theravada;
      case BuddhistPath.zen:
        return l10n.tradition_zen;
      case BuddhistPath.tibetanBuddhism:
        return l10n.tradition_tibetan_buddhism;
      case BuddhistPath.pureLand:
        return l10n.tradition_pure_land;
      case BuddhistPath.ambedkarBuddhism:
        return l10n.tradition_ambedkar_buddhism;
      default:
        return id;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPaths = ref.watch(
      onboardingProvider.select(
        (state) => state.preferences.selectedPaths,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    OnboardingBackButton(onBack: onBack),
                    const SizedBox(height: 40),
                    OnboardingQuestionTitle(
                      title: AppLocalizations.of(context)!.onboarding_traditions_question,
                    ),
                    const SizedBox(height: 44),
                    _buildPathOptions(context, ref, selectedPaths),
                    const Spacer(),
                    Center(
                      child: OnboardingContinueButton(
                        onPressed: () => _handleContinue(ref),
                        isEnabled: selectedPaths.isNotEmpty,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathOptions(
    BuildContext context,
    WidgetRef ref,
    List<String> selectedPaths,
  ) {
    final allSelected = _allPathIds.every(selectedPaths.contains);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboarding_choose_option,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.272,
              color: Color(0xFF707070),
            ),
          ),
          const SizedBox(height: 16),
          OnboardingCheckboxOption(
            id: 'select_all',
            label: l10n.onboarding_select_all,
            isSelected: allSelected,
            isEnabled: true,
            onTap: () => _toggleSelectAll(ref, selectedPaths, allSelected),
          ),
          ..._allPathIds.map((pathId) {
            final isSelected = selectedPaths.contains(pathId);
            return OnboardingCheckboxOption(
              id: pathId,
              label: _pathLabel(l10n, pathId),
              isSelected: isSelected,
              isEnabled: true,
              onTap: () => _togglePath(ref, pathId, selectedPaths),
            );
          }),
        ],
      ),
    );
  }

  void _toggleSelectAll(
    WidgetRef ref,
    List<String> currentPaths,
    bool allSelected,
  ) {
    final newPaths = allSelected ? <String>[] : List<String>.from(_allPathIds);
    ref.read(onboardingProvider.notifier).setSelectedPaths(newPaths);
  }

  void _togglePath(WidgetRef ref, String pathId, List<String> currentPaths) {
    final newPaths = List<String>.from(currentPaths);
    if (newPaths.contains(pathId)) {
      newPaths.remove(pathId);
    } else {
      newPaths.add(pathId);
    }
    ref.read(onboardingProvider.notifier).setSelectedPaths(newPaths);
  }

  void _handleContinue(WidgetRef ref) {
    final selectedPaths =
        ref.read(onboardingProvider).preferences.selectedPaths;
    if (selectedPaths.isNotEmpty) {
      onNext();
    }
  }
}

