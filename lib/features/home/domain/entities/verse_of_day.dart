import 'package:equatable/equatable.dart';

class VerseOfDayGroupInfo extends Equatable {
  final String id;
  final String title;
  final String subTitle;
  final String description;

  const VerseOfDayGroupInfo({
    required this.id,
    required this.title,
    required this.subTitle,
    required this.description,
  });

  @override
  List<Object?> get props => [id, title, subTitle, description];
}

class VerseOfDay extends Equatable {
  final String id;
  final String verse;
  final String imageUrl;
  final String date;
  final List<VerseOfDayGroupInfo> groupInfo;

  const VerseOfDay({
    required this.id,
    required this.verse,
    required this.imageUrl,
    required this.date,
    this.groupInfo = const [],
  });

  String? get groupTitle => groupInfo.isNotEmpty ? groupInfo.first.title : null;

  @override
  List<Object?> get props => [id, verse, imageUrl, date, groupInfo];
}
