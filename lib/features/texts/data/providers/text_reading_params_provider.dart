import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextReadingParams {
  final String textId;
  final String contentId;
  final String? versionId;
  final String skip;
  final double fontSize;

  const TextReadingParams({
    required this.textId,
    required this.contentId,
    this.versionId,
    this.skip = '0',
    this.fontSize = 16,
  });

  TextReadingParams copyWith({
    required String textId,
    required String contentId,
    String? versionId,
    String? skip,
    double? fontSize,
  }) {
    return TextReadingParams(
      textId: textId,
      contentId: contentId,
      versionId: versionId ?? this.versionId,
      skip: skip ?? this.skip,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}

class TextReadingParamsNotifier extends StateNotifier<TextReadingParams?> {
  TextReadingParamsNotifier() : super(null);

  void setParams({
    required String textId,
    required String contentId,
    String? versionId,
    String skip = '0',
  }) {
    state = TextReadingParams(
      textId: textId,
      contentId: contentId,
      versionId: versionId,
      skip: skip,
    );
  }

  void updateParams({
    required String textId,
    required String contentId,
    String? versionId,
    String? skip,
  }) {
    if (state != null) {
      state = state!.copyWith(
        textId: textId,
        contentId: contentId,
        versionId: versionId,
        skip: skip,
      );
    }
  }

  void setFontSize(double fontSize) {
    if (state != null) {
      state = state!.copyWith(
        textId: state!.textId,
        contentId: state!.contentId,
        fontSize: fontSize,
      );
    }
  }

  void clearParams() {
    state = null;
  }
}

final textReadingParamsProvider =
    StateNotifierProvider<TextReadingParamsNotifier, TextReadingParams?>((ref) {
      return TextReadingParamsNotifier();
    });
