// This file contains the UI for the login page, following the provided design.
// It offers social login options and a guest login button.

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/logo_label.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import '../widgets/auth_buttons.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Show login UI only when auth state is fully resolved and user is unauthenticated.
    // During loading or while a redirect is pending (already logged in / guest),
    // we stay in a loading state so the form never flashes on screen.
    final isUnauthenticated =
        !authState.isLoading && !authState.isLoggedIn && !authState.isGuest;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height * 0.20,
              left: 0,
              right: 0,
              child: const Center(child: LogoLabel()),
            ),
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 180),
                      if (isUnauthenticated)
                        AuthButtons()
                      else
                        const CircularProgressIndicator(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
