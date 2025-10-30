import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/models/plan_subtasks_model.dart';
import 'package:flutter_pecha/features/story_view/presentation/story_feature.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VerseCard extends ConsumerWidget {
  final String verse;
  final String? author;
  final String? imageUrl;
  final String title;
  const VerseCard({
    super.key,
    required this.verse,
    this.author,
    this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        // Navigate to story view with verse as image story
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => StoryFeature(
                  subtask: [
                    PlanSubtasksModel(
                      id: 'verse-of-day',
                      contentType: 'IMAGE',
                      content: imageUrl,
                      displayOrder: 0,
                    ),
                  ],
                ),
          ),
        );
      },
      child: Stack(
        children: [
          // Main card with Hero animation
          Hero(
            tag: 'verse-image-${imageUrl ?? 'default'}',
            child: Container(
              width: double.infinity,
              height: 311,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image:
                    imageUrl != null && imageUrl!.isNotEmpty
                        ? DecorationImage(
                          image: NetworkImage(imageUrl!),
                          fit: BoxFit.cover,
                        )
                        : null,
                color:
                    imageUrl == null || imageUrl!.isEmpty
                        ? Colors.brown[700]
                        : null,
              ),
              child: Stack(
                children: [
                  // Gradient overlay for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Instrument Serif',
                          ),
                        ),
                        Text(
                          'The Way Of Bodhisattva',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          verse,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            height: 0.97,
                          ),
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        if (author != null && author!.isNotEmpty)
                          Text(
                            author!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.italic,
                              fontFamily: 'Instrument Serif',
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
