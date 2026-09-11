import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/auth/presentation/screens/splash_screen.dart';
import 'package:flutter_pecha/features/auth/presentation/screens/splash_taglines.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('randomSplashTagline picks from the tagline list', () {
    final seen = <String>{};
    for (var i = 0; i < 200; i++) {
      seen.add(randomSplashTagline(Random(i)));
    }
    expect(seen, isNotEmpty);
    expect(splashTaglines, containsAll(seen));
    expect(seen.length, greaterThan(1));
  });

  testWidgets('shows logo and a tagline, animating in', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(tagline: 'We Buddhists learn daily.'),
      ),
    );

    final text = find.text('We Buddhists learn daily.');
    expect(text, findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    final fade = tester.widget<FadeTransition>(
      find.ancestor(of: text, matching: find.byType(FadeTransition)).first,
    );
    expect(fade.opacity.value, 0);

    await tester.pump(const Duration(seconds: 1));
    expect(fade.opacity.value, 1);

    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('picks a tagline from the list when none is given', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    final text = tester.widget<Text>(find.byType(Text));
    expect(splashTaglines, contains(text.data));
    await tester.pump(const Duration(seconds: 2));
  });
}
