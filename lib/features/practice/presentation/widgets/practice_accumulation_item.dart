import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';

class PracticeAccumulationItem extends StatelessWidget {
  const PracticeAccumulationItem({
    super.key,
    required this.mantra,
    required this.language,
    required this.onTap,
  });

  final Mantra mantra;
  final String language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final beadUrl = mantra.mantra?.beadImageUrl ?? mantra.beadImageUrl;
    final title = mantra.displayTitle(language);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            ClipOval(
              child:
                  beadUrl != null && beadUrl.isNotEmpty
                      ? CachedNetworkImageWidget(
                        imageUrl: beadUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.spa, size: 24),
                      ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
