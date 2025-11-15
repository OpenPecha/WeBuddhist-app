/// Social profile information
class SocialProfile {
  final String account;
  final String url;

  const SocialProfile({
    required this.account,
    required this.url,
  });

  factory SocialProfile.fromJson(Map<String, dynamic> json) {
    return SocialProfile(
      account: json['account']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account': account,
      'url': url,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SocialProfile &&
        other.account == account &&
        other.url == url;
  }

  @override
  int get hashCode => Object.hash(account, url);
}

class User {
  // from api response
  final String? id;
  final String? firstName;
  final String? email;
  final String? lastName;
  final String? username;
  final String? title;
  final String? organization;
  final String? location;
  final String? aboutMe;
  final String? avatarUrl;
  final List<String>? educations;
  final int? followers;
  final int? following;
  final List<SocialProfile>? socialProfiles;

  // from local storage
  final bool onboardingCompleted;

  const User({
    this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.username,
    this.title,
    this.organization,
    this.location,
    this.aboutMe,
    this.avatarUrl,
    this.educations,
    this.followers,
    this.following,
    this.socialProfiles,
    this.onboardingCompleted = false,
  });

  User copyWith({
    String? id,
    String? firstName,
    String? email,
    String? lastName,
    String? username,
    String? title,
    String? organization,
    String? location,
    String? aboutMe,
    String? avatarUrl,
    List<String>? educations,
    int? followers,
    int? following,
    List<SocialProfile>? socialProfiles,
    bool? onboardingCompleted,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      title: title ?? this.title,
      organization: organization ?? this.organization,
      location: location ?? this.location,
      aboutMe: aboutMe ?? this.aboutMe,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      educations: educations ?? this.educations,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      socialProfiles: socialProfiles ?? this.socialProfiles,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }


  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(),
      email: json['email']?.toString(),
      firstName: json['firstname']?.toString(),
      lastName: json['lastname']?.toString(),
      username: json['username']?.toString(),
      title: json['title']?.toString(),
      organization: json['organization']?.toString(),
      location: json['location']?.toString(),
      aboutMe: json['about_me']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      educations: (json['educations'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      followers: json['followers'] as int?,
      following: json['following'] as int?,
      socialProfiles: (json['social_profiles'] as List<dynamic>?)
          ?.map((e) => SocialProfile.fromJson(e as Map<String, dynamic>))
          .toList(),
      // Note: onboarding_completed is NOT sent by backend API
      // It's managed locally only - will be set by UserNotifier
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstname': firstName,
      'lastname': lastName,
      'username': username,
      'title': title,
      'organization': organization,
      'location': location,
      'about_me': aboutMe,
      'avatar_url': avatarUrl,
      'educations': educations,
      'followers': followers,
      'following': following,
      'social_profiles': socialProfiles?.map((e) => e.toJson()).toList() ?? [],
      'onboarding_completed': onboardingCompleted,
    };
  }

  /// Get user's full name
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? username ?? email ?? 'User';
  }

  /// Get user's display name (fallback chain)
  String get displayName {
    return username ?? fullName;
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, firstName: $firstName, lastName: $lastName, username: $username, title: $title, organization: $organization, location: $location, aboutMe: $aboutMe, avatarUrl: $avatarUrl, educations: $educations, followers: $followers, following: $following, socialProfiles: $socialProfiles, onboardingCompleted: $onboardingCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
