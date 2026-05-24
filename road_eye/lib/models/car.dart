// lib/models/car.dart

class Car {
  final int? id;
  final String owner;
  final String branch;
  final String model;
  final String color;
  final int fabricated;
  final String plate;

  Car({
    this.id,
    required this.owner,
    required this.branch,
    required this.model,
    required this.color,
    required this.fabricated,
    required this.plate,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] as int?,
      owner: json['owner'] as String,
      branch: json['branch'] as String,
      model: json['model'] as String,
      color: json['color'] as String,
      fabricated: json['frabricated'] as int, 
      plate: json['plate'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'owner': owner,
      'branch': branch,
      'model': model,
      'color': color,
      'frabricated': fabricated,
      'plate': plate,
    };
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }

  @override
  String toString() {
    return 'Car(id: $id, owner: $owner, branch: $branch, model: $model, color: $color, fabricated: $fabricated, plate: $plate)';
  }
}