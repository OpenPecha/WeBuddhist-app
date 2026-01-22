import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/plans/data/providers/plans_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pecha/features/app/presentation/skeleton_screen.dart';

/// Handler screen for plan invitation deep links
/// Fetches plan data and navigates to PlanInfo screen
class PlanInviteHandler extends ConsumerWidget {
  const PlanInviteHandler({super.key, required this.planId});

  final String planId;
  static final _logger = AppLogger('PlanInviteHandler');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    
    // Fetch plan data
    final planAsync = ref.watch(planByIdFutureProvider(planId));

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.plan_info),
      ),
      body: planAsync.when(
        data: (plan) {
          _logger.info('Plan loaded: ${plan.title}');
          
          // Check if plan already has author data embedded
          if (plan.author != null) {
            // Author data already embedded, navigate directly
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navigateToPlanInfo(context, plan, plan.author);
            });
            return _buildLoadingState(localizations.plan_info);
          } else {
            // No author data, navigate without author
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navigateToPlanInfo(context, plan, null);
            });
            return _buildLoadingState(localizations.plan_info);
          }
        },
        loading: () => _buildLoadingState(localizations.plan_info),
        error: (error, stackTrace) {
          _logger.error('Error loading plan', error);
          return _buildErrorState(
            context,
            ref,
            localizations,
            'Unable to load plan. Please try again.',
          );
        },
      ),
    );
  }


  void _navigateToPlanInfo(
    BuildContext context,
    dynamic plan,
    dynamic author,
  ) {
    if (!context.mounted) return;

    _logger.info('Navigating to PlanInfo for plan: ${plan.title}');

    // Use pushReplacement to replace the handler screen
    context.pushReplacement(
      '/plans/info',
      extra: {
        'plan': plan,
        'author': author,
      },
    );
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations localizations,
    String message,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                // Reset bottom nav index to 0 (texts tab) when navigating home
                ref.read(bottomNavIndexProvider.notifier).state = 0;
                context.go('/home');
              },
              child: Text(localizations.nav_home),
            ),
          ],
        ),
      ),
    );
  }
}
