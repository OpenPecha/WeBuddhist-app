import 'package:equatable/equatable.dart';
import 'package:flutter_pecha/shared/domain/entities/base_entity.dart';

/// Social media account entity.
class SocialMediaAccount extends Equatable {
  final String account;
  final String url;

  const SocialMediaAccount({
    required this.account,
    required this.url,
  });

  @override
  List<Object?> get props => [account, url];
}

/// Creator credit entity for different languages.
class CreatorCredit extends Equatable {
  final String language;
  final String name;
  final String bio;

  const CreatorCredit({
    required this.language,
    required this.name,
    required this.bio,
  });

  @override
  List<Object?> get props => [language, name, bio];
}

/// Creator info entity.
class CreatorInfo extends BaseEntity {
  final String id;
  final List<CreatorCredit> credits;
  final List<SocialMediaAccount> socialMedia;
  final List<String> featuredPlans;

  const CreatorInfo({
    required this.id,
    required this.credits,
    required this.socialMedia,
    required this.featuredPlans,
  });

  /// Get credit for a specific language.
  CreatorCredit? getCreditForLanguage(String languageCode) {
    try {
      return credits.firstWhere((credit) => credit.language == languageCode);
    } catch (_) {
      // Fallback to English if language not found
      try {
        return credits.firstWhere((credit) => credit.language == 'en');
      } catch (_) {
        return null;
      }
    }
  }

  @override
  List<Object?> get props => [id, credits, socialMedia, featuredPlans];
}
