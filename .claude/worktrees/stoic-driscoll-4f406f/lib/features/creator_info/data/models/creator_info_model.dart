import 'dart:convert';

import 'package:flutter_pecha/features/creator_info/domain/entities/creator_info.dart';

/// Social media account model.
class SocialMediaAccountModel {
  final String account;
  final String url;

  const SocialMediaAccountModel({
    required this.account,
    required this.url,
  });

  /// Convert SocialMediaAccount entity to SocialMediaAccountModel.
  static SocialMediaAccountModel fromEntity(SocialMediaAccount entity) {
    return SocialMediaAccountModel(
      account: entity.account,
      url: entity.url,
    );
  }

  /// Convert SocialMediaAccountModel to SocialMediaAccount entity.
  SocialMediaAccount toEntity() {
    return SocialMediaAccount(
      account: account,
      url: url,
    );
  }

  /// Serialize to JSON.
  Map<String, dynamic> toJson() => {
        'account': account,
        'url': url,
      };

  /// Deserialize from JSON.
  factory SocialMediaAccountModel.fromJson(Map<String, dynamic> json) {
    return SocialMediaAccountModel(
      account: json['account'] as String,
      url: json['url'] as String,
    );
  }
}

/// Creator credit model.
class CreatorCreditModel {
  final String language;
  final String name;
  final String bio;

  const CreatorCreditModel({
    required this.language,
    required this.name,
    required this.bio,
  });

  /// Convert CreatorCredit entity to CreatorCreditModel.
  static CreatorCreditModel fromEntity(CreatorCredit entity) {
    return CreatorCreditModel(
      language: entity.language,
      name: entity.name,
      bio: entity.bio,
    );
  }

  /// Convert CreatorCreditModel to CreatorCredit entity.
  CreatorCredit toEntity() {
    return CreatorCredit(
      language: language,
      name: name,
      bio: bio,
    );
  }

  /// Serialize to JSON.
  Map<String, dynamic> toJson() => {
        'language': language,
        'name': name,
        'bio': bio,
      };

  /// Deserialize from JSON.
  factory CreatorCreditModel.fromJson(Map<String, dynamic> json) {
    return CreatorCreditModel(
      language: json['language'] as String,
      name: json['name'] as String,
      bio: json['bio'] as String,
    );
  }
}

/// Creator info model with JSON serialization.
class CreatorInfoModel {
  final String id;
  final List<CreatorCreditModel> credits;
  final List<SocialMediaAccountModel> socialMedia;
  final List<String> featuredPlans;

  const CreatorInfoModel({
    required this.id,
    required this.credits,
    required this.socialMedia,
    required this.featuredPlans,
  });

  /// Convert CreatorInfo entity to CreatorInfoModel.
  static CreatorInfoModel fromEntity(CreatorInfo entity) {
    return CreatorInfoModel(
      id: entity.id,
      credits: entity.credits.map((credit) => CreatorCreditModel.fromEntity(credit)).toList(),
      socialMedia: entity.socialMedia.map((account) => SocialMediaAccountModel.fromEntity(account)).toList(),
      featuredPlans: entity.featuredPlans,
    );
  }

  /// Convert CreatorInfoModel to CreatorInfo entity.
  CreatorInfo toEntity() {
    return CreatorInfo(
      id: id,
      credits: credits.map((credit) => credit.toEntity()).toList(),
      socialMedia: socialMedia.map((account) => account.toEntity()).toList(),
      featuredPlans: featuredPlans,
    );
  }

  /// Serialize to JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'credits': credits.map((credit) => credit.toJson()).toList(),
        'socialMedia': socialMedia.map((account) => account.toJson()).toList(),
        'featuredPlans': featuredPlans,
      };

  /// Deserialize from JSON.
  factory CreatorInfoModel.fromJson(Map<String, dynamic> json) {
    return CreatorInfoModel(
      id: json['id'] as String,
      credits: (json['credits'] as List)
          .map((credit) => CreatorCreditModel.fromJson(credit as Map<String, dynamic>))
          .toList(),
      socialMedia: (json['socialMedia'] as List)
          .map((account) => SocialMediaAccountModel.fromJson(account as Map<String, dynamic>))
          .toList(),
      featuredPlans: (json['featuredPlans'] as List).cast<String>(),
    );
  }

  /// Deserialize from JSON string.
  factory CreatorInfoModel.fromJsonString(String jsonString) {
    return CreatorInfoModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Serialize to JSON string.
  String toJsonString() => jsonEncode(toJson());
}
