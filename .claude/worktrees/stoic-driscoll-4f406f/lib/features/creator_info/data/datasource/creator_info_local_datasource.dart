import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/creator_info/data/models/creator_info_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

final _logger = AppLogger('CreatorInfoLocalDataSource');

/// Local data source for creator info.
class CreatorInfoLocalDataSource {
  static const String boxName = 'creator_info_data';
  static const String _creatorInfoKey = 'creator_info';

  late Box<String> _box;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _box = await Hive.openBox<String>(boxName);
    _isInitialized = true;
    _logger.info('CreatorInfoLocalDataSource initialized');
  }

  /// Ensures initialization is complete before any operation.
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) await initialize();
  }

  /// Get creator info from local storage.
  Future<CreatorInfoModel?> getCreatorInfo() async {
    await _ensureInitialized();

    final json = _box.get(_creatorInfoKey);
    if (json == null) {
      // Return default creator info if none stored
      return _getDefaultCreatorInfo();
    }

    try {
      return CreatorInfoModel.fromJsonString(json);
    } catch (e) {
      _logger.error('Failed to parse creator info data', e);
      return _getDefaultCreatorInfo();
    }
  }

  /// Save creator info to local storage.
  Future<void> saveCreatorInfo(CreatorInfoModel creatorInfo) async {
    await _ensureInitialized();
    await _box.put(_creatorInfoKey, creatorInfo.toJsonString());
    _logger.info('Saved creator info');
  }

  /// Get default creator info.
  CreatorInfoModel _getDefaultCreatorInfo() {
    return const CreatorInfoModel(
      id: 'default_creator',
      credits: [
        CreatorCreditModel(
          language: 'bo',
          name: 'ཡེ་ཤེས་ལྷུན་གྲུབ།',
          bio: 'ཡེ་ཤེས་ལྷུན་གྲུབ་ནི་ནང་པ་ཞིག་ཡིན་པ་དང་། ཁོང་གིས་དབྱིན་ཡིག་ཐོག་ཏུ་བརྩེ་བ་དང་ཤེས་རབ་གཉིས་བསྡོམས་ན་བདེ་བ་ཡིན་ཞེས་པའི་དེབ་ཅིག་བྲིས་ཡོད།',
        ),
        CreatorCreditModel(
          language: 'zh',
          name: '耶喜嘉措（Jay）',
          bio: '希望能把佛法的內容以現代化的方式，傳達給所有對佛法有興趣的人。',
        ),
        CreatorCreditModel(
          language: 'en',
          name: 'Kevin',
          bio: '大家好，我是Kevin, 來自台灣。',
        ),
      ],
      socialMedia: [
        SocialMediaAccountModel(
          account: 'email',
          url: 'kevin@gmail.com',
        ),
        SocialMediaAccountModel(
          account: 'facebook',
          url: 'https://www.facebook.com/profile.php?id=100063506767189',
        ),
        SocialMediaAccountModel(
          account: 'linkedin',
          url: 'https://www.linkedin.com/in/kevin-chen-63506350635063506350/',
        ),
        SocialMediaAccountModel(
          account: 'youtube',
          url: 'https://www.youtube.com/kevin.chen/',
        ),
      ],
      featuredPlans: ['Medicine Buddha Healing'],
    );
  }

  /// Clear all creator info data.
  Future<void> clearAll() async {
    await _ensureInitialized();
    await _box.delete(_creatorInfoKey);
    _logger.info('Cleared all creator info data');
  }
}
