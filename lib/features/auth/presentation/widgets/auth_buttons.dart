// Widget for authentication buttons (social logins, guest login)
import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/auth/presentation/widgets/social_login_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthButtons extends ConsumerWidget {
  const AuthButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SocialLoginButton(
          connection: 'facebook',
          icon: Icons.facebook,
          iconColor: Colors.white,
          label: 'Continue with Facebook',
          backgroundColor: const Color(0xFF1877F3),
          foregroundColor: Colors.white,
        ),
        const SizedBox(height: 16),
        SocialLoginButton(
          connection: 'google',
          icon: Icons.g_mobiledata,
          iconColor: Colors.black,
          label: 'Continue with Google',
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        const SizedBox(height: 16),
        SocialLoginButton(
          connection: 'apple',
          icon: Icons.apple,
          iconColor: Colors.white,
          label: 'Continue with Apple',
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        const SizedBox(height: 16),
        SocialLoginButton(
          connection: 'guest',
          icon: Icons.person,
          iconColor: Colors.black,
          label: 'Continue as Guest',
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ],
    );
  }
}
