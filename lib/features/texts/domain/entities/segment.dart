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

  /// Creates a copy with the specified fields replaced with new values
  SegmentEntity copyWith({
    String? id,
    int? segmentNumber,
    String? contentTibetan,
    String? contentSanskrit,
    String? contentEnglish,
    String? contentChinese,
  }) {
    return SegmentEntity(
      id: id ?? this.id,
      segmentNumber: segmentNumber ?? this.segmentNumber,
      contentTibetan: contentTibetan ?? this.contentTibetan,
      contentSanskrit: contentSanskrit ?? this.contentSanskrit,
      contentEnglish: contentEnglish ?? this.contentEnglish,
      contentChinese: contentChinese ?? this.contentChinese,
    );
  }

  @override
  List<Object?> get props => [id, segmentNumber, contentTibetan, contentSanskrit, contentEnglish, contentChinese];
}
