class PlanTag {
  final String id;
  final String name;
  final String? image;
  final String? imageKey;
  final String? description;

  const PlanTag({
    required this.id,
    required this.name,
    this.image,
    this.imageKey,
    this.description,
  });

  factory PlanTag.fromJson(Map<String, dynamic> json) {
    return PlanTag(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String?,
      imageKey: json['image_key'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'image_key': imageKey,
      'description': description,
    };
  }
}
