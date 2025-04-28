import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MyHomePage(
            title: 'Pecha App',
            themeMode: ThemeMode.system,
            onToggleTheme: () {}, // You may want to pass actual handlers
            locale: null,
            onLocaleChanged: (_) {},
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Image.asset(
              'assets/images/pecha_logo.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            // App name
            Text(
              'Pecha',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily:
                    Theme.of(context).textTheme.headlineMedium?.fontFamily,
              ),
            ),
            const SizedBox(height: 24),
            // Tagline
            Text(
              'Learn Live and Share',
              style: TextStyle(
                fontSize: 24,
                color: Colors.black87,
                fontFamily:
                    Theme.of(context).textTheme.bodyLarge?.fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
