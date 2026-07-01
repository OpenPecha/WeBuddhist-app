import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/core/widgets/responsive_cover_image.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_accumulator.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_accumulator_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class GroupAccumulatorScreen extends ConsumerStatefulWidget {
  final String accumulatorId;
  final String? groupTitle;

  const GroupAccumulatorScreen({
    super.key,
    required this.accumulatorId,
    this.groupTitle,
  });

  @override
  ConsumerState<GroupAccumulatorScreen> createState() =>
      _GroupAccumulatorScreenState();
}

class _GroupAccumulatorScreenState extends ConsumerState<GroupAccumulatorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  GroupAccumulatorMemberSort _memberSort = GroupAccumulatorMemberSort.total;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(
      groupAccumulatorDetailProvider(widget.accumulatorId),
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: detailAsync.when(
                data:
                    (either) => either.fold(
                      (failure) => Center(
                        child: ErrorStateWidget(
                          error: failure,
                          onRetry:
                              () => ref.invalidate(
                                groupAccumulatorDetailProvider(
                                  widget.accumulatorId,
                                ),
                              ),
                        ),
                      ),
                      (detail) => _buildContent(context, detail, isDark),
                    ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, _) => Center(
                      child: ErrorStateWidget(
                        error: error,
                        onRetry:
                            () => ref.invalidate(
                              groupAccumulatorDetailProvider(
                                widget.accumulatorId,
                              ),
                            ),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final title = widget.groupTitle?.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(AppAssets.arrowLeft),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(
              title != null && title.isNotEmpty ? title : '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 48, height: 48),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    GroupAccumulatorDetail detail,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _AccumulatorHeroCard(detail: detail, isDark: isDark),
        ),
        TabBar(
          controller: _tabController,
          labelColor: isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
          unselectedLabelColor:
              isDark ? AppColors.textTertiaryDark : AppColors.textSecondary,
          indicatorColor:
              isDark ? AppColors.surfaceWhite : AppColors.textPrimary,
          indicatorWeight: 2,
          dividerHeight: 1,
          dividerColor: isDark ? AppColors.cardBorderDark : AppColors.grey300,
          tabs: [
            Tab(text: context.l10n.group_accumulator_leaderboard),
            Tab(text: context.l10n.group_accumulator_my_contributions),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _LeaderboardTab(
                accumulatorId: widget.accumulatorId,
                sort: _memberSort,
                isDark: isDark,
                onSortChanged: (sort) {
                  setState(() => _memberSort = sort);
                },
              ),
              _MyContributionsTab(detail: detail, isDark: isDark),
            ],
          ),
        ),
      ],
    );
  }
}

class _MyContributionsTab extends StatefulWidget {
  final GroupAccumulatorDetail detail;
  final bool isDark;

  const _MyContributionsTab({required this.detail, required this.isDark});

  @override
  State<_MyContributionsTab> createState() => _MyContributionsTabState();
}

class _MyContributionsTabState extends State<_MyContributionsTab> {
  GroupAccumulatorMemberSort _sort = GroupAccumulatorMemberSort.total;

