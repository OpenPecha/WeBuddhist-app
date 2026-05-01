import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/reader/presentation/providers/reader_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TranslationPanelHeader extends ConsumerWidget {
  final VoidCallback onClose;
  final ReaderParams params;
  final double availableHeight;

  const TranslationPanelHeader({
    super.key,
    required this.onClose,
    required this.params,
    required this.availableHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = context.l10n;
    final notifier = ref.read(readerNotifierProvider(params).notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onVerticalDragUpdate: (details) {
            final state = ref.read(readerNotifierProvider(params));
            final currentMainHeight = availableHeight * state.splitRatio;
            final newRatio =
                (currentMainHeight + details.delta.dy) / availableHeight;
            notifier.updateSplitRatio(newRatio);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.symmetric(
                horizontal: BorderSide(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColors.greyDark
                          : AppColors.greyLight,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Text(
                  localizations.text_translations,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  tooltip: localizations.text_close_translation,
                  iconSize: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
