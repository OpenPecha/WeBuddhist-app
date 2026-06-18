import 'package:flutter_pecha/shared/domain/entities/base_entity.dart';
import 'package:flutter_pecha/features/texts/domain/entities/section.dart';
import 'package:flutter_pecha/features/texts/domain/entities/version.dart';

/// Text entity for Buddhist texts.
class TextEntity extends BaseEntity {
  final String id;
  final String title;
  final String? titleTibetan;
  final String? author;
  final TextType type;
  final List<SectionEntity> sections;
  final List<VersionEntity> versions;

  const TextEntity({
    required this.id,
    required this.title,
    this.titleTibetan,
    this.author,
    required this.type,
    this.sections = const [],
    this.versions = const [],
  });

  String getDisplayTitle(bool preferTibetan) {
    if (preferTibetan && titleTibetan != null && titleTibetan!.isNotEmpty) {
      return titleTibetan!;
    }
    return title;
  }

  @override
  List<Object?> get props => [id, title, titleTibetan, author, type, sections, versions];
}

enum TextType { sutra, commentary, shastra, liturgy, other }
