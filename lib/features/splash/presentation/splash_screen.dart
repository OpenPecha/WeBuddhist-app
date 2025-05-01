// This file contains the presentation layer for the splash screen feature.
// It handles the UI for the splash screen shown at app startup.

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/logo_label.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [const LogoLabel()],
        ),
      ),
    );
  }
}
