import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/data/providers/texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/texts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextTocScreen extends ConsumerWidget {
  const TextTocScreen({super.key, required this.text});
  final Texts text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textContent = ref.watch(textContentFutureProvider(text.id));
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: null,
        shape: Border(bottom: BorderSide(color: Color(0xFFB6D7D7), width: 3)),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              text.title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            if (textContent.isLoading)
              const CircularProgressIndicator()
            else
              Text(textContent.value!.first.title),
          ],
        ),
      ),
    );
  }
}
