import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

bool _isAssetPath(String url) => url.trim().startsWith('assets/');

bool _isNetworkUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  return uri != null &&
      uri.hasScheme &&
      (uri.scheme == 'http' || uri.scheme == 'https');
}

class CachedNetworkImageWidget extends StatelessWidget {
  /// Remote http(s) URL, or a bundled asset path starting with `assets/`.
  final String? imageUrl;

  /// Shown when [imageUrl] is null/empty, or when a network image fails to load.
  final String? fallbackAsset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? heroTag;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration? placeholderFadeInDuration;
  final Duration? fadeInDuration;
  final VoidCallback? onImageLoaded;

  const CachedNetworkImageWidget({
    super.key,
    this.imageUrl,
    this.fallbackAsset,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.heroTag,
    this.placeholder,
    this.errorWidget,
    this.placeholderFadeInDuration,
    this.fadeInDuration,
    this.onImageLoaded,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = imageUrl?.trim();
    final url = (trimmed != null && trimmed.isNotEmpty) ? trimmed : null;

    Widget imageWidget;

    if (url != null && _isAssetPath(url)) {
      imageWidget = _buildAssetImage(url, context);
      if (onImageLoaded != null) {
        imageWidget = _ImageLoadedNotifier(
          onImageLoaded: onImageLoaded!,
          imageUrl: url,
          useAssetImage: true,
          child: imageWidget,
        );
      }
    } else if (url != null && _isNetworkUrl(url)) {
      imageWidget = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder:
            placeholder != null
                ? (context, url) => placeholder!
                : (context, url) =>
                    const Center(child: CircularProgressIndicator()),
        errorWidget:
            errorWidget != null
                ? (context, url, error) => errorWidget!
                : (context, url, error) =>
                    fallbackAsset != null
                        ? _buildAssetImage(fallbackAsset!, context)
                        : _buildErrorWidget(context),
      );

      if (onImageLoaded != null) {
        imageWidget = _ImageLoadedNotifier(
          onImageLoaded: onImageLoaded!,
          imageUrl: url,
          useAssetImage: false,
          child: imageWidget,
        );
      }
    } else if (url != null) {
      // Non-http URL and not an asset path — treat as missing.
      imageWidget =
          fallbackAsset != null
              ? _buildAssetImage(fallbackAsset!, context)
              : _buildErrorWidget(context);
    } else if (fallbackAsset != null) {
      imageWidget = _buildAssetImage(fallbackAsset!, context);
      if (onImageLoaded != null) {
        imageWidget = _ImageLoadedNotifier(
          onImageLoaded: onImageLoaded!,
          imageUrl: fallbackAsset!,
          useAssetImage: true,
          child: imageWidget,
        );
      }
    } else {
      imageWidget = _buildErrorWidget(context);
    }

    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    if (heroTag != null && heroTag!.isNotEmpty) {
      imageWidget = Hero(tag: heroTag!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildAssetImage(String assetPath, BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder:
          (context, error, stackTrace) =>
              errorWidget ?? _buildErrorWidget(context),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
      ),
    );
  }
}

class _ImageLoadedNotifier extends StatefulWidget {
  final Widget child;
  final VoidCallback onImageLoaded;
  final String imageUrl;
  final bool useAssetImage;

  const _ImageLoadedNotifier({
    required this.child,
    required this.onImageLoaded,
    required this.imageUrl,
    this.useAssetImage = false,
  });

  @override
  State<_ImageLoadedNotifier> createState() => _ImageLoadedNotifierState();
}

class _ImageLoadedNotifierState extends State<_ImageLoadedNotifier> {
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  bool _hasCalledCallback = false;

  @override
  void initState() {
    super.initState();
    _setupImageListener();
  }

  void _setupImageListener() {
    final ImageProvider imageProvider =
        widget.useAssetImage
            ? AssetImage(widget.imageUrl)
            : CachedNetworkImageProvider(widget.imageUrl);
    _imageStream = imageProvider.resolve(const ImageConfiguration());
    _imageStreamListener = ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        if (!_hasCalledCallback && mounted) {
          _hasCalledCallback = true;
          widget.onImageLoaded();
        }
      },
      onError: (exception, stackTrace) {
        // Don't call callback on error
      },
    );
    _imageStream?.addListener(_imageStreamListener!);
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_imageStreamListener!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

extension CachedNetworkImageProviderExtension on String {
  ImageProvider get cachedNetworkImageProvider {
    return CachedNetworkImageProvider(this);
  }
}
