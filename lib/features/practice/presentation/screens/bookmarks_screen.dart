import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/practice/data/models/bookmark_models.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/bookmark_card.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/timer/domain/entities/preset_timer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabLabels = ['All', 'Plans', 'Mala', 'Timers', 'Texts'];
  static const _tabs = [
    BookmarkTab.all,
    BookmarkTab.plans,
    BookmarkTab.mala,
    BookmarkTab.timers,
    BookmarkTab.texts,
  ];

  static const _emptyMessages = [
    ('Nothing bookmarked yet.', 'Bookmark anything to save it here.'),
    ('No plans bookmarked yet.', 'Bookmark a plan to save it here.'),
    ('No malas bookmarked yet.', 'Bookmark a mala to save it here.'),
    ('No timers bookmarked yet.', 'Bookmark a timer to save it here.'),
    ('No texts bookmarked yet.', 'Bookmark a text to save it here.'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onRemove(BookmarkDTO bookmark) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(bookmarksProvider.notifier).remove(bookmark);
    if (!mounted) return;
    if (ok) {
      final type = bookmarkTypeFromItem(bookmark.type);
      if (type != null) {
        ref.invalidate(
          bookmarkExistsProvider(
            BookmarkTarget(type: type, sourceId: bookmark.sourceId),
          ),
        );
      }
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'Bookmark removed' : 'Failed to remove bookmark'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onTap(BookmarkDTO bookmark) {
    switch (bookmark.type) {
      case BookmarkItemType.text:
      case BookmarkItemType.verse:
        final textId = bookmark.textId ?? bookmark.sourceId;
        context.push(
          '/reader/$textId',
          extra: NavigationContext(source: NavigationSource.normal),
        );
      case BookmarkItemType.series:
        context.pushNamed(
          'home-series-detail',
          pathParameters: {'id': bookmark.sourceId},
        );
      case BookmarkItemType.timer:
        // Open the active timer directly. This route is root-navigator-keyed,
        // so it won't duplicate the /home shell page (which crashes when a
        // shell route like the timers list is pushed from this root screen).
        final durationMs = bookmark.timerDurationMs;
        if (durationMs == null || durationMs <= 0) return;
        context.push(
          '/home/timers/active',
          extra: PresetTimer(
            id: bookmark.sourceId,
            name: bookmark.displayTitle,
            durationMs: durationMs,
          ),
        );
      case BookmarkItemType.accumulator:
        context.push('/mala', extra: {'presetId': bookmark.sourceId});
      case BookmarkItemType.plan:
        // No reliable id-based deep link for a plan from bookmark data alone.
        break;
    }
  }

  bool _isTappable(BookmarkItemType type) => type != BookmarkItemType.plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(bookmarksProvider);

    return Scaffold(
      backgroundColor:
          isDark
              ? AppColors.scaffoldBackgroundDark
              : AppColors.scaffoldBackgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark
                ? AppColors.scaffoldBackgroundDark
                : AppColors.scaffoldBackgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.l10n.bookmarks,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildTabBar(isDark),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(
          _tabs.length,
          (i) => _BookmarkTabView(
            state: state,
            tab: _tabs[i],
            emptyMessage: _emptyMessages[i],
            isDark: isDark,
            onRefresh: () => ref.read(bookmarksProvider.notifier).refresh(),
            onRetry: () => ref.read(bookmarksProvider.notifier).load(),
            onRemove: _onRemove,
            onTap: _onTap,
            isTappable: _isTappable,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    final indicatorColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(width: 2, color: indicatorColor),
        insets: const EdgeInsets.symmetric(horizontal: 4),
      ),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
      labelColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      unselectedLabelColor:
          isDark ? AppColors.textSubtleDark : AppColors.grey500,
      labelStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      dividerColor: isDark ? AppColors.cardBorderDark : AppColors.grey300,
      tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
    );
  }
}

/// Renders one tab: loading / error / empty / grouped list states.
class _BookmarkTabView extends StatelessWidget {
  const _BookmarkTabView({
    required this.state,
    required this.tab,
    required this.emptyMessage,
    required this.isDark,
    required this.onRefresh,
    required this.onRetry,
    required this.onRemove,
    required this.onTap,
    required this.isTappable,
  });

  final BookmarksState state;
  final BookmarkTab tab;
  final (String, String) emptyMessage;
  final bool isDark;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final void Function(BookmarkDTO) onRemove;
  final void Function(BookmarkDTO) onTap;
  final bool Function(BookmarkItemType) isTappable;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.bookmarks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.bookmarks.isEmpty) {
      return _BookmarkErrorState(message: state.error!, onRetry: onRetry);
    }

    final items = state.forTab(tab);
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: LayoutBuilder(
          builder:
              (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: _BookmarkEmptyState(
                    firstLine: emptyMessage.$1,
                    secondLine: emptyMessage.$2,
                  ),
                ),
              ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: _buildGroupedChildren(items),
      ),
    );
  }

  List<Widget> _buildGroupedChildren(List<BookmarkDTO> items) {
    final children = <Widget>[];
    String? lastHeader;
    for (final bookmark in items) {
      final header = _sectionLabel(bookmark.createdAt);
      if (header != lastHeader) {
        children.add(
          _SectionHeader(label: header, isDark: isDark, isFirst: lastHeader == null),
        );
        lastHeader = header;
      }
      children.add(
        BookmarkCard(
          bookmark: bookmark,
          onRemove: () => onRemove(bookmark),
          onTap: isTappable(bookmark.type) ? () => onTap(bookmark) : null,
        ),
      );
    }
    return children;
  }

  static String _sectionLabel(DateTime created) {
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(created);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (today.year == created.year) return DateFormat('MMM d').format(created);
    return DateFormat('MMM d, y').format(created);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.isDark,
    required this.isFirst,
  });

  final String label;
  final bool isDark;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: isFirst ? 0 : 12, bottom: 12),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _BookmarkErrorState extends StatelessWidget {
  const _BookmarkErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textSubtleDark : AppColors.grey600;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: textColor, height: 1.5),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _BookmarkEmptyState extends StatelessWidget {
  const _BookmarkEmptyState({
    required this.firstLine,
    required this.secondLine,
  });

  final String firstLine;
  final String secondLine;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textSubtleDark : AppColors.grey600;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              firstLine,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: textColor, height: 1.5),
            ),
            Text(
              secondLine,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: textColor, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
