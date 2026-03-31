import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextVersionLanguageNotifier extends StateNotifier<String> {
  TextVersionLanguageNotifier() : super('en');

  void setLanguageCode(String languageCode) {
    state = languageCode;
  }
}

final textVersionLanguageProvider =
    StateNotifierProvider<TextVersionLanguageNotifier, String>((ref) {
      return TextVersionLanguageNotifier();
    });
