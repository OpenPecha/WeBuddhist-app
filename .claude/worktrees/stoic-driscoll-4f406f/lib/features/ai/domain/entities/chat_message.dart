import 'package:flutter_pecha/shared/domain/entities/base_entity.dart';

/// Chat message entity for AI conversations.
class ChatMessage extends BaseEntity {
  final String id;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final String? sourceText; // For context messages
  final List<String>? sources; // Source references

  const ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.createdAt,
    this.sourceText,
    this.sources,
  });

  @override
  List<Object?> get props => [id, content, type, createdAt, sourceText, sources];
}

/// Type of message (user or AI).
enum MessageType {
  user,
  assistant,
  system,
}
