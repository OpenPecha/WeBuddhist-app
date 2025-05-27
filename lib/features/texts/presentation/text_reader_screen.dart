import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/data/providers/texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/segment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextReaderScreen extends ConsumerWidget {
  const TextReaderScreen({
    super.key,
    required this.textId,
    this.contentId,
    this.versionId,
  });
  final String textId;
  final String? contentId;
  final String? versionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final segments = ref.watch(
    //   textDetailsFutureProvider(
    //     TextDetailsParams(textId: textId, contentId: contentId ?? ''),
    //   ),
    // );

    final List<Segment> segments = [
      Segment(
        segmentId: "2bfd3d67-e3ac-4f4e-b5c3-a23f8aa92c49",
        segmentNumber: 1,
        content:
            "Bowing respectfully to the Sugatas possessing the Dharmakaya, together with their sons,<br>And to all those worthy of veneration,<br>I will briefly explain, in accordance with scripture,<br>The entrance into the vows of the Sons of the Sugatas.",
        translation: "",
      ),
      Segment(
        segmentId: "d62460af-4ed7-4112-a53d-5023a985aa16",
        segmentNumber: 2,
        content:
            "There is nothing previously unspoken to be said here,<br>Nor do I possess skill in composition.<br>Therefore, I have no intention of benefiting others;<br>I have composed this to cultivate my own mind.",
        translation: "",
      ),
      Segment(
        segmentId: "2bfd3d67-e3ac-4f4e-b5c3-a23f8aa92c49",
        segmentNumber: 3,
        content:
            "Bowing respectfully to the Sugatas possessing the Dharmakaya, together with their sons,<br>And to all those worthy of veneration,<br>I will briefly explain, in accordance with scripture,<br>The entrance into the vows of the Sons of the Sugatas.",
        translation: "",
      ),
      Segment(
        segmentId: "d62460af-4ed7-4112-a53d-5023a985aa16",
        segmentNumber: 4,
        content:
            "There is nothing previously unspoken to be said here,<br>Nor do I possess skill in composition.<br>Therefore, I have no intention of benefiting others;<br>I have composed this to cultivate my own mind.",
        translation: "",
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        toolbarHeight: 40,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: const Color(0xFFB6D7D7)),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'The Way of the Bodhisattva',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Jomolhari',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '1',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Jomolhari',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final segment = segments[index];
              final segmentNumber = segment.segmentNumber.toString().padLeft(
                2,
                '0',
              );
              final content = segment.content.replaceAll('<br>', '\n');
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        segmentNumber,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        content,
                        style: TextStyle(fontSize: 16, height: 1.6),
                      ),
                    ),
                  ],
                ),
              );
            }, childCount: segments.length),
          ),
        ],
      ),
    );
  }
}
