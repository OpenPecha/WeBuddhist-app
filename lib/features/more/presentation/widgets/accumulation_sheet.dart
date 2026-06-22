import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/more/domain/entities/mantra_count.dart';
import 'package:flutter_pecha/features/more/presentation/providers/mantra_counts_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AccumulationSheet extends ConsumerWidget {
  const AccumulationSheet({super.key, required this.formattedTotal});

  final String formattedTotal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asyncData = ref.watch(mantraCountsProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.goldLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            asyncData.when(
              data: (either) {
                final page = either.fold(
                  (_) => MantraCountPage.empty,
                  (page) => page,
                );

                return Flexible(
                  child: _AccumulationSheetContent(
                    formattedTotal: formattedTotal,
                    counts: page.counts,
                    hasError: either.isLeft(),
                  ),
                );
              },
              loading:
                  () => Flexible(
                    child: _AccumulationSheetContent(
                      formattedTotal: formattedTotal,
                      counts: const [],
                      isLoading: true,
                    ),
                  ),
              error:
                  (_, __) => Flexible(
                    child: _AccumulationSheetContent(
                      formattedTotal: formattedTotal,
                      counts: const [],
                      hasError: true,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccumulationSheetContent extends StatelessWidget {
  const _AccumulationSheetContent({
    required this.formattedTotal,
    required this.counts,
    this.isLoading = false,
    this.hasError = false,
  });

  final String formattedTotal;
  final List<MantraCount> counts;
  final bool isLoading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Image.asset(
                  AppAssets.homeMalaIcon,
                  width: 22,
                  height: 22,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.me_accumulation,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  formattedTotal,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, thickness: 1, color: dividerColor),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            )
          else if (counts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Text(
                hasError ? l10n.something_went_wrong : l10n.no_plans_found,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.grey300 : AppColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: counts.length,
                separatorBuilder:
                    (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      indent: 20,
                      endIndent: 20,
                      color: dividerColor,
                    ),
                itemBuilder: (context, index) {
                  return _MantraCountRow(count: counts[index]);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _MantraCountRow extends StatelessWidget {
  const _MantraCountRow({required this.count});

  final MantraCount count;

  @override
  Widget build(BuildContext context) {
    final locale = intlFormatLocaleOf(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          _MalaBeadImage(imageUrl: count.malaImageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              count.mantraTitle,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            NumberFormat.decimalPattern(locale).format(count.totalCount),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MalaBeadImage extends StatelessWidget {
  const _MalaBeadImage({this.imageUrl});

  final String? imageUrl;

  static const _size = 44.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(shape: BoxShape.circle),
      child: ClipOval(
        child: CachedNetworkImageWidget(
          imageUrl: imageUrl,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          fallbackAsset: AppAssets.homeMalaIcon,
        ),
      ),
    );
  }
}

void showAccumulationSheet(
  BuildContext context, {
  required String formattedTotal,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => AccumulationSheet(formattedTotal: formattedTotal),
  );
}
