import 'dart:convert';

import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/story_view/data/models/story_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

final _logger = AppLogger('StoryLocalDataSource');

/// Local data source for story data.
class StoryLocalDataSource {
  static const String boxName = 'story_data';
  static const String _viewedStoriesKey = 'viewed_stories';
  static const String _cachedStoriesKey = 'cached_stories';

  late Box<String> _box;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _box = await Hive.openBox<String>(boxName);
    _isInitialized = true;
    _logger.info('StoryLocalDataSource initialized');
  }

  /// Ensures initialization is complete before any operation.
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) await initialize();
  }

  /// Get viewed story IDs from local storage.
  Future<List<String>> getViewedStoryIds() async {
    await _ensureInitialized();

    final json = _box.get(_viewedStoriesKey);
    if (json == null) return [];

    try {
      final List<dynamic> list = jsonDecode(json);
      return list.cast<String>();
    } catch (e) {
      _logger.error('Failed to parse viewed story IDs', e);
      return [];
    }
  }

  /// Save viewed story IDs to local storage.
  Future<void> saveViewedStoryIds(List<String> storyIds) async {
    await _ensureInitialized();
    await _box.put(_viewedStoriesKey, jsonEncode(storyIds));
    _logger.info('Saved ${storyIds.length} viewed story IDs');
  }

  /// Add viewed story ID.
  Future<void> markAsViewed(String storyId) async {
    final viewedIds = await getViewedStoryIds();
    if (!viewedIds.contains(storyId)) {
      viewedIds.add(storyId);
      await saveViewedStoryIds(viewedIds);
    }
  }

  /// Get cached stories from local storage.
  Future<List<StoryModel>> getCachedStories() async {
    await _ensureInitialized();

    final json = _box.get(_cachedStoriesKey);
    if (json == null) return [];

    try {
      final List<dynamic> list = jsonDecode(json);
      return list
          .map((story) => StoryModel.fromJson(story as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.error('Failed to parse cached stories', e);
      return [];
    }
  }

  /// Save stories to local cache.
  Future<void> cacheStories(List<StoryModel> stories) async {
    await _ensureInitialized();
    await _box.put(
      _cachedStoriesKey,
      jsonEncode(stories.map((s) => s.toJson()).toList()),
    );
    _logger.info('Cached ${stories.length} stories');
  }

  /// Clear all story data.
  Future<void> clearAll() async {
    await _ensureInitialized();
    await _box.delete(_viewedStoriesKey);
    await _box.delete(_cachedStoriesKey);
    _logger.info('Cleared all story data');
  }
}
