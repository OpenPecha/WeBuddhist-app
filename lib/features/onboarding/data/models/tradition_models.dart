class TraditionPath {
  const TraditionPath({
    required this.code,
    required this.title,
    required this.description,
  });

  final String code;
  final String title;
  final String description;

  factory TraditionPath.fromJson(String code, Map<String, dynamic> json) {
    return TraditionPath(
      code: code,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class UserTradition {
  const UserTradition({
    required this.id,
    required this.traditionCode,
    required this.traditionName,
  });

  final String id;
  final String traditionCode;
  final String traditionName;

  factory UserTradition.fromJson(Map<String, dynamic> json) {
    return UserTradition(
      id: json['id'] as String,
      traditionCode: json['tradition_code'] as String,
      traditionName: json['tradition_name'] as String? ?? '',
    );
  }
}

class SaveTraditionRequest {
  const SaveTraditionRequest({required this.traditionCode});

  final String traditionCode;

  Map<String, dynamic> toJson() => {
    'tradition_code': traditionCode,
  };
}

const traditionPathOrder = ['pali', 'chinese', 'tibetan'];

const traditionShowAllCode = 'show_all';
