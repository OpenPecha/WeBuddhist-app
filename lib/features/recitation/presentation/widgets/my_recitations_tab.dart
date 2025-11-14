import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/features/recitation/presentation/providers/recitations_providers.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MyRecitationsTab extends ConsumerWidget {
  const MyRecitationsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final localizations = AppLocalizations.of(context)!;

    // Show login prompt for guest users
    if (authState.isGuest) {
      return _buildLoginPrompt(context, localizations, ref);
    }

    final savedRecitationsAsync = ref.watch(savedRecitationsFutureProvider);

    return savedRecitationsAsync.when(
      data: (recitations) {
        if (recitations.isEmpty) {
          return _buildEmptyState(context, localizations);
        }
        return _buildRecitationsList(context, recitations, ref);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(context, error, localizations),
    );
  }

  Widget _buildRecitationsList(
    BuildContext context,
    List<RecitationModel> recitations,
    WidgetRef ref,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 16),
      itemCount: recitations.length,
      itemBuilder: (context, index) {
        final recitation = recitations[index];
        return RecitationCard(
          recitation: recitation,
          onTap: () {
            context.push('/recitations/detail', extra: recitation);
          },
          onMoreTap: () {
            _showRecitationOptions(context, recitation, ref);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No saved recitations',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Save recitations to access them here',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(
    BuildContext context,
    AppLocalizations localizations,
    WidgetRef ref,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 60,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Sign in to view your saved recitations',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                LoginDrawer.show(context, ref);
              },
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    Object error,
    AppLocalizations localizations,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load saved recitations',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  void _showRecitationOptions(
    BuildContext context,
    RecitationModel recitation,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.bookmark_remove_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  'Remove from Saved',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onTap: () async {
                  final result = await ref
                      .read(recitationsRepositoryProvider)
                      .unsaveRecitation(recitation.textId);
                  ref.invalidate(savedRecitationsFutureProvider);
                  if (context.mounted) Navigator.pop(context);
                  if (context.mounted && result) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Recitation unsaved'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to unsave recitation'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
              ),
              // ListTile(
              //   leading: const Icon(Icons.share_outlined),
              //   title: const Text('Share'),
              //   onTap: () {
              //     Navigator.pop(context);
              //     // TODO: Implement share functionality
              //   },
              // ),
            ],
          ),
        );
      },
    );
  }
}
