import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/practice/data/providers/routine_provider.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/edit_routine_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/routine_empty_state.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/routine_filled_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  void _onBuildRoutine(BuildContext context, WidgetRef ref) {
    final isGuest = ref.read(authProvider).isGuest;
    if (isGuest) {
      LoginDrawer.show(context, ref);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditRoutineScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    
    // Guests always see empty state (they have no routine data)
    final routineData = authState.isGuest ? null : ref.watch(routineProvider);

    if (routineData != null && routineData.hasItems) {
      return Scaffold(
        body: SafeArea(
          child: RoutineFilledState(
            routineData: routineData,
            onEdit: () => _onBuildRoutine(context, ref),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                localizations.routine_empty_title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Divider(height: 1),
            ),
            Expanded(
              child: RoutineEmptyState(
                onBuildRoutine: () => _onBuildRoutine(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
