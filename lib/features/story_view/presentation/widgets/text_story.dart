import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/services/background_image/background_image_service.dart';

class TextStory extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final bool roundedTop;
  final bool roundedBottom;
  final String? backgroundImagePath;

  const TextStory({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textStyle,
    this.padding,
    this.roundedTop = false,
    this.roundedBottom = false,
    this.backgroundImagePath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBackgroundColor = backgroundColor ?? theme.primaryColor;

    // Calculate contrast for text color
    final brightness = ThemeData.estimateBrightnessForColor(
      defaultBackgroundColor,
    );
    final textColor =
        brightness == Brightness.dark ? Colors.white : Colors.black;

    // Get background image - use provided path or generate from text content
    final imagePath = backgroundImagePath ??
        BackgroundImageService().getImageForContent(text);

    // Get screen height to calculate 80% constraint
    final screenHeight = MediaQuery.of(context).size.height;
    final maxTextHeight = screenHeight * 0.6;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: imagePath.isNotEmpty
            ? DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              )
            : null,
        color: imagePath.isEmpty ? defaultBackgroundColor : null,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(roundedTop ? 8 : 0),
          bottom: Radius.circular(roundedBottom ? 8 : 0),
        ),
      ),
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Decorative element
          Container(
            width: 60,
            height: 4,
            margin: const EdgeInsets.only(bottom: 32),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Main text content
          SizedBox(
            height: maxTextHeight,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Text(
                text,
                style:
                    textStyle?.copyWith(color: textColor) ??
                    TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Bottom decorative element
          Container(
            width: 60,
            height: 4,
            margin: const EdgeInsets.only(top: 32),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
