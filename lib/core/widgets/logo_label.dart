import 'package:flutter/material.dart';

class LogoLabel extends StatelessWidget {
  const LogoLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo or splash animation can go here
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Image.asset('assets/images/favicon-pecha.png', height: 150),
        ),
        const Text(
          'Pecha',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
