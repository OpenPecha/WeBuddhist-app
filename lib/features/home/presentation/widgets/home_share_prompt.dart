import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/services/app_share/app_share_service.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Home screen prompt that invites the user to share WeBuddhist with others.
class HomeSharePrompt extends ConsumerWidget {
  const HomeSharePrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PromptLabel(),
          const SizedBox(height: 12.0),
          _ShareButton(
            onTap: () => ref.read(appShareServiceProvider).shareApp(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _PromptLabel extends StatelessWidget {
  const _PromptLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Enjoying WeBuddhist?',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimaryLight,
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ShareButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.greyLight,
      borderRadius: BorderRadius.circular(999.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999.0),
        child: SizedBox(
          width: double.infinity,
          height: 52.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PhosphorIcon(
                PhosphorIconsBold.export,
                size: 22.0,
                color: Theme.of(context).colorScheme.onSurface,
                
              ),
              const SizedBox(width: 8.0),
              Text(
                'Share',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                  fontSize: 16.0,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
