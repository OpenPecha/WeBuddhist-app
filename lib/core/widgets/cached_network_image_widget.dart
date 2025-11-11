import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedNetworkImageWidget extends StatelessWidget {
  final String imageUrl;
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
    required this.imageUrl,
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
    if (imageUrl.isEmpty) {
      return _buildErrorWidget(context);
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
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
              : (context, url, error) => _buildErrorWidget(context),
    );

    if (onImageLoaded != null) {
      imageWidget = _ImageLoadedNotifier(
        onImageLoaded: onImageLoaded!,
        imageUrl: imageUrl,
        child: imageWidget,
      );
    }

    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    if (heroTag != null && heroTag!.isNotEmpty) {
      imageWidget = Hero(tag: heroTag!, child: imageWidget);
    }

    return imageWidget;
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

  const _ImageLoadedNotifier({
    required this.child,
    required this.onImageLoaded,
    required this.imageUrl,
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
    final imageProvider = CachedNetworkImageProvider(widget.imageUrl);
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
