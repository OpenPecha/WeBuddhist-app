import 'package:flutter_pecha/shared/domain/entities/value_object.dart';

/// Multi-resolution image URLs from the API (`thumbnail`, `medium`, `original`).
///
/// Pick the URL closest to the on-screen size to balance quality and bandwidth.
class ResponsiveImage extends ValueObject {
  /// Physical pixel ceiling for thumbnail tier (~list tiles, small avatars).
  static const int thumbnailMaxPhysicalPx = 400;

  /// Physical pixel ceiling for medium tier (~cards, 16:9 covers on phones).
  static const int mediumMaxPhysicalPx = 1200;

  final String? thumbnail;
  final String? medium;
  final String? original;

  const ResponsiveImage({this.thumbnail, this.medium, this.original});

  /// Legacy / single-URL payloads where every tier is the same address.
  const ResponsiveImage.uniform(String url)
    : thumbnail = url,
      medium = url,
      original = url;

  bool get isEmpty =>
      (thumbnail == null || thumbnail!.isEmpty) &&
      (medium == null || medium!.isEmpty) &&
      (original == null || original!.isEmpty);

  /// Smallest available URL — notifications, placeholders, non-UI fallbacks.
  String? get displayUrl => thumbnail ?? medium ?? original;

  /// Largest layout dimension in physical pixels for [width]/[height] (logical).
  static int maxPhysicalPixels({
    double? width,
    double? height,
    required double devicePixelRatio,
  }) {
    final int wPx =
        width != null && width.isFinite && width > 0
            ? (width * devicePixelRatio).round()
            : 0;
    final int hPx =
        height != null && height.isFinite && height > 0
            ? (height * devicePixelRatio).round()
            : 0;
    if (wPx == 0) return hPx;
    if (hPx == 0) return wPx;
    return wPx > hPx ? wPx : hPx;
  }

  /// URL best matched to on-screen size using [devicePixelRatio].
  String? urlForLayout({
    double? width,
    double? height,
    required double devicePixelRatio,
  }) {
    return urlForMaxPhysicalPixels(
      maxPhysicalPixels(
        width: width,
        height: height,
        devicePixelRatio: devicePixelRatio,
      ),
    );
  }

  /// URL best matched to a known physical pixel budget.
  String? urlForMaxPhysicalPixels(int maxPhysicalPixels) {
    if (isEmpty) return null;
    if (maxPhysicalPixels <= 0) return displayUrl;

    if (maxPhysicalPixels <= thumbnailMaxPhysicalPx) {
      return thumbnail ?? medium ?? original;
    }
    if (maxPhysicalPixels <= mediumMaxPhysicalPx) {
      return medium ?? original ?? thumbnail;
    }
    return original ?? medium ?? thumbnail;
  }

  factory ResponsiveImage.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ResponsiveImage();
    return ResponsiveImage(
      thumbnail: json['thumbnail'] as String?,
      medium: json['medium'] as String?,
      original: json['original'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'thumbnail': thumbnail,
    'medium': medium,
    'original': original,
  };

  @override
  List<Object?> get props => [thumbnail, medium, original];
}
