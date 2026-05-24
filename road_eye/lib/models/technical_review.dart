//lib/models/technical_review.dart

class TechnicalReview {
  final int? id;
  final String description;
  final int carId;
  final DateTime? created;

  TechnicalReview({
    this.id,
    required this.description,
    required this.carId,
    this.created,
  });

  factory TechnicalReview.fromJson(Map<String, dynamic> json) {
    return TechnicalReview(
      id: json['id'] as int?,
      description: json['description'] as String,
      carId: json['car_id'] as int,
      created: json['created'] != null 
          ? DateTime.parse(json['created'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'description': description,
      'car_id': carId,
    };
    if (id != null) data['id'] = id;
    if (created != null) data['created'] = created!.toIso8601String();
    return data;
  }

  @override
  String toString() {
    return 'TechnicalReview(id: $id, description: $description, carId: $carId, created: $created)';
  }
}