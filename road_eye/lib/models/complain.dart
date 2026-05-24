// lib/models/complain.dart

class Complain {
  final int? id;
  final String description;
  final int carId;
  final DateTime? created;

  Complain({
    this.id,
    required this.description,
    required this.carId,
    this.created,
  });

  factory Complain.fromJson(Map<String, dynamic> json) {
    return Complain(
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
    return 'Complain(id: $id, description: $description, carId: $carId, created: $created)';
  }
}