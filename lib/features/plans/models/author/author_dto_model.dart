class AuthorDtoModel {
  final String id;
  final String firstName;
  final String lastName;
  final String imageUrl;

  AuthorDtoModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.imageUrl,
  });

  factory AuthorDtoModel.fromJson(Map<String, dynamic> json) {
    return AuthorDtoModel(
      id: json['id'],
      firstName: json['firstname'],
      lastName: json['lastname'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'imageUrl': imageUrl,
    };
  }

  @override
  String toString() {
    return 'AuthorDtoModel(id: $id, firstName: $firstName, lastName: $lastName, imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthorDtoModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
