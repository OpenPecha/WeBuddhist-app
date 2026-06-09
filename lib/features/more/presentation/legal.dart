import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  static const String routeName = '/legal';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Legal',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            _buildLegalRow(
              context,
              icon: PhosphorIconsRegular.fileText,
              title: 'Terms of Service',
            ),
            _buildLegalRow(
              context,
              icon: PhosphorIconsRegular.fileText,
              title: 'Privacy policy',
              onTap: () => context.push(AppRoutes.privacyPolicy),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.bodyLarge),
            ),
            Icon(
              PhosphorIconsRegular.arrowSquareOut,
              size: 24,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ],
        ),
      ),
    );
  }
}
