class ReaderScriptOption {
  final String id;
  final String label;
  final String? name;

  const ReaderScriptOption({
    required this.id,
    required this.label,
    this.name,
  });

  factory ReaderScriptOption.fromJson(Map<String, dynamic> json) {
    return ReaderScriptOption(
      id: json['script_code'] as String? ?? '',
      label: json['script'] as String? ?? '',
      name: json['name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'script_code': id,
        'script': label,
        'name': name,
      };
}

class ReaderScriptsResponse {
  final String textId;
  final String language;
  final List<ReaderScriptOption> availableScripts;

  const ReaderScriptsResponse({
    required this.textId,
    required this.language,
    required this.availableScripts,
  });

  factory ReaderScriptsResponse.fromJson(Map<String, dynamic> json) {
    return ReaderScriptsResponse(
      textId: json['text_id'] as String? ?? '',
      language: json['language'] as String? ?? '',
      availableScripts: (json['available_scripts'] as List<dynamic>? ?? [])
          .map((e) => ReaderScriptOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
