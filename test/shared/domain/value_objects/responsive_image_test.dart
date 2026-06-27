import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const image = ResponsiveImage(
    thumbnail: 'thumb.webp',
    medium: 'medium.webp',
    original: 'original.webp',
  );

  group('ResponsiveImage.urlForMaxPhysicalPixels', () {
    test('uses thumbnail for small targets', () {
      expect(image.urlForMaxPhysicalPixels(200), 'thumb.webp');
    });

    test('uses medium for mid-size targets', () {
      expect(image.urlForMaxPhysicalPixels(800), 'medium.webp');
    });

    test('uses original for large targets', () {
      expect(image.urlForMaxPhysicalPixels(2000), 'original.webp');
    });

    test('falls back when a tier is missing', () {
      const partial = ResponsiveImage(thumbnail: 'thumb.webp');
      expect(partial.urlForMaxPhysicalPixels(2000), 'thumb.webp');
    });
  });

  group('ResponsiveImage.urlForLayout', () {
    test('scales logical size by device pixel ratio', () {
      expect(image.urlForLayout(width: 100, devicePixelRatio: 2), 'thumb.webp');
      expect(
        image.urlForLayout(width: 300, devicePixelRatio: 3),
        'medium.webp',
      );
    });
  });
}
