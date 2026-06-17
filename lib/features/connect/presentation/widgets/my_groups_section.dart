import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:go_router/go_router.dart';

class MyGroupsSection extends StatelessWidget {
  const MyGroupsSection({super.key, required this.groups});

  final List<GroupProfile> groups;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.connect_my_groups,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                l10n.see_all,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final group = groups[index];
              return _MyGroupItem(group: group, isDark: isDark);
            },
          ),
        ),
      ],
    );
  }
}

class _MyGroupItem extends StatelessWidget {
  const _MyGroupItem({required this.group, required this.isDark});

  final GroupProfile group;
  final bool isDark;

  String _displayName(GroupProfile group) {
    if (group.title.trim().isNotEmpty) return group.title;
    if (group.slug.trim().isNotEmpty) return group.slug;
    return group.id;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/home/group/${group.id}'),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceVariantDark : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.cardBorderDark : AppColors.grey100,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _GroupAvatar(group: group, isDark: isDark, size: 56),
            ),
            const SizedBox(height: 6),
            Text(
              _displayName(group),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({
    required this.group,
    required this.isDark,
    required this.size,
  });

  final GroupProfile group;
  final bool isDark;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (group.avatarUrl != null && group.avatarUrl!.isNotEmpty) {
      return Image.network(
        group.avatarUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder:
            (_, __, ___) => _PlaceholderAvatar(isDark: isDark, size: size),
      );
    }

    return _PlaceholderAvatar(isDark: isDark, size: size);
  }
}

class _PlaceholderAvatar extends StatelessWidget {
  const _PlaceholderAvatar({required this.isDark, required this.size});

  final bool isDark;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        AppAssets.usersThree,
        size: size * 0.45,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );
  }
}
