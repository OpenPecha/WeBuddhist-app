import 'package:flutter_pecha/features/home/domain/entities/verse_of_day.dart';

class VerseOfDayGroupInfoModel {
  final String id;
  final String title;
  final String subTitle;
  final String description;
  final String language;

  VerseOfDayGroupInfoModel({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.description,
    required this.language,
  });

  factory VerseOfDayGroupInfoModel.fromJson(Map<String, dynamic> json) {
    return VerseOfDayGroupInfoModel(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      subTitle: (json['sub_title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      language: (json['language'] as String?) ?? '',
    );
  }

  VerseOfDayGroupInfo toEntity() {
    return VerseOfDayGroupInfo(
      id: id,
      title: title,
      subTitle: subTitle,
      description: description,
    );
  }
}

class VerseOfDayModel {
  final String id;
  final String verse;
  final String imageUrl;
  final String refId;
  final String refType;
  final String date;
  final List<VerseOfDayGroupInfoModel> groupInfo;

  VerseOfDayModel({
    required this.id,
    required this.verse,
    required this.imageUrl,
    required this.refId,
    required this.refType,
    required this.date,
    this.groupInfo = const [],
  });

  factory VerseOfDayModel.fromJson(Map<String, dynamic> json) {
    final vodJson = json['verse_of_day'] as Map<String, dynamic>? ?? json;
    final groupInfoList = (vodJson['group_info'] as List<dynamic>?)
            ?.map((g) =>
                VerseOfDayGroupInfoModel.fromJson(g as Map<String, dynamic>))
            .toList() ??
        [];

    return VerseOfDayModel(
      id: (vodJson['id'] as String?) ?? '',
      verse: (vodJson['verse'] as String?) ?? '',
      imageUrl: (vodJson['image_url'] as String?) ?? '',
      refId: (vodJson['ref_id'] as String?) ?? '',
      refType: (vodJson['ref_type'] as String?) ?? '',
      date: (vodJson['date'] as String?) ?? '',
      groupInfo: groupInfoList,
    );
  }

  VerseOfDay toEntity() {
    return VerseOfDay(
      id: id,
      verse: verse,
      imageUrl: imageUrl,
      date: date,
      groupInfo: groupInfo.map((g) => g.toEntity()).toList(),
    );
  }
}
