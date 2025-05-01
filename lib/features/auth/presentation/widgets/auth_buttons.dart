// Widget for authentication buttons (social logins, guest login)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/auth_provider.dart';
import '../../auth_service.dart';

class AuthButtons extends ConsumerWidget {
  AuthButtons({super.key});
  final authService = AuthService();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.facebook, color: Colors.white),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1877F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final credentials = await authService.loginWithFacebook();
              if (credentials?.user != null) {
                ref.read(authProvider.notifier).login(userId: credentials!.user.sub ?? 'facebook');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Facebook login successful!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Facebook login failed!')),
                );
              }
            },
            label: const Text('Continue with Facebook'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.g_mobiledata, color: Colors.black),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.grey),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final credentials = await authService.loginWithGoogle();
              if (credentials != null) {
                ref.read(authProvider.notifier).login(userId: credentials.user.sub ?? 'google');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Google login successful!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Google login failed!')),
                );
              }
            },
            label: const Text('Continue with Google'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.apple, color: Colors.white),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final credentials = await authService.loginWithApple();
              if (credentials != null) {
                ref.read(authProvider.notifier).login(userId: credentials.user.sub ?? 'apple');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Apple login successful!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Apple login failed!')),
                );
              }
            },
            label: const Text('Continue with Apple'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black, width: 1),
            ),
            onPressed: () {
              ref.read(authProvider.notifier).login(userId: 'guest');
            },
            child: const Text('Continue as Guest'),
          ),
        ),
      ],
    );
  }
}
