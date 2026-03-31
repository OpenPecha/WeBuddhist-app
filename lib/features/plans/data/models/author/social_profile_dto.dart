class SocialProfileDto {
  final String account;
  final String url;

  SocialProfileDto({required this.account, required this.url});

  factory SocialProfileDto.fromJson(Map<String, dynamic> json) {
    return SocialProfileDto(
      account: json['account'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'account': account, 'url': url};
  }
}
