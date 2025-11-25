import 'dart:math';
import 'package:flutter_pecha/core/services/background_image/background_image_constants.dart';

/// Service to manage background image selection for verses and text content
///
/// This singleton service provides consistent background image selection
/// across the app, ensuring the same content always gets the same background.
class BackgroundImageService {
  static final BackgroundImageService _instance =
      BackgroundImageService._internal();
  factory BackgroundImageService() => _instance;
  BackgroundImageService._internal();

  final Random _random = Random();
  int _currentIndex = 0;
  bool _isRandom = true;

  /// Get a random background image from the list
  String getRandomImage() {
    final images = BackgroundImageConstants.verseBackgroundImages;
    if (images.isEmpty) {
      throw StateError('No background images available');
    }
    _currentIndex = _random.nextInt(images.length);
    return images[_currentIndex];
  }

  /// Get the next background image in sequence (loop through)
  String getNextImage() {
    final images = BackgroundImageConstants.verseBackgroundImages;
    if (images.isEmpty) {
      throw StateError('No background images available');
    }
    _currentIndex = (_currentIndex + 1) % images.length;
    return images[_currentIndex];
  }

  /// Get a background image based on current mode (random or sequential)
  String getImage() {
    return _isRandom ? getRandomImage() : getNextImage();
  }

  /// Set the selection mode
  void setRandomMode(bool isRandom) {
    _isRandom = isRandom;
  }

  /// Reset to first image
  void reset() {
    _currentIndex = 0;
  }

  /// Get image by index (useful for consistent selection based on ID)
  String getImageByIndex(int index) {
    final images = BackgroundImageConstants.verseBackgroundImages;
    if (images.isEmpty) {
      throw StateError('No background images available');
    }
    return images[index % images.length];
  }

  /// Get image based on content hash (consistent for same content)
  ///
  /// This method ensures that the same content (verse, text) always receives
  /// the same background image, providing visual consistency across the app.
  ///
  /// Example:
  /// ```dart
  /// final bgImage = BackgroundImageService().getImageForContent(verseText);
  /// ```
  String getImageForContent(String content) {
    final images = BackgroundImageConstants.verseBackgroundImages;
    if (images.isEmpty) {
      throw StateError('No background images available');
    }
    // Use hash code to get consistent image for same content
    final index = content.hashCode.abs() % images.length;
    return images[index];
  }
}
