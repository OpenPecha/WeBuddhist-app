import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/plans/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/story_view/utils/story_dialog_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VerseCard extends ConsumerWidget {
  final String verseText;
  final String title;
  final Map<String, dynamic>? nextCard;

  const VerseCard({
    super.key,
    required this.verseText,
    required this.title,
    this.nextCard,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageUrl =
        "https://images.unsplash.com/photo-1685495856559-5d96a0e51acb?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=2624";
    return GestureDetector(
      onTap: () {
        showStoryDialog(
          context: context,
          subtasks: [
            UserSubtasksDto(
              id: 'verse-of-day',
              contentType: 'IMAGE',
              content: imageUrl,
              displayOrder: 0,
              isCompleted: false,
            ),
          ],
          nextCard: nextCard,
        );
      },
      child: Stack(
        children: [
          // Main card with Hero animation
          Hero(
            tag: 'verse-image-$imageUrl',
            child: Container(
              width: double.infinity,
              height: 311,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image:
                    imageUrl.isNotEmpty
                        ? DecorationImage(
                          image: imageUrl.cachedNetworkImageProvider,
                          fit: BoxFit.fill,
                        )
                        : null,
                color: imageUrl.isEmpty ? Colors.brown[700] : null,
              ),
              child: Stack(
                children: [
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            fontFamily: 'Instrument Serif',
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Text(
                              verseText,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                height: 0.97,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
