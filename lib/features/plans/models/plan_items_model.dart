class PlanItemsModel {
  final String id;
  final String planId;
  final int dayNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PlanItemsModel({
    required this.id,
    required this.planId,
    required this.dayNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory PlanItemsModel.fromJson(Map<String, dynamic> json) {
    return PlanItemsModel(
      id: json['id'],
      planId: json['plan_id'],
      dayNumber: json['day_number'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'day_number': dayNumber,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
