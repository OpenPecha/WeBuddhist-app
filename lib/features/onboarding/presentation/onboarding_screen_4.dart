import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/onboarding/application/onboarding_provider.dart';
import 'package:flutter_pecha/features/onboarding/models/onboarding_preferences.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_back_button.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_checkbox_option.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_continue_button.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_question_title.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Fourth onboarding screen: "Which path or school do you feel drawn to?"
/// Based on Figma design node-id=127-154
class OnboardingScreen4 extends ConsumerWidget {
  const OnboardingScreen4({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  static const int _maxSelections = 3;

  static const List<_PathOption> _paths = [
    _PathOption(id: BuddhistPath.theravada, label: 'Theravada'),
    _PathOption(id: BuddhistPath.zen, label: 'Zen'),
    _PathOption(id: BuddhistPath.tibetanBuddhism, label: 'Tibetan Buddhism'),
    _PathOption(id: BuddhistPath.pureLand, label: 'Pure land'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPaths = ref.watch(
      onboardingProvider.select(
        (state) => state.preferences.selectedPaths ?? [],
      ),
    );
    final appLocalizations = AppLocalizations.of(context);
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
                      OnboardingQuestionTitle(
                        title: appLocalizations!.onboarding_second_question,
                      ),
                      const SizedBox(height: 16),
                      _buildSubtitle(context),
                      const SizedBox(height: 44),
                      _buildPathOptions(ref, selectedPaths),
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

  Widget _buildSubtitle(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context);
    return Text(
      appLocalizations!.onboarding_choose_option,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.272,
        color: Color(0xFF707070),
      ),
    );
  }

  Widget _buildPathOptions(WidgetRef ref, List<String> selectedPaths) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            _paths.map((path) {
              final isSelected = selectedPaths.contains(path.id);
              final canSelect =
                  selectedPaths.length < _maxSelections || isSelected;
              return OnboardingCheckboxOption(
                id: path.id,
                label: path.label,
                isSelected: isSelected,
                isEnabled: canSelect,
                onTap: () => _togglePath(ref, path.id, selectedPaths),
              );
            }).toList(),
      ),
    );
  }

  void _togglePath(WidgetRef ref, String pathId, List<String> currentPaths) {
    final newPaths = List<String>.from(currentPaths);
    if (newPaths.contains(pathId)) {
      newPaths.remove(pathId);
    } else {
      if (newPaths.length < _maxSelections) {
        newPaths.add(pathId);
      }
    }
    ref.read(onboardingProvider.notifier).setSelectedPaths(newPaths);
  }

  void _handleContinue(WidgetRef ref) {
    final selectedPaths =
        ref.read(onboardingProvider).preferences.selectedPaths;
    if (selectedPaths != null && selectedPaths.isNotEmpty) {
      onNext();
    }
  }
}

class _PathOption {
  const _PathOption({required this.id, required this.label});

  final String id;
  final String label;
}
