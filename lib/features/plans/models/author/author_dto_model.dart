import 'package:flutter_pecha/features/plans/models/plans_model.dart';

class AuthorDtoModel {
  final String id;
  final String firstName;
  final String lastName;
  final ImageModel? image;

  AuthorDtoModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.image,
  });

  String? get authorImageUrl => image?.medium ?? image?.original;
  String? get authorImageThumbnail => image?.thumbnail ?? image?.medium;

  factory AuthorDtoModel.fromJson(Map<String, dynamic> json) {
    return AuthorDtoModel(
      id: json['id'],
      firstName: json['firstname'],
      lastName: json['lastname'],
      image:
          json['image'] != null
              ? ImageModel.fromJson(json['image'] as Map<String, dynamic>?)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'image': image?.toJson(),
    };
  }

  @override
  String toString() {
    return 'AuthorDtoModel(id: $id, firstName: $firstName, lastName: $lastName, image: $image)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthorDtoModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
