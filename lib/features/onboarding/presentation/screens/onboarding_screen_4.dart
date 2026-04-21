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

  static const List<_PathOption> _paths = [
    _PathOption(id: BuddhistPath.theravada, label: 'Theravada'),
    _PathOption(id: BuddhistPath.zen, label: 'Zen'),
    _PathOption(id: BuddhistPath.tibetanBuddhism, label: 'Tibetan Buddhism'),
    _PathOption(id: BuddhistPath.pureLand, label: 'Pure Land'),
    _PathOption(id: BuddhistPath.ambedkarBuddhism, label: 'Ambedkar Buddhism'),
  ];

  static final List<String> _allPathIds =
      _paths.map((p) => p.id).toList();

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              OnboardingBackButton(onBack: onBack),
              const SizedBox(height: 40),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const OnboardingQuestionTitle(
                        title: 'Which traditions\ndo you follow?',
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
            label: 'Select all',
            isSelected: allSelected,
            isEnabled: true,
            onTap: () => _toggleSelectAll(ref, selectedPaths, allSelected),
          ),
          ..._paths.map((path) {
            final isSelected = selectedPaths.contains(path.id);
            return OnboardingCheckboxOption(
              id: path.id,
              label: path.label,
              isSelected: isSelected,
              isEnabled: true,
              onTap: () => _togglePath(ref, path.id, selectedPaths),
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

class _PathOption {
  const _PathOption({required this.id, required this.label});

  final String id;
  final String label;
}
