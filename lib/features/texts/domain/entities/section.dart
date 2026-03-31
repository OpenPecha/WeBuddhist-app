import 'package:equatable/equatable.dart';
import 'segment.dart';

/// Section entity - a division of a text.
class SectionEntity extends Equatable {
  final String id;
  final int sectionNumber;
  final String title;
  final String? titleTibetan;
  final List<SegmentEntity> segments;
  final int startPage;
  final int endPage;

  const SectionEntity({
    required this.id,
    required this.sectionNumber,
    required this.title,
    this.titleTibetan,
    this.segments = const [],
    required this.startPage,
    required this.endPage,
  });

  String getDisplayTitle(bool preferTibetan) {
    if (preferTibetan && titleTibetan != null && titleTibetan!.isNotEmpty) {
      return titleTibetan!;
    }
    return title;
  }

  @override
  List<Object?> get props => [id, sectionNumber, title, titleTibetan, segments, startPage, endPage];
}
