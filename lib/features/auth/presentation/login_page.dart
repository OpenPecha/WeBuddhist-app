// This file contains the UI for the login page, following the provided design.
// It offers social login options and a guest login button.

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/logo_label.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/auth/application/auth_provider.dart';
import '../presentation/widgets/auth_buttons.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    // Redirect immediately if already logged in
    if (authState.isLoggedIn) {
      Future.microtask(() => Navigator.of(context).pushReplacementNamed('/home'));
      return const SizedBox.shrink();
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  const LogoLabel(),
                  const SizedBox(height: 36),
                  // Auth Buttons (Riverpod aware)
                  AuthButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
