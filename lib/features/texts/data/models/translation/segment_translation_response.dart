import 'package:flutter_pecha/features/texts/data/models/commentary/parent_segment.dart';
import 'package:flutter_pecha/features/texts/data/models/translation/segment_translation.dart';

class SegmentTranslationResponse {
  final ParentSegment parentSegment;
  final List<SegmentTranslation> translations;

  SegmentTranslationResponse({
    required this.parentSegment,
    required this.translations,
  });

  factory SegmentTranslationResponse.fromJson(Map<String, dynamic> json) {
    return SegmentTranslationResponse(
      parentSegment: ParentSegment.fromJson(json['parent_segment']),  
      translations: json['translations'].map((e) => SegmentTranslation.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parent_segment': parentSegment.toJson(),
      'translations': translations.map((e) => e.toJson()).toList(),
    };
  }
}
