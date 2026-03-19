import 'package:equatable/equatable.dart';

/// Segment entity - a small portion of text.
class SegmentEntity extends Equatable {
  final String id;
  final int segmentNumber;
  final String contentTibetan;
  final String? contentSanskrit;
  final String? contentEnglish;
  final String? contentChinese;

  const SegmentEntity({
    required this.id,
    required this.segmentNumber,
    required this.contentTibetan,
    this.contentSanskrit,
    this.contentEnglish,
    this.contentChinese,
  });

  @override
  List<Object?> get props => [id, segmentNumber, contentTibetan, contentSanskrit, contentEnglish, contentChinese];
}
