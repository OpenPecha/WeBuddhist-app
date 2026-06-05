import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_pecha/shared/domain/value_objects/responsive_image.dart';

/// Network cover image that picks thumbnail / medium / original based on layout.
class ResponsiveCoverImage extends StatelessWidget {
  final ResponsiveImage? image;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? heroTag;
  final String? fallbackAsset;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ResponsiveCoverImage({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.heroTag,
    this.fallbackAsset,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (image == null || image!.isEmpty) {
      return _buildFallback(context, '');
    }

    final double? layoutWidth =
        width != null && width!.isFinite && width! > 0 ? width : null;

    if (layoutWidth != null) {
      return _buildResolved(context, layoutWidth);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double resolvedWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
        return _buildResolved(context, resolvedWidth);
      },
    );
  }

  Widget _buildResolved(BuildContext context, double layoutWidth) {
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final String? url = image!.urlForLayout(
      width: layoutWidth,
      height: height,
      devicePixelRatio: dpr,
    );
    return _buildFallback(context, url ?? '');
  }

  Widget _buildFallback(BuildContext context, String url) {
    if (url.isEmpty && fallbackAsset == null && placeholder == null) {
      return errorWidget ?? const SizedBox.shrink();
    }

    return CachedNetworkImageWidget(
      imageUrl: url.isEmpty ? null : url,
      fallbackAsset: fallbackAsset,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      heroTag: heroTag,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}
