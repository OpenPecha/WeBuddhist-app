import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/routine_api_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/routine_empty_state.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/routine_filled_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

  void _onBuildRoutine(BuildContext context, WidgetRef ref) {
    final isGuest = ref.read(authProvider).isGuest;
    if (isGuest) {
      LoginDrawer.show(context, ref);
      return;
    }
    context.pushNamed('edit-routine');
  }

  /// Strips the `Exception: ` prefix from thrown errors so users do not see
  /// Dart runtime jargon. Falls back to the generic localized error message
  /// when the underlying error has no useful description.
  String _friendlyErrorMessage(Object error, AppLocalizations localizations) {
    if (error is Exception) {
      final raw = error.toString().replaceFirst('Exception: ', '').trim();
      if (raw.isNotEmpty) return raw;
    }
    return localizations.routine_load_error;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);

    // Show empty state for guests without hitting the API.
    if (authState.isGuest) {
      return _buildEmptyScaffold(context, ref, localizations);
    }

    if (authState.isLoading) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final routineAsync = ref.watch(userRoutineProvider);

    return routineAsync.when(
      loading:
          () => const Scaffold(
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          ),
      error:
          (error, _) => Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        localizations.routine_load_error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _friendlyErrorMessage(error, localizations),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => ref.invalidate(userRoutineProvider),
                        child: Text(localizations.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      // userRoutineProvider already maps RoutineResponse → RoutineData, so
      // the screen never touches API models or mapper functions.
      data: (routineData) {
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
        return _buildEmptyScaffold(context, ref, localizations);
      },
    );
  }

  /// Shared scaffold for the "no routine yet" state, used both for guests
  /// and for logged-in users whose routine is empty.
  Widget _buildEmptyScaffold(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations localizations,
  ) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
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
