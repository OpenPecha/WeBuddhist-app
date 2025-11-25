import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:go_router/go_router.dart';

class ViewIllustration extends StatelessWidget {
  final String imageUrl;
  final String title;

  const ViewIllustration({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            context.pop();
          },
        ),
        title: Text(title),
      ),
      body: CachedNetworkImageWidget(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorWidget: const Center(child: Icon(Icons.broken_image, size: 80)),
      ),
    );
  }
}
