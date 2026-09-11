import 'package:flutter_pecha/features/group_profile/presentation/utils/group_event_live_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupEventLiveUtils.initialLanguage', () {
    test('keeps a supported content language', () {
      expect(GroupEventLiveUtils.initialLanguage('bo'), 'bo');
      expect(GroupEventLiveUtils.initialLanguage('zh'), 'zh');
      expect(GroupEventLiveUtils.initialLanguage(' EN '), 'en');
    });

    test('falls back to English for unsupported languages', () {
      expect(GroupEventLiveUtils.initialLanguage('hi'), 'en');
      expect(GroupEventLiveUtils.initialLanguage(''), 'en');
    });
  });

  group('GroupEventLiveUtils.isLiveLabel', () {
    test('detects live in the label', () {
      expect(GroupEventLiveUtils.isLiveLabel('live'), isTrue);
      expect(GroupEventLiveUtils.isLiveLabel('Tibetan LIVE'), isTrue);
    });

    test('is false for other labels', () {
      expect(GroupEventLiveUtils.isLiveLabel('recording'), isFalse);
      expect(GroupEventLiveUtils.isLiveLabel(null), isFalse);
    });
  });
}
