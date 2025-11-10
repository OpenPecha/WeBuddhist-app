class RecitationContentModel {
  final String id;
  final String title;
  final String content;
  final String? phonetic;
  final String? translation;
  final String language;
  final String? author;
  final String? tradition;

  RecitationContentModel({
    required this.id,
    required this.title,
    required this.content,
    this.phonetic,
    this.translation,
    required this.language,
    this.author,
    this.tradition,
  });

  factory RecitationContentModel.fromJson(Map<String, dynamic> json) {
    return RecitationContentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      phonetic: json['phonetic'] as String?,
      translation: json['translation'] as String?,
      language: json['language'] as String,
      author: json['author'] as String?,
      tradition: json['tradition'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'phonetic': phonetic,
      'translation': translation,
      'language': language,
      'author': author,
      'tradition': tradition,
    };
  }

  RecitationContentModel copyWith({
    String? id,
    String? title,
    String? content,
    String? phonetic,
    String? translation,
    String? language,
    String? author,
    String? tradition,
  }) {
    return RecitationContentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      phonetic: phonetic ?? this.phonetic,
      translation: translation ?? this.translation,
      language: language ?? this.language,
      author: author ?? this.author,
      tradition: tradition ?? this.tradition,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecitationContentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RecitationContentModel(id: $id, title: $title, language: $language)';
  }
}


