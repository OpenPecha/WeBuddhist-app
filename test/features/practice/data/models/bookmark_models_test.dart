import 'package:flutter_pecha/features/practice/data/datasource/bookmark_remote_datasource.dart';
import 'package:flutter_pecha/features/practice/data/models/bookmark_models.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/bookmark_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookmarkDTO', () {
    test('parses RECITATION_COLLECTION bookmark rows', () {
      final bookmark = BookmarkDTO.tryFromJson({
        'id': 'bookmark-1',
        'type': 'RECITATION_COLLECTION',
        'source_id': 'collection-1',
        'name': 'Daily chants',
        'created_at': '2026-09-09T10:00:00.000Z',
        'updated_at': '2026-09-09T10:05:00.000Z',
        'recitation_collection': {
          'id': 'collection-1',
          'name': 'Morning chants',
          'img_url': 'https://example.com/cover.jpg',
          'item_count': 3,
        },
      });

      expect(bookmark, isNotNull);
      expect(bookmark!.type, BookmarkItemType.recitationCollection);
      expect(bookmark.displayTitle, 'Morning chants');
      expect(bookmark.imageUrl, 'https://example.com/cover.jpg');
      expect(bookmark.itemCount, 3);
      expect(bookmark.isOpenable, isTrue);
    });

    test('falls back to bookmark name for RECITATION_COLLECTION rows', () {
      final bookmark = BookmarkDTO.tryFromJson({
        'id': 'bookmark-1',
        'type': 'RECITATION_COLLECTION',
        'source_id': 'collection-1',
        'name': 'Daily chants',
        'created_at': '2026-09-09T10:00:00.000Z',
      });

      expect(bookmark, isNotNull);
      expect(bookmark!.displayTitle, 'Daily chants');
      expect(bookmark.isOpenable, isTrue);
    });
  });

  group('bookmark mapping', () {
    test('maps RECITATION_COLLECTION rows to the create/check type', () {
      expect(
        bookmarkTypeFromItem(BookmarkItemType.recitationCollection),
        BookmarkType.recitationCollection,
      );
      expect(BookmarkType.recitationCollection.value, 'RECITATION_COLLECTION');
    });

    test('shows personal and group recitation collections in chants tab', () {
      BookmarkDTO bookmark(BookmarkItemType type) => BookmarkDTO(
        id: 'bookmark-$type',
        type: type,
        sourceId: 'source-$type',
        createdAt: DateTime(2026, 9, 9),
        updatedAt: DateTime(2026, 9, 9),
      );

      expect(
        BookmarkTab.chants.matches(
          bookmark(BookmarkItemType.recitationCollection),
        ),
        isTrue,
      );
      expect(
        BookmarkTab.chants.matches(
          bookmark(BookmarkItemType.groupRecitationCollection),
        ),
        isTrue,
      );
      expect(
        BookmarkTab.chants.matches(bookmark(BookmarkItemType.text)),
        isFalse,
      );
    });
  });
}
