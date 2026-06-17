import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class GroupSearchResultCard extends StatelessWidget {
  const GroupSearchResultCard({super.key, required this.group});

  final GroupProfile group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/home/group/${group.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              _GroupAvatar(group: group, isDark: isDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: subtitleColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(BuildContext context) {
    final typeLabel =
        group.subTitle ??
        (group.tags.isNotEmpty ? group.tags.first : group.groupType.name);
    final memberCount = group.memberCount;
    final formattedCount = _formatCompactCount(
      memberCount,
      intlFormatLocaleOf(context),
    );
    final memberLabel =
        memberCount == 1
            ? context.l10n.group_member
            : context.l10n.group_members;

    return '$typeLabel · $formattedCount $memberLabel';
  }

  String _formatCompactCount(int count, String locale) {
    if (count >= 1000000) {
      final value = count / 1000000;
      return '${_trimTrailingZero(value.toStringAsFixed(1))}M';
    }
    if (count >= 1000) {
      final value = count / 1000;
      return '${_trimTrailingZero(value.toStringAsFixed(1))}k';
    }
    return NumberFormat.decimalPattern(locale).format(count);
  }

  String _trimTrailingZero(String value) {
    return value.endsWith('.0') ? value.substring(0, value.length - 2) : value;
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.group, required this.isDark});

  final GroupProfile group;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final placeholderColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.grey100;

    return ClipOval(
      child: SizedBox(
        width: 48,
        height: 48,
        child:
            group.avatarUrl != null && group.avatarUrl!.isNotEmpty
                ? CachedNetworkImageWidget(
                  imageUrl: group.avatarUrl!,
                  fit: BoxFit.cover,
                  width: 48,
                  height: 48,
                )
                : ColoredBox(
                  color: placeholderColor,
                  child: Icon(
                    AppAssets.usersThree,
                    size: 22,
                    color: isDark ? AppColors.grey500 : AppColors.grey600,
                  ),
                ),
      ),
    );
  }
}
