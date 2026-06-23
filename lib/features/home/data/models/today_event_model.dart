import 'package:flutter_pecha/features/home/domain/entities/today_event.dart';

class TodayEventMetadataModel {
  final String id;
  final String name;
  final String? description;
  final String language;

  TodayEventMetadataModel({
    required this.id,
    required this.name,
    this.description,
    required this.language,
  });

  factory TodayEventMetadataModel.fromJson(Map<String, dynamic> json) {
    return TodayEventMetadataModel(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      language: (json['language'] as String?) ?? '',
    );
  }
}

class TodayEventModel {
  final String id;
  final TodayEventMetadataModel metadata;

  TodayEventModel({required this.id, required this.metadata});

  factory TodayEventModel.fromJson(Map<String, dynamic> json) {
    return TodayEventModel(
      id: (json['id'] as String?) ?? '',
      metadata: TodayEventMetadataModel.fromJson(
        json['metadata'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  TodayEvent toEntity() {
    return TodayEvent(
      id: id,
      name: metadata.name,
      description: metadata.description,
    );
  }
}

class TodayEventsResponseModel {
  final List<TodayEventModel> events;

  TodayEventsResponseModel({required this.events});

  factory TodayEventsResponseModel.fromJson(Map<String, dynamic> json) {
    final eventsJson = json['events'] as List<dynamic>? ?? const [];
    return TodayEventsResponseModel(
      events:
          eventsJson
              .map(
                (event) =>
                    TodayEventModel.fromJson(event as Map<String, dynamic>),
              )
              .toList(),
    );
  }

  List<TodayEvent> toEntities() => events.map((event) => event.toEntity()).toList();
}
