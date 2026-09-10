import 'package:flutter_pecha/features/group_chat/data/models/chat_message_dto.dart';
import 'package:flutter_pecha/features/group_chat/presentation/utils/chat_sender.dart';

/// How many rows a selection may hold. One place to tune: the snackbar that
/// explains a refused tap reads the number from here too.
///
/// Bounded so a multi-delete stays a short run of sequential calls and a
/// multi-copy stays a sane clipboard.
const int kChatMaxSelection = 10;

/// Which header actions a selection offers.
///
/// A disabled action is hidden rather than greyed, the way the old menu
/// omitted Report and Delete when they did not apply.
class ChatSelectionGates {
  const ChatSelectionGates({
    required this.canReply,
    required this.canCopy,
    required this.showDelete,
    required this.canDelete,
    required this.canReport,
    required this.showPill,
  });

  /// Exactly one message: a reply quotes one original.
  final bool canReply;

  /// Any number: one copies the bare body, several copy a transcript.
  final bool canCopy;

  /// At least one of the viewer's own messages is selected, so the Delete
  /// icon is drawn. Whether it is *enabled* is [canDelete]: a mixed selection
  /// shows it greyed rather than hiding it, so the reason it cannot fire is
  /// visible.
  final bool showDelete;

  /// Every selected message is the viewer's own and still stands. Deletion is
  /// sender-only on the server; the gate is here because the API answers a
  /// non-sender attempt generically.
  final bool canDelete;

  /// Exactly one message, someone else's, and the viewer's identity is known
  /// — until the profile has loaded nothing can be told apart from "mine".
  final bool canReport;

  /// The quick-reaction pill: one message only, gone the moment a second row
  /// joins.
  final bool showPill;
}

/// Works out the gates for [selected] as seen by the signed-in viewer.
///
/// [currentUserId] is the **backend** user id, the same id space as
/// `sender_id`; see [isSelfChatMessage] for why the JWT `sub` must not be
/// passed here.
ChatSelectionGates chatSelectionGates(
  List<ChatMessageDTO> selected, {
  String? currentUserId,
  String? currentUserEmail,
}) {
  final count = selected.length;
  final viewerKnown = isChatViewerKnown(
    currentUserId: currentUserId,
    currentUserEmail: currentUserEmail,
  );
  bool isSelf(ChatMessageDTO message) => isSelfChatMessage(
    senderId: message.senderId,
    senderEmail: message.senderEmail,
    currentUserId: currentUserId,
    currentUserEmail: currentUserEmail,
  );
  final allStanding = selected.every((message) => message.deletedAt == null);
  final anyOwn = viewerKnown && selected.any(isSelf);
  final allOwn = anyOwn && selected.every(isSelf);

  return ChatSelectionGates(
    canReply: count == 1 && allStanding,
    canCopy: count >= 1,
    showDelete: anyOwn && allStanding,
    canDelete: allOwn && allStanding,
    canReport:
        count == 1 && viewerKnown && allStanding && !isSelf(selected.single),
    showPill: count == 1 && allStanding,
  );
}

/// Whether [message] may be part of a selection at all.
///
/// A tombstone offers nothing: no words to copy or quote, nothing left to
/// delete or report.
bool chatMessageIsSelectable(ChatMessageDTO message) =>
    message.deletedAt == null;

/// Whether one more row fits under [kChatMaxSelection].
bool chatSelectionHasRoom(int currentCount) =>
    currentCount < kChatMaxSelection;
