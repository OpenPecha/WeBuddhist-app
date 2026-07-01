import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_pecha/features/mala/presentation/providers/accumulator_groups_provider.dart';
import 'package:flutter_pecha/features/mala/presentation/widgets/group_accumulations_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pill entry point for group accumulations on the mala screen.
///
/// Always reserves [barHeight] so bead layout does not shift when the groups
/// request resolves. The pill is shown only when
/// `GET /accumulators/{presetId}/groups?joined_only=true` returns groups.
class GroupAccumulationsBar extends ConsumerWidget {
  const GroupAccumulationsBar({
    super.key,
    required this.presetId,
    required this.userTotalCount,
  });

  final String presetId;
  final int userTotalCount;

  static const barHeight = 40.0;
  static const _avatarSize = 28.0;
  static const _avatarOverlap = 10.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(joinedAccumulatorGroupsProvider(presetId));

    return SizedBox(
      height: barHeight,
      child: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) return const SizedBox.shrink();
          return _GroupAccumulationsBarContent(
            groups: groups,
            userTotalCount: userTotalCount,
            avatarSize: _avatarSize,
            avatarOverlap: _avatarOverlap,
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

class _GroupAccumulationsBarContent extends StatelessWidget {
  const _GroupAccumulationsBarContent({
    required this.groups,
    required this.userTotalCount,
    required this.avatarSize,
    required this.avatarOverlap,
  });

  final List<AccumulatorGroup> groups;
  final int userTotalCount;
  final double avatarSize;
  final double avatarOverlap;

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final preview = groups.take(2).toList();
    final stackWidth =
        preview.length == 1 ? avatarSize : avatarSize + avatarOverlap;

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap:
              () => GroupAccumulationsSheet.show(
                context,
                groups: groups,
                userTotalCount: userTotalCount,
              ),
          child: Container(
            height: GroupAccumulationsBar.barHeight,
            padding: const EdgeInsets.fromLTRB(6, 6, 8, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: stackWidth,
                  height: avatarSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = 0; i < preview.length; i++)
                        Positioned(
                          left: i * avatarOverlap,
                          child: _GroupAvatar(
                            group: preview[i],
                            size: avatarSize,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: iconColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  const _GroupAvatar({required this.group, required this.size});

  final AccumulatorGroup group;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fallbackColor =
        Theme.of(context).colorScheme.surfaceContainerHighest;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fallbackColor,
        border: Border.all(color: AppColors.surfaceWhite, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: ResponsiveCoverImage(
        image: group.image,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
