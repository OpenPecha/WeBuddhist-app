enum SessionType {
  plan,
  recitation;

  String toJson() => switch (this) {
    SessionType.plan => 'PLAN',
    SessionType.recitation => 'RECITATION',
  };

  static SessionType fromJson(String value) => switch (value) {
    'PLAN' => SessionType.plan,
    'RECITATION' => SessionType.recitation,
    _ => throw FormatException('Unknown SessionType: $value'),
  };
}

// ─── Request models ───

class SessionRequest {
  final SessionType sessionType;
  final String sourceId;
  final int displayOrder;

  const SessionRequest({
    required this.sessionType,
    required this.sourceId,
    required this.displayOrder,
  });

  Map<String, dynamic> toJson() => {
    'session_type': sessionType.toJson(),
    'source_id': sourceId,
    'display_order': displayOrder,
  };
}

class CreateTimeBlockRequest {
  final String time;
  final int timeInt;
  final bool notificationEnabled;
  final List<SessionRequest> sessions;

  const CreateTimeBlockRequest({
    required this.time,
    required this.timeInt,
    this.notificationEnabled = true,
    required this.sessions,
  });

  Map<String, dynamic> toJson() => {
    'time': time,
    'time_int': timeInt,
    'notification_enabled': notificationEnabled,
    'sessions': sessions.map((s) => s.toJson()).toList(),
  };
}

class UpdateTimeBlockRequest {
  final String time;
  final int timeInt;
  final bool notificationEnabled;
  final List<SessionRequest> sessions;

  const UpdateTimeBlockRequest({
    required this.time,
    required this.timeInt,
    this.notificationEnabled = true,
    required this.sessions,
  });

  Map<String, dynamic> toJson() => {
    'time': time,
    'time_int': timeInt,
    'notification_enabled': notificationEnabled,
    'sessions': sessions.map((s) => s.toJson()).toList(),
  };
}

// ─── Response models ───

class SessionDTO {
  final String id;
  final SessionType sessionType;
  final String sourceId;
  final String title;
  final String language;
  final String? imageUrl;
  final int displayOrder;

  const SessionDTO({
    required this.id,
    required this.sessionType,
    required this.sourceId,
    required this.title,
    required this.language,
    this.imageUrl,
    required this.displayOrder,
  });

  factory SessionDTO.fromJson(Map<String, dynamic> json) {
    return SessionDTO(
      id: json['id'] as String,
      sessionType: SessionType.fromJson(json['session_type'] as String),
      sourceId: json['source_id'] as String,
      title: json['title'] as String,
      language: json['language'] as String,
      imageUrl: json['image_url'] as String?,
      displayOrder: json['display_order'] as int,
    );
  }
}

class TimeBlockDTO {
  final String id;
  final String time;
  final int timeInt;
  final bool notificationEnabled;
  final List<SessionDTO> sessions;

  const TimeBlockDTO({
    required this.id,
    required this.time,
    required this.timeInt,
    required this.notificationEnabled,
    required this.sessions,
  });

  factory TimeBlockDTO.fromJson(Map<String, dynamic> json) {
    return TimeBlockDTO(
      id: json['id'] as String,
      time: json['time'] as String,
      timeInt: json['time_int'] as int,
      notificationEnabled: json['notification_enabled'] as bool,
      sessions: (json['sessions'] as List<dynamic>)
          .map((s) => SessionDTO.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RoutineWithTimeBlocksResponse {
  final String id;
  final List<TimeBlockDTO> timeBlocks;

  const RoutineWithTimeBlocksResponse({
    required this.id,
    required this.timeBlocks,
  });

  factory RoutineWithTimeBlocksResponse.fromJson(Map<String, dynamic> json) {
    return RoutineWithTimeBlocksResponse(
      id: json['id'] as String,
      timeBlocks: (json['time_blocks'] as List<dynamic>)
          .map((tb) => TimeBlockDTO.fromJson(tb as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RoutineResponse {
  final String id;
  final List<TimeBlockDTO> timeBlocks;
  final int skip;
  final int limit;
  final int total;

  const RoutineResponse({
    required this.id,
    required this.timeBlocks,
    required this.skip,
    required this.limit,
    required this.total,
  });

  factory RoutineResponse.fromJson(Map<String, dynamic> json) {
    return RoutineResponse(
      id: json['id'] as String,
      timeBlocks: (json['time_blocks'] as List<dynamic>)
          .map((tb) => TimeBlockDTO.fromJson(tb as Map<String, dynamic>))
          .toList(),
      skip: json['skip'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
    );
  }
}

class ErrorResponse {
  final String error;
  final String message;

  const ErrorResponse({required this.error, required this.message});

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      error: json['error'] as String,
      message: json['message'] as String,
    );
  }
}
