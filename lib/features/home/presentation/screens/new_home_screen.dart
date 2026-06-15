// DEV / WIP — This file replaces HomeScreen temporarily so the team can
// preview in-progress home page components on every hot-reload.
// Swap back to HomeScreen in main_navigation_screen.dart before opening a PR.

import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/home_header.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/home_share_prompt.dart';

class NewHomeScreen extends StatelessWidget {
  const NewHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Your component ──────────────────────────────────────────
            // Streak count is hardcoded to 1 to match the design mock-up.
            // Replace with a real provider once the streak API is integrated.
            const HomeHeader(streakCount: 1),
            // ────────────────────────────────────────────────────────────

            // Placeholders for other teammates' components.
            // Each person will import their widget here once ready.
            const Divider(height: 1),
            Expanded(
              child: Center(
                child: Text(
                  'Other home components go here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            const HomeSharePrompt(),
          ],
        ),
      ),
    );
  }
}
