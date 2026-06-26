import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/mala/domain/entities/mantra.dart';

class PracticeAccumulationCircleItem extends StatelessWidget {
  const PracticeAccumulationCircleItem({
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

    const titleStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.bold,
      height: 1.33,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 110,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipOval(
              child:
                  beadUrl != null && beadUrl.isNotEmpty
                      ? CachedNetworkImageWidget(
                        imageUrl: beadUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.spa, size: 24),
                      ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: titleStyle.fontSize! * titleStyle.height! * 2,
              child: Text(
                title,
                style: titleStyle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
