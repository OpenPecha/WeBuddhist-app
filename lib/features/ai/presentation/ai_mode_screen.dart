import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/utils/error_message_mapper.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/ai/presentation/controllers/chat_controller.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/chat_header.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/chat_history_drawer.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/message_list.dart';
import 'package:flutter_pecha/features/ai/validators/message_validator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/login_drawer.dart';

class AiModeScreen extends ConsumerStatefulWidget {
  const AiModeScreen({super.key});

  @override
  ConsumerState<AiModeScreen> createState() => _AiModeScreenState();
}

class _AiModeScreenState extends ConsumerState<AiModeScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  List<String> _getSuggestions(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return [
      localizations.ai_suggestion_self,
      localizations.ai_suggestion_enlightenment,
    ];
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    // Always rebuild to update character counter
    setState(() {
      _hasText = _controller.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSuggestionTap(String suggestion) {
    // Don't focus the text field when tapping suggestions
    _sendMessage(suggestion);
  }

  void _onSendMessage() {
    if (_controller.text.trim().isEmpty) return;
    final message = _controller.text.trim();
    _controller.clear();
    _focusNode.unfocus();
    _sendMessage(message);
  }

  void _sendMessage(String message) {
    ref.read(chatControllerProvider.notifier).sendMessage(message);
  }

  void _onNewChat() {
    // Start new thread
    ref.read(chatControllerProvider.notifier).startNewThread();
    // Note: Thread list will be refreshed automatically when we receive
    // the thread_id from the API after sending the first message
  }

  void _onMenuPressed() {
    // Show fullscreen overlay drawer that covers bottom nav
    final localizations = AppLocalizations.of(context)!;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: localizations.ai_chat_history,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const ChatHistoryDrawer();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    if (authState.isGuest) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: _buildSignInPrompt(isDarkMode),
      );
    }

    final chatState = ref.watch(chatControllerProvider);
    final hasMessages = chatState.messages.isNotEmpty || chatState.isStreaming;

    if (chatState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final localizations = AppLocalizations.of(context)!;
        final friendlyMessage = ErrorMessageMapper.getDisplayMessage(
          chatState.error,
          context: 'chat',
        );
        final isRetryable = ErrorMessageMapper.isRetryable(chatState.error);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label:
                  isRetryable
                      ? localizations.ai_retry
                      : localizations.ai_dismiss,
              textColor: Colors.white,
              onPressed: () {
                ref.read(chatControllerProvider.notifier).clearError();
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        ref.read(chatControllerProvider.notifier).clearError();
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        onHorizontalDragEnd: (details) {
          // Open drawer when swiping from left to right
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            _onMenuPressed();
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              // Show full header when in chat mode, minimal header in empty state
              if (hasMessages)
                ChatHeader(onNewChat: _onNewChat, onMenuPressed: _onMenuPressed)
              else
                _buildMinimalHeader(isDarkMode),

              // Main content area
              Expanded(
                child:
                    chatState.isLoadingThread
                        ? _buildLoadingState(isDarkMode)
                        : hasMessages
                        ? MessageList(
                          messages: chatState.messages,
                          isStreaming: chatState.isStreaming,
                          currentStreamingContent:
                              chatState.currentStreamingContent,
                        )
                        : _buildEmptyState(isDarkMode),
              ),

              // Bottom input section
              _buildInputSection(isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  // Build the minimal header for the empty state. Starting State for the app.
  Widget _buildMinimalHeader(bool isDarkMode) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? AppColors.grey800 : AppColors.grey100,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _onMenuPressed,
            icon: Icon(
              Icons.menu_sharp,
              color:
                  isDarkMode
                      ? AppColors.surfaceWhite
                      : AppColors.cardBorderDark,
            ),
            tooltip: localizations.ai_chat_history,
          ),
          Text(
            localizations.ai_buddhist_assistant,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color:
                  isDarkMode ? AppColors.surfaceWhite : AppColors.textPrimary,
            ),
          ),
          // Invisible spacer to balance the layout
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDarkMode) {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            localizations.ai_loading_conversation,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? AppColors.grey400 : AppColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInPrompt(bool isDarkMode) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 80,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 24),
              Text(
                localizations.sign_in,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color:
                      isDarkMode
                          ? AppColors.surfaceWhite
                          : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                localizations.ai_sign_in_prompt,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? AppColors.grey400 : AppColors.grey600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: Text(localizations.sign_in),
                onPressed: () {
                  LoginDrawer.show(context, ref);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    final localizations = AppLocalizations.of(context)!;
    final suggestions = _getSuggestions(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localizations.ai_explore_wisdom,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? AppColors.surfaceWhite : Colors.black,
              ),
            ),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                alignment: WrapAlignment.start,
                runAlignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.start,
                spacing: 8,
                runSpacing: 8,
                children:
                    suggestions.map((s) {
                      return ActionChip(
                        onPressed: () => _onSuggestionTap(s),
                        avatar: Icon(
                          Icons.lightbulb_outline,
                          size: 15,
                          color:
                              isDarkMode
                                  ? AppColors.surfaceWhite
                                  : AppColors.grey800,
                        ),
                        label: Text(s),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color:
                              isDarkMode
                                  ? AppColors.surfaceWhite
                                  : AppColors.grey800,
                        ),
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        shape: StadiumBorder(
                          side: BorderSide(color: Colors.transparent),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(bool isDarkMode) {
    final textLength = _controller.text.length;
    final isOverLimit = MessageValidator.exceedsLimit(_controller.text);
    final isApproachingLimit = MessageValidator.isApproachingLimit(
      _controller.text,
    );
    final canSend = _hasText && !isOverLimit;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? AppColors.surfaceVariantDark
                      : AppColors.primarySurface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    autofocus: false,
                    enableInteractiveSelection: true,
                    maxLines: null,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.ai_ask_question,
                      hintStyle: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.textSubtleDark
                                : AppColors.textPrimaryLight,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    style: TextStyle(
                      color:
                          isDarkMode
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 4, bottom: 4),
                  child: IconButton(
                    onPressed: canSend ? _onSendMessage : null,
                    icon: Icon(
                      Icons.send_rounded,
                      color:
                          canSend
                              ? (isDarkMode
                                  ? AppColors.primaryContainer
                                  : AppColors.backgroundDark)
                              : (isDarkMode
                                  ? AppColors.grey500
                                  : AppColors.grey800),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Character counter - only show when user has typed something
          if (_hasText)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$textLength/${MessageValidator.maxLength}',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isOverLimit
                            ? Colors.red
                            : isApproachingLimit
                            ? Colors.orange
                            : (isDarkMode
                                ? AppColors.grey500
                                : AppColors.grey600),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 5),
        ],
      ),
    );
  }
}
