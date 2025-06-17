import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/action_button.dart';
import 'package:share_plus/share_plus.dart';

class SegmentActionBar extends StatelessWidget {
  final String text;
  final VoidCallback onClose;
  const SegmentActionBar({
    required this.text,
    required this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(18),
          color: Theme.of(context).cardColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ActionButton(
                icon: Icons.copy,
                label: 'Copy',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Copied!')));
                  onClose();
                },
              ),
              ActionButton(
                icon: Icons.share,
                label: 'Share',
                onTap: () {
                  SharePlus.instance.share(
                    ShareParams(text: text, subject: 'Share this text'),
                  );
                  onClose();
                },
              ),
              ActionButton(
                icon: Icons.image,
                label: 'Image',
                onTap: () {
                  // TODO: Implement image export
                  onClose();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
