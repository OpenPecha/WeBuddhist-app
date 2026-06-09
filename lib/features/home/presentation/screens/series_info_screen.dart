import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/home/domain/entities/series.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/plan_inline_markdown_view.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SeriesInfoScreen extends ConsumerWidget {
  final Series series;

  const SeriesInfoScreen({super.key, required this.series});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final lineHeight = getLineHeight(locale.languageCode);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleFontSize = locale.languageCode == 'bo' ? 24.0 : 20.0;
    final bodyFontSize = locale.languageCode == 'bo' ? 18.0 : 15.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: ResponsiveCoverImage(
                            image: series.coverImage,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        series.title,
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          height: lineHeight,
                        ),
                      ),
                    ),
                    if (series.group != null) ...[
                      const SizedBox(height: 16),
                      _buildGroupRow(
                        context,
                        series.group!,
                        isDark,
                        lineHeight,
                      ),
                    ],
                    if (series.group?.description != null &&
                        series.group!.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildSection(
                        context,
                        body: series.description,
                        bodyFontSize: bodyFontSize,
                        lineHeight: lineHeight,
                        isDark: isDark,
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowLeft),
            onPressed: () => context.pop(),
          ),
          const Spacer(),
          const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }

  Widget _buildGroupRow(
    BuildContext context,
    SeriesGroup group,
    bool isDark,
    double? lineHeight,
  ) {
    final subtitleColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return GestureDetector(
      onTap: () => context.push('/home/group/${group.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor:
                  isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
              backgroundImage:
                  group.avatarUrl != null && group.avatarUrl!.isNotEmpty
                      ? NetworkImage(group.avatarUrl!)
                      : null,
              child:
                  (group.avatarUrl == null || group.avatarUrl!.isEmpty)
                      ? Icon(
                        Icons.group,
                        size: 20,
                        color: isDark ? AppColors.grey500 : AppColors.grey600,
                      )
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (group.title.isNotEmpty)
                    Text(
                      group.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: lineHeight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (group.subTitle != null &&
                      group.subTitle!.trim().isNotEmpty)
                    Text(
                      group.subTitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                        height: lineHeight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.grey500 : AppColors.grey600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String body,
    required double bodyFontSize,
    required double? lineHeight,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: PlanInlineMarkdownView(content: body, fontSize: bodyFontSize),
    );
  }
}
