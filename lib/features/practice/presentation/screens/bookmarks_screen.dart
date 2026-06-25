import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabLabels = [
    'All',
    'Plans',
    'Accumulations',
    'Timers',
    'Texts',
  ];

  static const _emptyMessages = [
    ('Nothing bookmarked yet.', 'Bookmark anything to save it here.'),
    ('No plans bookmarked yet.', 'Bookmark a plan to save it here.'),
    (
      'No accumulations bookmarked yet.',
      'Bookmark an accumulation to save it here.',
    ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          _tabLabels.length,
          (i) => _BookmarkEmptyState(
            firstLine: _emptyMessages[i].$1,
            secondLine: _emptyMessages[i].$2,
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
