class AuthorModel {
  final String id;
  final String name;
  final String? bio;
  final String? imageUrl;
  final String? email;
  final bool isVerified;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AuthorModel({
    required this.id,
    required this.name,
    this.bio,
    this.imageUrl,
    this.email,
    this.isVerified = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(
      id: json['id'],
      name: json['name'],
      bio: json['bio'],
      imageUrl: json['image_url'],
      email: json['email'],
      isVerified: json['is_verified'],
      isActive: json['is_active'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'image_url': imageUrl,
      'email': email,
      'is_verified': isVerified,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  String toString() {
    return 'Author(id: $id, name: $name, bio: $bio, imageUrl: $imageUrl, email: $email, isVerified: $isVerified, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
