import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/features/onboarding/application/tradition_chat_provider.dart';
import 'package:flutter_pecha/features/onboarding/application/tradition_chat_state.dart';
import 'package:flutter_pecha/features/onboarding/data/models/tradition_chat_models.dart';
import 'package:flutter_pecha/features/onboarding/presentation/widgets/onboarding_back_button.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Onboarding screen: tradition chatbot to identify the user's Buddhist tradition.
class OnboardingScreenTraditionChat extends ConsumerStatefulWidget {
  const OnboardingScreenTraditionChat({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  ConsumerState<OnboardingScreenTraditionChat> createState() =>
      _OnboardingScreenTraditionChatState();
}

class _OnboardingScreenTraditionChatState
    extends ConsumerState<OnboardingScreenTraditionChat> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController
      ..removeListener(_onTextChanged)
      ..dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    _textController.clear();
    _focusNode.unfocus();
    await ref.read(traditionChatProvider.notifier).sendMessage(content);
    _scrollToBottom();
  }

  Future<void> _handleContinue() async {
    final saved =
        await ref.read(traditionChatProvider.notifier).saveSelectedTradition();
    if (!mounted || !saved) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.something_went_wrong)),
        );
      }
      return;
    }
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chatState = ref.watch(traditionChatProvider);

    ref.listen<TraditionChatState>(traditionChatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.something_went_wrong)));
      }
    });

    final canSend =
        _textController.text.trim().isNotEmpty && !chatState.isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChatHeader(
              title: l10n.onboarding_tradition_chat_title,
              subtitle: l10n.onboarding_tradition_chat_subtitle,
              onBack: widget.onBack,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _ChatMessageList(
                scrollController: _scrollController,
                messages: chatState.messages,
                suggestedTraditions: chatState.suggestedTraditions,
                isComplete: chatState.isComplete,
                isLoading: chatState.isLoading,
                onSelectTradition: _sendMessage,
              ),
            ),
            if (!chatState.isComplete) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _ChatInputField(
                  controller: _textController,
                  focusNode: _focusNode,
                  hintText: l10n.onboarding_tradition_type_hint,
                  canSend: canSend,
                  isLoading: chatState.isLoading,
                  onSend: () => _sendMessage(_textController.text),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
              child:
                  chatState.isComplete
                      ? _ContinueButton(
                        isSaving: chatState.isSaving,
                        onContinue: _handleContinue,
                      )
                      : _SkipButton(onSkip: widget.onSkip),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final subtitleColor = onSurface.withValues(alpha: 0.65);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          OnboardingBackButton(onBack: onBack),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: onSurface,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: subtitleColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageList extends StatelessWidget {
  const _ChatMessageList({
    required this.scrollController,
    required this.messages,
    required this.suggestedTraditions,
    required this.isComplete,
    required this.isLoading,
    required this.onSelectTradition,
  });

  final ScrollController scrollController;
  final List<TraditionChatMessage> messages;
  final List<SuggestedTradition> suggestedTraditions;
  final bool isComplete;
  final bool isLoading;
  final ValueChanged<String> onSelectTradition;

  @override
  Widget build(BuildContext context) {
    final showChips = !isComplete && suggestedTraditions.isNotEmpty;
    final itemCount =
        messages.length + (isLoading ? 1 : 0) + (showChips ? 1 : 0);

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index < messages.length) {
          return _ChatBubble(message: messages[index]);
        }

        final afterMessagesIndex = index - messages.length;

        if (isLoading && afterMessagesIndex == 0) {
          return const _TypingIndicator();
        }

        if (showChips && afterMessagesIndex == (isLoading ? 1 : 0)) {
          return _SuggestedTraditionChips(
            traditions: suggestedTraditions,
            onSelect: onSelectTradition,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final TraditionChatMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.brandblue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.content,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ),
      );
    }

    final language = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: MarkdownBody(
          data: message.content,
          selectable: true,
          shrinkWrap: true,
          softLineBreak: true,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurface,
              height: getLineHeight(language) ?? 1.4,
              fontFamily: getSystemFontFamily(language),
            ),
            listBullet: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            strong: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestedTraditionChips extends StatelessWidget {
  const _SuggestedTraditionChips({
    required this.traditions,
    required this.onSelect,
  });

  final List<SuggestedTradition> traditions;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    final chipColor = isDark ? AppColors.surfaceDark : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children:
            traditions.map((tradition) {
              return InkWell(
                onTap: () => onSelect(tradition.name),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    tradition.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ChatInputField extends StatelessWidget {
  const _ChatInputField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.canSend,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool canSend;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outlineColor = isDark ? AppColors.cardBorderDark : AppColors.grey300;
    const fontSize = 16.0;
    final language = Localizations.localeOf(context).languageCode;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final isTibetan = context.isTibetanLocale;

    TextStyle fieldStyle(Color color) {
      final style = TextStyle(
        fontSize: fontSize,
        color: color,
        fontFamily: getSystemFontFamily(language),
        height: getLineHeight(language),
      );
      return AppFontConfig.applyTibetanMetrics(language, style) ?? style;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: outlineColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: !isLoading,
              minLines: 1,
              maxLines: 2,
              textInputAction: TextInputAction.send,
              onSubmitted: canSend ? (_) => onSend() : null,
              strutStyle: context.tibetanStrutStyle(fontSize),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.transparent,
                hintText: hintText,
                hintStyle: fieldStyle(onSurfaceColor.withValues(alpha: 0.45)),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: isTibetan ? 16 : 14,
                ),
              ),
              style: fieldStyle(onSurfaceColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Material(
              color: canSend ? AppColors.brandblue : AppColors.greyLight,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: canSend ? onSend : null,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: canSend ? Colors.white : AppColors.grey500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onSkip,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.greyLight,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          context.l10n.onboarding_skip_for_now,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.isSaving, required this.onContinue});

  final bool isSaving;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isSaving ? null : onContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandblue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child:
            isSaving
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Text(
                  context.l10n.onboarding_continue,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }
}
