class DeepLinkUrlBuilder {
  DeepLinkUrlBuilder._();

  static const String _host = 'webuddhist.com';

  static Uri readerSegmentLink({
    required String textId,
    required String segmentId,
    String? language,
  }) {
    final queryParameters = <String, String>{
      'segment': segmentId,
      if (language != null && language.isNotEmpty) 'lang': language,
    };

    return Uri(
      scheme: 'https',
      host: _host,
      pathSegments: ['open', 'reader', textId],
      queryParameters: queryParameters,
    );
  }
}
