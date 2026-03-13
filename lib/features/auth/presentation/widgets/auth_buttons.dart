// Widget for authentication buttons (social logins, guest login)
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/social_login_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';

class AuthButtons extends ConsumerWidget {
  const AuthButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIOS = Platform.isIOS;
    final l10n = context.l10n;
    return Column(
      children: [
        SocialLoginButton(
          connection: 'google',
          icon: Icons.g_mobiledata,
          iconColor: Colors.black,
          label: l10n.continueWithGoogle,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          iconWidget: Image.asset(
            'assets/images/google-icon.png',
            width: 20,
            height: 20,
          ),
          isBorder: true,
        ),
        const SizedBox(height: 16),
        if (isIOS)
          SocialLoginButton(
            connection: 'apple',
            icon: Icons.apple,
            iconColor: Colors.white,
            label: l10n.continueWithApple,
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            iconWidget: Icon(Icons.apple, color: Colors.white, size: 24),
          ),
        const SizedBox(height: 16),
        SocialLoginButton(
          connection: 'guest',
          icon: Icons.person,
          iconColor: Colors.black,
          label: l10n.continueAsGuest,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          iconWidget: Icon(Icons.person, color: Colors.black, size: 24),
          isBorder: true,
        ),
      ],
    );
  }
}
