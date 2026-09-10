import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/bookmark_models.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> groupAccumulatorRow({bool withPayload = true}) => {
    'id': 'b-1',
    'type': 'GROUP_ACCUMULATOR',
    'source_id': 'ga-1',
    'created_at': '2026-09-01T08:00:00Z',
    if (withPayload)
      'group_accumulator': {
        'id': 'ga-1',
        'group_id': 'g-1',
        'title': 'Group Mani',
        'image': 'https://img/cover.jpg',
      },
  };

  group('GROUP_ACCUMULATOR bookmarks', () {
    test('creates with the GROUP_ACCUMULATOR wire value', () {
      expect(BookmarkType.groupAccumulator.value, 'GROUP_ACCUMULATOR');
      expect(
        bookmarkTypeFromItem(BookmarkItemType.groupAccumulator),
        BookmarkType.groupAccumulator,
      );
    });

    test('parses the nested group_accumulator payload', () {
      final bookmark = BookmarkDTO.tryFromJson(groupAccumulatorRow());

      expect(bookmark, isNotNull);
      expect(bookmark!.type, BookmarkItemType.groupAccumulator);
      expect(bookmark.sourceId, 'ga-1');
      expect(bookmark.displayTitle, 'Group Mani');
      expect(bookmark.imageUrl, 'https://img/cover.jpg');
      expect(bookmark.groupId, 'g-1');
      expect(bookmark.isOrphaned, isFalse);
      expect(bookmark.isOpenable, isTrue);
      expect(bookmark.isRoundLeading, isFalse);
    });

    test('marks a row without its payload as orphaned and unopenable', () {
      final bookmark = BookmarkDTO.tryFromJson(
        groupAccumulatorRow(withPayload: false),
      );

      expect(bookmark, isNotNull);
      expect(bookmark!.isOrphaned, isTrue);
      expect(bookmark.isOpenable, isFalse);
      expect(bookmark.displayTitle, 'Group accumulation');
    });

    test('lists under its own tab, not the mala tab', () {
      final bookmark = BookmarkDTO.tryFromJson(groupAccumulatorRow())!;

      expect(BookmarkTab.groupAccumulation.matches(bookmark), isTrue);
      expect(BookmarkTab.all.matches(bookmark), isTrue);
      expect(BookmarkTab.mala.matches(bookmark), isFalse);
      expect(BookmarkTab.chants.matches(bookmark), isFalse);
      expect(BookmarkTab.texts.matches(bookmark), isFalse);
    });
  });
}
