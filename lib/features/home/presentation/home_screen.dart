// This file contains the presentation layer for the home screen feature.
// It handles the UI for the main home screen after splash.

import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/core/theme/theme_provider.dart';
import 'package:flutter_pecha/core/config/locale_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Today',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Icon(Icons.notifications_none, size: 28),
                      SizedBox(width: 16),
                      Icon(Icons.account_circle, size: 32),
                    ],
                  ),
                ],
              ),
            ),
            // Scrollable body content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Verse of the Day Card (replace with your custom widget)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: VerseOfTheDayCard(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: VerseOfTheDayCard(),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: VerseOfTheDayCard(),
                    ),
                    // Add more content here as needed
                  ],
                ),
              ),
            ),
            // Fixed Bottom Navigation Bar
            // _CustomBottomNavBar(),
          ],
        ),
      ),
    );
  }
}

class _CustomBottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(Icons.home, size: 32),
          Icon(Icons.menu_book, size: 32),
          Icon(Icons.check_box, size: 32),
          Icon(Icons.menu, size: 32),
        ],
      ),
    );
  }
}

class VerseOfTheDayCard extends StatelessWidget {
  const VerseOfTheDayCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: Colors.brown[200],
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: AssetImage('assets/field.jpg'), // Replace with your image
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verse of the Day',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              '1 John 5:14 NIV',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Spacer(),
            Text(
              'This is the confidence we have in approaching God: that if we ask anything according to his will, he hears us.',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite_border, color: Colors.white),
                    SizedBox(width: 4),
                    Text('392.5k', style: TextStyle(color: Colors.white)),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.share, color: Colors.white),
                    SizedBox(width: 4),
                    Text('129.2k', style: TextStyle(color: Colors.white)),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.text_snippet, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Text', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
