class TraditionChatMessage {
  const TraditionChatMessage({
    required this.role,
    required this.content,
  });

  final String role;
  final String content;

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
  };

  factory TraditionChatMessage.fromJson(Map<String, dynamic> json) {
    return TraditionChatMessage(
      role: json['role'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}

class SuggestedTradition {
  const SuggestedTradition({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;

  factory SuggestedTradition.fromJson(Map<String, dynamic> json) {
    return SuggestedTradition(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class TraditionChatRequest {
  const TraditionChatRequest({
    required this.messages,
    required this.language,
  });

  final List<TraditionChatMessage> messages;
  final String language;

  Map<String, dynamic> toJson() => {
    'messages': messages.map((m) => m.toJson()).toList(),
    'language': language,
  };
}

class TraditionChatResponse {
  const TraditionChatResponse({
    required this.message,
    required this.suggestedTraditions,
    required this.isComplete,
    this.selectedTraditionCode,
  });

  final String message;
  final List<SuggestedTradition> suggestedTraditions;
  final bool isComplete;
  final String? selectedTraditionCode;

  factory TraditionChatResponse.fromJson(Map<String, dynamic> json) {
    final traditions = json['suggested_traditions'];
    return TraditionChatResponse(
      message: json['message'] as String? ?? '',
      suggestedTraditions: traditions is List
          ? traditions
              .whereType<Map<String, dynamic>>()
              .map(SuggestedTradition.fromJson)
              .toList()
          : const [],
      isComplete: json['is_complete'] as bool? ?? false,
      selectedTraditionCode: json['selected_tradition_code'] as String?,
    );
  }
}

class SaveTraditionRequest {
  const SaveTraditionRequest({required this.traditionCode});

  final String traditionCode;

  Map<String, dynamic> toJson() => {
    'tradition_code': traditionCode,
  };
}
