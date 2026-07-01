class DeepLinkUrlBuilder {
  DeepLinkUrlBuilder._();

  static const String _host = 'webuddhist.com';

  static Uri homeLink() {
    return Uri(scheme: 'https', host: _host, pathSegments: ['open']);
  }

  /// Returns a link that opens the reader at the very first segment —
  /// i.e. no segment/lang params so the app starts from the top.
  static Uri readerLink({required String textId}) {
    return Uri(
      scheme: 'https',
      host: _host,
      pathSegments: ['open', 'reader', textId],
    );
  }

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
