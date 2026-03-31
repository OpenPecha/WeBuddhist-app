import 'package:equatable/equatable.dart';

/// Featured content entity for home screen.
class FeaturedContent extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final FeaturedContentType type;
  final String? targetId; // Plan/Text/Recitation ID

  const FeaturedContent({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.type,
    this.targetId,
  });

  @override
  List<Object?> get props => [id, title, description, imageUrl, type, targetId];
}

enum FeaturedContentType { plan, text, recitation, video }
