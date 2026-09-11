import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/features/recitation/data/models/my_recitation_list_collection_model.dart';

class PracticeMyChantsCollectionListTile extends StatelessWidget {
  const PracticeMyChantsCollectionListTile({
    super.key,
    required this.collection,
    this.onTap,
  });

  final MyRecitationListCollectionModel collection;
  final VoidCallback? onTap;

  static const double _thumbnailSize = 56;
  static const double _thumbnailRadius = 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtitleColor = isDark ? AppColors.textSubtleDark : AppColors.grey900;
    final trailingColor = theme.colorScheme.onSurfaceVariant;
    final chantLabel = context.l10n.my_recitation_collection_chant_count_owner(
      collection.itemCount,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: isDark ? AppColors.cardBackgroundDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _CollectionThumbnail(imageUrl: collection.imageUrl),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        collection.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chantLabel,
                        style: TextStyle(fontSize: 13, color: subtitleColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: trailingColor.withAlpha(100),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      AppAssets.caretRight,
                      size: 16,
                      color: trailingColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CollectionThumbnail extends StatelessWidget {
  const _CollectionThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    const fallback = _CollectionThumbnailFallback();
    final url = imageUrl?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(
        PracticeMyChantsCollectionListTile._thumbnailRadius,
      ),
      child: SizedBox(
        width: PracticeMyChantsCollectionListTile._thumbnailSize,
        height: PracticeMyChantsCollectionListTile._thumbnailSize,
        child:
            url != null && _isSupportedImageUrl(url)
                ? CachedNetworkImageWidget(
                  imageUrl: url,
                  width: PracticeMyChantsCollectionListTile._thumbnailSize,
                  height: PracticeMyChantsCollectionListTile._thumbnailSize,
                  fit: BoxFit.cover,
                  placeholder: fallback,
                  errorWidget: fallback,
                )
                : fallback,
      ),
    );
  }

  bool _isSupportedImageUrl(String value) {
    if (value.startsWith('assets/')) return true;
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }
}

class _CollectionThumbnailFallback extends StatelessWidget {
  const _CollectionThumbnailFallback();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.myCollectionDefault,
      width: PracticeMyChantsCollectionListTile._thumbnailSize,
      height: PracticeMyChantsCollectionListTile._thumbnailSize,
      fit: BoxFit.cover,
    );
  }
}
