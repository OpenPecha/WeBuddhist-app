import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_member.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupProfileMembersTab extends ConsumerStatefulWidget {
  final String groupId;
  final GroupType groupType;
  final bool isDark;
  final double? lineHeight;

  const GroupProfileMembersTab({
    super.key,
    required this.groupId,
    required this.groupType,
    required this.isDark,
    this.lineHeight,
  });

  @override
  ConsumerState<GroupProfileMembersTab> createState() =>
      _GroupProfileMembersTabState();
}

class _GroupProfileMembersTabState
    extends ConsumerState<GroupProfileMembersTab> {
  final ScrollController _scrollController = ScrollController();
  bool _hasRequestedInitialLoad = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialIfNeeded();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialIfNeeded() {
    if (_hasRequestedInitialLoad) return;
    _hasRequestedInitialLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(groupMembersProvider(widget.groupId).notifier).loadInitial();
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(groupMembersProvider(widget.groupId).notifier).loadMore();
    }
  }

  String _membersHeading(BuildContext context, int count) {
    return widget.groupType.isPage
        ? context.l10n.group_followers_heading(count)
        : context.l10n.group_members_heading(count);
  }

  @override
  Widget build(BuildContext context) {
    final membersState = ref.watch(groupMembersProvider(widget.groupId));

    if (membersState.isLoading && membersState.members.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (membersState.error != null && membersState.members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ErrorStateWidget(
            error: membersState.error!,
            onRetry:
                () =>
                    ref
                        .read(groupMembersProvider(widget.groupId).notifier)
                        .retry(),
            customMessage:
                widget.groupType.isPage
                    ? context.l10n.group_followers_load_error
                    : context.l10n.group_members_load_error,
          ),
        ),
      );
    }

    if (membersState.members.isEmpty) {
      return ListView(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 16, bottom: 32),
        children: [
          if (!membersState.isLoading)
            _MembersHeading(
              title: _membersHeading(context, membersState.totalMembers),
              isDark: widget.isDark,
              lineHeight: widget.lineHeight,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Text(
              widget.groupType.isPage
                  ? context.l10n.group_followers_empty
                  : context.l10n.group_members_empty,
              style: TextStyle(
                fontSize: 15,
                color:
                    widget.isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textSecondary,
                height: widget.lineHeight,
              ),
            ),
          ),
        ],
      );
    }

    final itemCount =
        1 + membersState.members.length + (membersState.isLoadingMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _MembersHeading(
            title: _membersHeading(context, membersState.totalMembers),
            isDark: widget.isDark,
            lineHeight: widget.lineHeight,
          );
        }

        final memberIndex = index - 1;
        if (memberIndex < membersState.members.length) {
          return _GroupMemberRow(
            member: membersState.members[memberIndex],
            isDark: widget.isDark,
            lineHeight: widget.lineHeight,
          );
        }

        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class _MembersHeading extends StatelessWidget {
  final String title;
  final bool isDark;
  final double? lineHeight;

  const _MembersHeading({
    required this.title,
    required this.isDark,
    this.lineHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          height: lineHeight,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _GroupMemberRow extends StatelessWidget {
  final GroupMember member;
  final bool isDark;
  final double? lineHeight;

  const _GroupMemberRow({
    required this.member,
    required this.isDark,
    this.lineHeight,
  });

  @override
  Widget build(BuildContext context) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final displayName =
        member.fullname.trim().isNotEmpty
            ? member.fullname.trim()
            : member.username;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          child: Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child:
                      member.avatarUrl != null && member.avatarUrl!.isNotEmpty
                          ? CachedNetworkImageWidget(
                            key: ValueKey(member.avatarUrl),
                            imageUrl: member.avatarUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorWidget: _buildAvatarFallback(isDark),
                          )
                          : _buildAvatarFallback(isDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: lineHeight,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (member.username.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '@${member.username}',
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryColor,
                            height: lineHeight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildAvatarFallback(bool isDark) {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.profile,
        size: 22,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );
  }
}
