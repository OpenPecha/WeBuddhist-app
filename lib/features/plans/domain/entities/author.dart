import 'package:equatable/equatable.dart';

/// Author entity for plan authors.
class Author extends Equatable {
  final String id;
  final String name;
  final String? tibetanName;
  final String? biography;
  final String? imageUrl;
  final List<SocialProfile> socialProfiles;

  const Author({
    required this.id,
    required this.name,
    this.tibetanName,
    this.biography,
    this.imageUrl,
    this.socialProfiles = const [],
  });

  /// Get display name based on language preference.
  String getDisplayName(bool preferTibetan) {
    if (preferTibetan && tibetanName != null && tibetanName!.isNotEmpty) {
      return tibetanName!;
    }
    return name;
  }

  @override
  List<Object?> get props => [id, name, tibetanName, biography, imageUrl, socialProfiles];
}

/// Social profile for an author.
class SocialProfile extends Equatable {
  final String platform;
  final String url;
  final String? handle;

  const SocialProfile({
    required this.platform,
    required this.url,
    this.handle,
  });

  @override
  List<Object?> get props => [platform, url, handle];
}
