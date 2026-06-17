import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';
import 'package:flutter_pecha/features/connect/presentation/providers/connect_providers.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DiscoverGroupCard extends ConsumerStatefulWidget {
  const DiscoverGroupCard({
    super.key,
    required this.group,
    required this.isJoined,
  });

  final GroupProfile group;
  final bool isJoined;

  @override
  ConsumerState<DiscoverGroupCard> createState() => _DiscoverGroupCardState();
}

class _DiscoverGroupCardState extends ConsumerState<DiscoverGroupCard> {
  bool _isJoining = false;
  bool _joinedLocally = false;

  bool get _isFollowing => widget.isJoined || _joinedLocally;

  Future<void> _onJoinPressed() async {
    if (_isFollowing) {
      context.push('/home/group/${widget.group.id}');
      return;
    }

    final authState = ref.read(authProvider);
    if (authState.isGuest || !authState.isLoggedIn) {
      LoginDrawer.show(context, ref);
      return;
    }

    setState(() => _isJoining = true);
    final followKey = GroupFollowKey(
      groupId: widget.group.id,
      groupType: widget.group.groupType,
    );
    final success = await ref
        .read(groupFollowProvider(followKey).notifier)
        .follow();
    if (!mounted) return;

    setState(() {
      _isJoining = false;
      if (success) _joinedLocally = true;
    });

    if (success) {
      ref.invalidate(joinedGroupsProvider);
      ref.invalidate(discoverGroupsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final locale = Localizations.localeOf(context);
    final formattedCount = NumberFormat.decimalPattern(
      locale.toString(),
    ).format(widget.group.joinerCount);
    final memberLabel =
        widget.group.joinerCount == 1
            ? context.l10n.group_member
            : context.l10n.group_members;
    final tagLabel =
        widget.group.tags.isNotEmpty
            ? widget.group.tags.first
            : widget.group.slug;

    return InkWell(
      onTap: () => context.push('/home/group/${widget.group.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.cardBorderDark : AppColors.grey100,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
              backgroundImage:
                  widget.group.avatarUrl != null &&
                          widget.group.avatarUrl!.isNotEmpty
                      ? NetworkImage(widget.group.avatarUrl!)
                      : null,
              child:
                  (widget.group.avatarUrl == null ||
                          widget.group.avatarUrl!.isEmpty)
                      ? Icon(
                        AppAssets.usersThree,
                        size: 22,
                        color: isDark ? AppColors.grey500 : AppColors.grey600,
                      )
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$tagLabel · $formattedCount $memberLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _JoinButton(
              isFollowing: _isFollowing,
              isLoading: _isJoining,
              onPressed: _onJoinPressed,
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({
    required this.isFollowing,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isFollowing;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey50,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child:
              isLoading
                  ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onSurface,
                    ),
                  )
                  : Text(
                    isFollowing ? l10n.joined : l10n.join,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
        ),
      ),
    );
  }
}
