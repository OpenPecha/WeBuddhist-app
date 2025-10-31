import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_card.dart';

class VerseText extends StatelessWidget {
  final String verseText;

  const VerseText({super.key, required this.verseText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verse Of The Day")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            VerseCard(verseText: verseText, title: 'Verse Of The Day'),
          ],
        ),
      ),
    );
  }
}
