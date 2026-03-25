import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/story_view/data/models/story_model.dart';
import 'package:flutter_pecha/features/story_view/domain/entities/story.dart';
import 'package:http/http.dart' as http;

final _logger = AppLogger('StoryRemoteDataSource');

/// Remote data source for story data.
class StoryRemoteDataSource {
  final http.Client _client;

  StoryRemoteDataSource({required http.Client client}) : _client = client;

  /// Get all active stories from the API.
  Future<List<StoryModel>> getStories() async {
    try {
      // TODO: Implement actual API call
      // For now, return default stories
      _logger.info('Fetching stories from API');
      return _getDefaultStories();
    } catch (e) {
      _logger.error('Failed to fetch stories from API', e);
      rethrow;
    }
  }

  /// Get stories by type from the API.
  Future<List<StoryModel>> getStoriesByType(String type) async {
    try {
      // TODO: Implement actual API call
      _logger.info('Fetching stories by type: $type');
      final allStories = await getStories();
      return allStories.where((story) => story.type.name == type).toList();
    } catch (e) {
      _logger.error('Failed to fetch stories by type', e);
      rethrow;
    }
  }

  /// Get default stories for fallback.
  List<StoryModel> _getDefaultStories() {
    final now = DateTime.now();
    return [
      StoryModel(
        id: 'story_1',
        title: 'Daily Practice',
        description: 'Start your day with mindfulness',
        imageUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800',
        type: StoryType.plan,
        createdAt: now,
      ),
      StoryModel(
        id: 'story_2',
        title: 'New Content',
        description: 'Check out our latest content',
        imageUrl: 'https://images.unsplash.com/photo-1545389336-cf090694435e?w=800',
        type: StoryType.promotion,
        createdAt: now,
      ),
    ];
  }
}
