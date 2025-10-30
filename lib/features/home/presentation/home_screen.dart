// This file contains the presentation layer for the home screen feature.
// It handles the UI for the main home screen after splash.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/auth/application/auth_provider.dart';
import 'package:flutter_pecha/features/home/data/week_plan.dart';
import 'package:flutter_pecha/features/home/models/plan_item.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/action_of_the_day_card.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/calendar_banner_card.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_card.dart';
import 'package:flutter_pecha/features/notifications/presentation/notification_settings_screen.dart';
import 'package:flutter_pecha/features/texts/data/providers/selected_segment_provider.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/action_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  late List<PlanItem> planItems;
  Timer? _dayCheckTimer;
  String _currentDay = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeTodayPlan();
    _startDayCheckTimer();
  }

  void _startDayCheckTimer() {
    _dayCheckTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _checkAndUpdateDay();
    });
  }

  void _checkAndUpdateDay() {
    final today = DateTime.now();
    final dayName = DateFormat('EEEE').format(today).toLowerCase();
    if (dayName != _currentDay) {
      _currentDay = dayName;
      _updatePlanForNewDay();
    }
  }

  void _updatePlanForNewDay() {
    final weekPlan = ref.read(weekPlanProvider);
    final plan = weekPlan[_currentDay];
    setState(() {
      planItems =
          (plan["plan"] as List<dynamic>)
              .map((item) => PlanItem.fromJson(item))
              .toList();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndUpdateDay();
    }
  }

  @override
  void dispose() {
    _dayCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _initializeTodayPlan() {
    final today = DateTime.now();
    final dayName = DateFormat('EEEE').format(today).toLowerCase();
    _currentDay = dayName;

    // Get the localized week plan
    final weekPlan = ref.read(weekPlanProvider);
    final plan = weekPlan[_currentDay];
    planItems =
        (plan["plan"] as List<dynamic>)
            .map((item) => PlanItem.fromJson(item))
            .toList();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final authState = ref.watch(authProvider);
    final bottomBarVisible = ref.watch(bottomBarVisibleProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(authState, localizations),
                _buildBody(context, localizations),
              ],
            ),
            if (bottomBarVisible) _buildBottomBar(context, localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, AppLocalizations localizations) {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        constraints: const BoxConstraints(minHeight: 60),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ActionButton(
              icon: Icons.library_books,
              label: 'Library',
              onTap: () {
                // context.push('/library');
                ref.read(bottomBarVisibleProvider.notifier).state =
                    !ref.read(bottomBarVisibleProvider.notifier).state;
                context.push('/texts');
              },
            ),
            ActionButton(
              icon: Icons.info_outline,
              label: 'Creator Info',
              onTap: () {
                ref.read(bottomBarVisibleProvider.notifier).state =
                    !ref.read(bottomBarVisibleProvider.notifier).state;
                context.push('/creator_info');
              },
            ),
          ],
        ),
      ),
    );
  }

  // Build the top bar
  Widget _buildTopBar(AuthState authState, AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            localizations.home_today,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          Row(
            children: [
              IconButton(
                onPressed:
                    () => context.push(NotificationSettingsScreen.routeName),
                icon: Icon(Icons.notifications_none, size: 28),
              ),
              SizedBox(width: 16),
              if (authState.isGuest)
                GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: Hero(
                    tag: 'profile-avatar',
                    child: Icon(Icons.account_circle, size: 32),
                  ),
                ),
              if (authState.isLoggedIn && !authState.isGuest)
                GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: Hero(
                    tag: 'profile-avatar',
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage:
                          (authState.userProfile?.pictureUrl?.toString() ?? '')
                                  .isNotEmpty
                              ? NetworkImage(
                                authState.userProfile!.pictureUrl!.toString(),
                              )
                              : null,
                      child:
                          ((authState.userProfile?.pictureUrl?.toString() ?? '')
                                  .isEmpty)
                              ? const Icon(Icons.person, color: Colors.black54)
                              : null,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Build the scrollable body
  Widget _buildBody(BuildContext context, AppLocalizations localizations) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Banner
            CalendarBannerCard(
              title: 'Saka Dawa',
              subtitle: 'Full Moon',
              description:
                  'Celebrated in the fourth month of the Tibetan calendar',
              celebratedBy: 'ALL SCHOOL',
              imageUrl: 'https://picsum.photos/200/300',
            ),
            const SizedBox(height: 16),
            // Plan Items
            ...planItems.asMap().entries.map((entry) {
              final index = entry.key;
              final planItem = entry.value;
              switch (index) {
                case 0:
                  return Column(
                    children: [
                      VerseCard(
                        verse: planItem.content,
                        author: planItem.author,
                        imageUrl: planItem.imageUrl,
                        title: planItem.label,
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                case 1:
                  return Column(
                    children: [
                      ActionOfTheDayCard(
                        heading: "Guided Scripture",
                        title: planItem.label,
                        subtitle: "1-2 min",
                        iconWidget: _getVideoThumbnail(planItem.content),
                        onTap:
                            () => context.push(
                              '/home/video_player',
                              extra: {
                                'videoUrl': planItem.content,
                                'title': planItem.label,
                              },
                            ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                case 2:
                  return Column(
                    children: [
                      ActionOfTheDayCard(
                        heading: "Guided Meditation",
                        title:
                            planItem.label == "Meditation"
                                ? localizations.home_meditationTitle
                                : localizations.home_recitation,
                        subtitle: "1-2 min",
                        iconWidget: _getAudioThumbnail(planItem.label),
                        onTap:
                            () => context.push(
                              '/home/meditation_video',
                              extra: planItem.content,
                            ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                default:
                  return const SizedBox.shrink();
              }
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _getVideoThumbnail(String videoUrl) {
    // Extract YouTube video ID and create thumbnail
    final uri = Uri.parse(videoUrl);
    String? videoId;

    if (uri.host.contains('youtube.com')) {
      videoId = uri.queryParameters['v'];
    } else if (uri.host.contains('youtu.be')) {
      videoId = uri.pathSegments.firstOrNull;
    }

    if (videoId != null) {
      return Image.network(
        'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(
              Icons.video_library,
              size: 48,
              color: Colors.grey,
            ),
          );
        },
      );
    }

    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.video_library, size: 48, color: Colors.grey),
    );
  }

  Widget _getAudioThumbnail(String label) {
    if (label == "Meditation") {
      return Image.asset(
        'assets/images/meditation.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(
              Icons.self_improvement,
              size: 48,
              color: Colors.grey,
            ),
          );
        },
      );
    }
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.audiotrack, size: 48, color: Colors.grey),
    );
  }
}
