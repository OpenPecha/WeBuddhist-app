import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';

class ChatHeader extends StatelessWidget {
  final VoidCallback? onNewChat;
  final VoidCallback? onMenuPressed;

  const ChatHeader({
    super.key,
    this.onNewChat,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            onPressed: onMenuPressed,
            icon: Icon(
              Icons.menu_sharp,
              color: isDarkMode ? AppColors.surfaceWhite : AppColors.cardBorderDark,
            ),
            tooltip: localizations.ai_chat_history,
          ),
          Text(
            localizations.ai_buddhist_assistant,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? AppColors.surfaceWhite : AppColors.textPrimary,
            ),
          ),
          if (onNewChat != null)
            IconButton(
              onPressed: onNewChat,
              icon: Icon(
                Icons.add,
                color: isDarkMode ? AppColors.surfaceWhite : AppColors.cardBorderDark,
              ),
              tooltip: localizations.ai_new_chat,
            ),
        ],
      ),
    );
  }
}
