import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum UsernameState { idle, checking, available, conflict, error, invalid }

/// A self-contained username input that shows a real-time availability status
/// icon and inline feedback (conflict message + tappable suggestions).
class UsernameFormField extends StatelessWidget {
  const UsernameFormField({
    super.key,
    required this.controller,
    required this.usernameState,
    required this.usernameSuggestions,
    required this.onChanged,
    required this.onSuggestionTap,
    required this.isDark,
    this.validationMessage,
  });

  final TextEditingController controller;
  final UsernameState usernameState;
  final List<String> usernameSuggestions;
  final ValueChanged<String> onChanged;

  /// Called when the user taps one of the suggested available usernames.
  final ValueChanged<String> onSuggestionTap;
  final bool isDark;

  /// Shown below the field when [usernameState] is [UsernameState.invalid].
  final String? validationMessage;

  InputBorder get _inputBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.grey800 : AppColors.grey300,
        ),
      );

  InputBorder get _focusedBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.grey600 : AppColors.grey900,
          width: 1.5,
        ),
      );

  InputBorder get _errorBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      );

  @override
  Widget build(BuildContext context) {
    final isError =
        usernameState == UsernameState.conflict ||
        usernameState == UsernameState.invalid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: 'Username',
            labelStyle: TextStyle(color: AppColors.grey500),
            filled: true,
            fillColor:
                isDark ? AppColors.surfaceVariantDark : AppColors.surfaceWhite,
            border: _inputBorder,
            enabledBorder: isError ? _errorBorder : _inputBorder,
            focusedBorder: isError ? _errorBorder : _focusedBorder,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: _buildStatusIcon(),
          ),
        ),
        _buildFeedback(),
      ],
    );
  }

  Widget? _buildStatusIcon() {
    switch (usernameState) {
      case UsernameState.checking:
        return Padding(
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.grey600),
            ),
          ),
        );
      case UsernameState.available:
        return Icon(
          PhosphorIconsRegular.checkCircle,
          color: Colors.green.shade600,
          size: 20,
        );
      case UsernameState.conflict:
        return Icon(
          PhosphorIconsRegular.warningCircle,
          color: Colors.red.shade600,
          size: 20,
        );
      case UsernameState.error:
        return Icon(
          PhosphorIconsRegular.warningCircle,
          color: Colors.orange.shade600,
          size: 20,
        );
      case UsernameState.invalid:
        return Icon(
          PhosphorIconsRegular.warningCircle,
          color: Colors.red.shade600,
          size: 20,
        );
      case UsernameState.idle:
        return null;
    }
  }

  Widget _buildFeedback() {
    switch (usernameState) {
      case UsernameState.conflict:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              'Someone already used this name',
              style: TextStyle(color: Colors.red.shade600, fontSize: 13),
            ),
            if (usernameSuggestions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                children: [
                  Text(
                    'Available : ',
                    style: TextStyle(
                      color: isDark ? AppColors.grey400 : AppColors.grey600,
                      fontSize: 13,
                    ),
                  ),
                  for (int i = 0; i < usernameSuggestions.length; i++) ...[
                    GestureDetector(
                      onTap: () => onSuggestionTap(usernameSuggestions[i]),
                      child: Text(
                        usernameSuggestions[i],
                        style: TextStyle(
                          color: isDark ? AppColors.grey400 : AppColors.grey600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (i < usernameSuggestions.length - 1)
                      Text(
                        ', ',
                        style: TextStyle(
                          color: isDark ? AppColors.grey400 : AppColors.grey600,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ],
              ),
            ],
          ],
        );
      case UsernameState.error:
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Could not check username. Try again.',
            style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
          ),
        );
      case UsernameState.invalid:
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            validationMessage ?? 'Invalid username format.',
            style: TextStyle(color: Colors.red.shade600, fontSize: 13),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