  @override
  Widget build(BuildContext context) {
    final user = widget.detail.user;
    final secondaryColor =
        widget.isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final locale = Localizations.localeOf(context).toString();
    final numberFormat = NumberFormat.decimalPattern(locale);

    if (user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            context.l10n.group_accumulator_contributions_empty,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: secondaryColor),
          ),
        ),
      );
    }

    final count =
        _sort == GroupAccumulatorMemberSort.today
            ? user.todayCount
            : user.totalCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(
          children: [
            Text(
              context.l10n.group_accumulator_recited,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color:
                    widget.isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            _SortToggle(
              sort: _sort,
              isDark: widget.isDark,
              onChanged: (sort) => setState(() => _sort = sort),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _MemberAvatar(avatarUrl: user.imageUrl, isDark: widget.isDark),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user.displayName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color:
                      widget.isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              numberFormat.format(count),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color:
                    widget.isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccumulatorHeroCard extends StatelessWidget {
  final GroupAccumulatorDetail detail;
  final bool isDark;

  const _AccumulatorHeroCard({required this.detail, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final numberFormat = NumberFormat.decimalPattern(locale);
    final progressText =
        '${numberFormat.format(detail.totalCount)} / ${numberFormat.format(detail.targetCount)}';

    return GestureDetector(
      onTap: () {
        final presetId = detail.presetAccumulatorId;
        if (presetId.isEmpty) return;
        context.push('/mala', extra: {'presetId': presetId});
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 220,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (detail.image != null && !detail.image!.isEmpty)
                ResponsiveCoverImage(image: detail.image, fit: BoxFit.cover)
              else
                ColoredBox(
                  color:
                      isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.group_accumulator_participants(
                        detail.memberCount,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            detail.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            AppAssets.caretRight,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            progressText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          '${detail.progressPercent}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: detail.progressFraction,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.35),
                        color: AppColors.primary,
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
}

class _LeaderboardTab extends ConsumerStatefulWidget {
  final String accumulatorId;
  final GroupAccumulatorMemberSort sort;
  final bool isDark;
  final ValueChanged<GroupAccumulatorMemberSort> onSortChanged;

  const _LeaderboardTab({
    required this.accumulatorId,
    required this.sort,
    required this.isDark,
    required this.onSortChanged,
  });

  @override
  ConsumerState<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends ConsumerState<_LeaderboardTab> {
  final ScrollController _scrollController = ScrollController();
  bool _hasRequestedInitialLoad = false;

  GroupAccumulatorMembersKey get _membersKey => GroupAccumulatorMembersKey(
    accumulatorId: widget.accumulatorId,
    sortBy: widget.sort,
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _LeaderboardTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sort != widget.sort) {
      _hasRequestedInitialLoad = false;
      _loadInitialIfNeeded(force: true);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialIfNeeded({bool force = false}) {
    if (_hasRequestedInitialLoad && !force) return;
    _hasRequestedInitialLoad = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(groupAccumulatorMembersProvider(_membersKey).notifier)
          .loadInitial(force: force);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(groupAccumulatorMembersProvider(_membersKey).notifier)
          .loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersState = ref.watch(
      groupAccumulatorMembersProvider(_membersKey),
    );
    final secondaryColor =
        widget.isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;
    final locale = Localizations.localeOf(context).toString();
    final numberFormat = NumberFormat.decimalPattern(locale);

    if (membersState.isLoading && membersState.members.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (membersState.error != null && membersState.members.isEmpty) {
      return Center(
        child: ErrorStateWidget(
          error: membersState.error!,
          onRetry:
              () =>
                  ref
                      .read(
                        groupAccumulatorMembersProvider(_membersKey).notifier,
                      )
                      .retry(),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount:
          1 +
          membersState.members.length +
          (membersState.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Text(
                  context.l10n.group_accumulator_recited,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color:
                        widget.isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                _SortToggle(
                  sort: widget.sort,
                  isDark: widget.isDark,
                  onChanged: widget.onSortChanged,
                ),
              ],
            ),
          );
        }

        final memberIndex = index - 1;
        if (memberIndex < membersState.members.length) {
          final member = membersState.members[memberIndex];
          final count =
              widget.sort == GroupAccumulatorMemberSort.today
                  ? member.todayCount
                  : member.totalCount;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${memberIndex + 1}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: secondaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _MemberAvatar(
                  avatarUrl: member.avatarUrl,
                  isDark: widget.isDark,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    member.displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color:
                          widget.isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  numberFormat.format(count),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color:
                        widget.isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
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

class _SortToggle extends StatelessWidget {
  final GroupAccumulatorMemberSort sort;
  final bool isDark;
  final ValueChanged<GroupAccumulatorMemberSort> onChanged;

  const _SortToggle({
    required this.sort,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? AppColors.cardBorderDark : AppColors.grey300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SortToggleChip(
            label: context.l10n.home_today,
            isSelected: sort == GroupAccumulatorMemberSort.today,
            isDark: isDark,
            onTap: () => onChanged(GroupAccumulatorMemberSort.today),
          ),
          _SortToggleChip(
            label: context.l10n.group_accumulator_total,
            isSelected: sort == GroupAccumulatorMemberSort.total,
            isDark: isDark,
            onTap: () => onChanged(GroupAccumulatorMemberSort.total),
          ),
        ],
      ),
    );
  }
}

class _SortToggleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _SortToggleChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? (isDark ? AppColors.surfaceWhite : AppColors.textPrimary)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color:
                isSelected
                    ? (isDark ? AppColors.textPrimary : AppColors.surfaceWhite)
                    : (isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final String? avatarUrl;
  final bool isDark;

  const _MemberAvatar({required this.avatarUrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: 40,
        height: 40,
        child:
            avatarUrl != null && avatarUrl!.isNotEmpty
                ? CachedNetworkImageWidget(
                  imageUrl: avatarUrl!,
                  fit: BoxFit.cover,
                  errorWidget: _placeholder(),
                )
                : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: isDark ? AppColors.surfaceVariantDark : AppColors.grey100,
      child: Icon(
        AppAssets.profile,
        color: isDark ? AppColors.grey500 : AppColors.grey600,
      ),
    );
  }
}
