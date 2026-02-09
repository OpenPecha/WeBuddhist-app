import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/services/service_providers.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/home/data/providers/tags_provider.dart';
import 'package:flutter_pecha/features/home/presentation/home_screen_constants.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/tag_card.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/tag_search_overlay.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('HomeScreen');

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasRequestedPermissions = false;

  @override
  void initState() {
    super.initState();
    // Request notification permissions when home screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermissionsIfNeeded();
    });
  }

  Future<void> _requestNotificationPermissionsIfNeeded() async {
    if (_hasRequestedPermissions) return;
    _hasRequestedPermissions = true;

    final notificationService = ref.read(notificationServiceProvider);
    if (notificationService == null) {
      _log.warning(
        'NotificationService not initialized, skipping permission request',
      );
      return;
    }

    try {
      // Check if permissions are already granted
      final alreadyEnabled =
          await notificationService.areNotificationsEnabled();
      if (!alreadyEnabled) {
        _log.info('Requesting notification permissions...');
        final granted = await notificationService.requestPermission();
        if (granted) {
          _log.info('Notification permissions granted');
        } else {
          _log.info('Notification permissions denied');
        }
      }
    } catch (e) {
      _log.warning('Error requesting notification permissions: $e');
    }
  }

  /// Manual refetch/retry method that can be called from UI
  void _refetchTags() {
    // Refresh the provider to immediately fetch fresh data
    // ignore: unused_result
    ref.refresh(tagsFutureProvider);
  }

  void _navigateToPlans(String tag) {
    context.push('/home/plans/$tag');
  }

  void _openSearchOverlay(List<String> tags) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Search',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: TagSearchOverlay(
            allTags: tags,
            onTagSelected: (tag) {
              _log.info('Tag selected from search: $tag');
              _navigateToPlans(tag);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final tagsAsync = ref.watch(tagsFutureProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(localizations),
            _buildSearchSection(localizations, tagsAsync),
            _buildBody(context, localizations),
          ],
        ),
      ),
    );
  }

  // Build the top bar
  Widget _buildTopBar(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: HomeScreenConstants.topBarHorizontalPadding,
        vertical: HomeScreenConstants.topBarVerticalPadding,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          localizations.nav_home,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: HomeScreenConstants.titleFontSize,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection(
    AppLocalizations localizations,
    AsyncValue<List<String>> tagsAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: GestureDetector(
        onTap: () {
          tagsAsync.whenData((tags) {
            _openSearchOverlay(tags);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Text(
                localizations.text_search,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations localizations) {
    final tagsAsync = ref.watch(tagsFutureProvider);
    final language = ref.watch(localeProvider).languageCode;
    final fontSize = language == 'bo' ? 22.0 : 18.0;

    return Expanded(
      child: tagsAsync.when(
        data: (tags) {
          if (tags.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(
                  HomeScreenConstants.emptyStatePadding,
                ),
                child: Text(
                  localizations.no_feature_content,
                  style: TextStyle(fontSize: fontSize),
                ),
              ),
            );
          }

          // 2-column grid layout, only the grid is scrollable
          return GridView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: HomeScreenConstants.bodyHorizontalPadding,
              vertical: HomeScreenConstants.bodyVerticalPadding,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.4,
            ),
            itemCount: tags.length,
            itemBuilder: (context, index) {
              final tag = tags[index];
              return TagCard(
                tag: tag,
                onTap: () {
                  _log.info('Tag tapped: $tag');
                  _navigateToPlans(tag);
                },
              );
            },
          );
        },
        loading:
            () => const Center(
              child: Padding(
                padding: EdgeInsets.all(HomeScreenConstants.emptyStatePadding),
                child: CircularProgressIndicator(),
              ),
            ),
        error:
            (error, stackTrace) =>
                ErrorStateWidget(error: error, onRetry: _refetchTags),
      ),
    );
  }
}
