import 'package:flutter_pecha/features/ai/domain/entities/chat_message.dart';
import 'package:flutter_pecha/shared/domain/entities/base_entity.dart';

/// Chat thread entity representing a conversation.
class ChatThread extends BaseEntity {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;

  const ChatThread({
    required this.id,
    required this.title,
    this.messages = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
  });

  /// Get the last message in the thread.
  ChatMessage? get lastMessage {
    if (messages.isEmpty) return null;
    return messages.last;
  }

  /// Get a preview of the last message (for UI display).
  String get lastMessagePreview {
    final last = lastMessage;
    if (last == null) return 'New conversation';
    final content = last.content;
    return content.length > 50 ? '${content.substring(0, 50)}...' : content;
  }

  @override
  List<Object?> get props => [id, title, messages, createdAt, updatedAt, isPinned];
}
