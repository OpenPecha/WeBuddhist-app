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
  
  static Uri seriesLink({required String seriesId}) {
    return Uri(
      scheme: 'https',
      host: _host,
      pathSegments: ['open', 'series', seriesId],
    );
  }

  static Uri planLink({required String planId}) {
    return Uri(
      scheme: 'https',
      host: _host,
      pathSegments: ['open', 'plan', planId],
    );
  }

  /// Returns a link that opens a specific day inside a plan.
  /// Format: https://webuddhist.com/open/plan/{planId}/day/{dayNumber}
  static Uri planDayLink({
    required String planId,
    required int dayNumber,
  }) {
    return Uri(
      scheme: 'https',
      host: _host,
      pathSegments: ['open', 'plan', planId, 'day', dayNumber.toString()],
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

  static Uri moreLink() {
    return Uri(scheme: 'https', host: _host, pathSegments: ['open', 'more']);
  }

  static Uri groupLink({required String groupId}) {
    return Uri(
      scheme: 'https',
      host: _host,
      pathSegments: ['open', 'group', groupId],
    );
  }

  static Uri malaLink({required String presetId}) {
    return Uri(
      scheme: 'https',
      host: _host,
      pathSegments: ['open', 'mala', presetId],
    );
  }

  static Uri timerLink({required String timerId}) {
    return Uri(
      scheme: 'https',
      host: _host,
      pathSegments: ['open', 'timer', timerId],
    );
  }
}
