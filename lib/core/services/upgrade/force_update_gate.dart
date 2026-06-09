import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/router/app_router.dart';
import 'package:flutter_pecha/core/services/upgrade/force_update_dialog.dart';
import 'package:flutter_pecha/core/services/upgrade/upgrade_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps the app's root child and shows a non-dismissible forced-update dialog
/// on Android/iOS whenever the store detects a newer version.
///
/// Mount this via [MaterialApp.router]'s `builder` parameter so the dialog
/// sits above the GoRouter navigator and blocks every route.
class ForceUpdateGate extends ConsumerStatefulWidget {
  const ForceUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ForceUpdateGate> createState() => _ForceUpdateGateState();
}

class _ForceUpdateGateState extends ConsumerState<ForceUpdateGate> {
  /// Prevents the dialog from being enqueued more than once across rebuilds.
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    // Only enforce on Android/iOS; skip macOS and other platforms.
    if (!Platform.isAndroid && !Platform.isIOS) {
      return widget.child;
    }

    final updateAsync = ref.watch(updateAvailableProvider);

    updateAsync.whenData((isAvailable) {
      if (isAvailable && !_dialogShown) {
        _dialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Use the navigator key's context so the dialog is pushed onto a
          // context that is actually inside the GoRouter navigator tree.
          // The builder context (ForceUpdateGate) is above the navigator, so
          // Navigator.of(context) would fail from here.
          final navContext = rootNavigatorKey.currentContext;
          if (navContext == null) return;
          showDialog<void>(
            context: navContext,
            barrierDismissible: false,
            builder: (_) => const ForceUpdateDialog(),
          );
        });
      }
    });

    return widget.child;
  }
}
