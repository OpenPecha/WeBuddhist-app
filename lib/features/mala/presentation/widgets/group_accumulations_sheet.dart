import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/l10n/intl_format_locale.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/mala/domain/entities/accumulator_group.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class GroupAccumulationsSheet extends ConsumerStatefulWidget {
  const GroupAccumulationsSheet({
    super.key,
    required this.groups,
    required this.userTotalCount,
  });

  final List<AccumulatorGroup> groups;
  final int userTotalCount;

  static Future<void> show(
    BuildContext context, {
    required List<AccumulatorGroup> groups,
    required int userTotalCount,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder:
          (_) => GroupAccumulationsSheet(
            groups: groups,
            userTotalCount: userTotalCount,
          ),
    );
  }

  @override
  ConsumerState<GroupAccumulationsSheet> createState() =>
      _GroupAccumulationsSheetState();
}

class _GroupAccumulationsSheetState
    extends ConsumerState<GroupAccumulationsSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureUserLoaded());
  }

  /// Profile is cached locally after login; refresh from GET /users/info when
  /// the sheet opens and no cached user is available yet.
  void _ensureUserLoaded() {
    final userState = ref.read(userProvider);
    if (userState.user == null && !userState.isLoading) {
      ref.read(userProvider.notifier).refreshUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(userProvider).user;
    final accentColor = isDark ? AppColors.blueDark : AppColors.blue;
    final dividerColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final locale = intlFormatLocaleOf(context);
    final formattedUserCount = NumberFormat.decimalPattern(
      locale,
    ).format(widget.userTotalCount);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.goldLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  context.l10n.mala_group_accumulations,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _UserAccumulationRow(
                user: user,
                formattedCount: formattedUserCount,
                accentColor: accentColor,
              ),
              const SizedBox(height: 12),
              Divider(height: 1, thickness: 1, color: dividerColor),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  context.l10n.mala_groups_section,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: widget.groups.length,
                  separatorBuilder:
                      (_, __) => Divider(
                        height: 1,
                        thickness: 1,
                        indent: 20,
                        endIndent: 20,
                        color: dividerColor,
                      ),
                  itemBuilder: (context, index) {
                    return _GroupAccumulationRow(
                      group: widget.groups[index],
                      locale: locale,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserAccumulationRow extends StatelessWidget {
  const _UserAccumulationRow({
    required this.user,
    required this.formattedCount,
    required this.accentColor,
  });

  final User? user;
  final String formattedCount;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final nameStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: accentColor,
      fontWeight: FontWeight.w500,
    );
    final countStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: accentColor,
      fontWeight: FontWeight.w700,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _UserAvatar(avatarUrl: user?.avatarUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user != null ? _userDisplayName(user!) : '—',
              style: nameStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(formattedCount, style: countStyle),
        ],
      ),
    );
  }

  String _userDisplayName(User user) {
    final parts =
        [
          user.firstName,
          user.lastName,
        ].whereType<String>().where((name) => name.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(' ');
    return user.displayName;
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({this.avatarUrl});

  final String? avatarUrl;

  static const _size = 40.0;

  @override
  Widget build(BuildContext context) {
    final fallbackColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return ClipOval(
      child: SizedBox(
        width: _size,
        height: _size,
        child:
            avatarUrl != null && avatarUrl!.isNotEmpty
                ? CachedNetworkImageWidget(
                  imageUrl: avatarUrl,
                  width: _size,
                  height: _size,
                  fit: BoxFit.cover,
                )
                : ColoredBox(
                  color: fallbackColor,
                  child: Icon(
                    AppAssets.profile,
                    size: 22,
                    color: AppColors.grey600,
                  ),
                ),
      ),
    );
  }
}

class _GroupAccumulationRow extends StatelessWidget {
  const _GroupAccumulationRow({required this.group, required this.locale});

  final AccumulatorGroup group;
  final String locale;

  static const _avatarSize = 40.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholderColor =
        isDark ? AppColors.surfaceVariantDark : AppColors.grey100;
    final formattedCount = NumberFormat.decimalPattern(
      locale,
    ).format(group.userTotalCount);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipOval(
            child: SizedBox(
              width: _avatarSize,
              height: _avatarSize,
              child:
                  group.image != null && !group.image!.isEmpty
                      ? ResponsiveCoverImage(
                        image: group.image,
                        width: _avatarSize,
                        height: _avatarSize,
                        fit: BoxFit.cover,
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
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              group.title!.trim(),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formattedCount,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
