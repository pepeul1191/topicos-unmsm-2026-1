// lib/models/car_details.dart

import 'car.dart';
import 'technical_review.dart';
import 'infraction.dart';
import 'complain.dart';

class CarDetails {
  final Car car;
  final List<TechnicalReview> technicalReviews;
  final List<Infraction> infractions;
  final List<Complain> complains;

  CarDetails({
    required this.car,
    required this.technicalReviews,
    required this.infractions,
    required this.complains,
  });

  // Mapea todo el JSON compuesto que devuelve tu servidor
  factory CarDetails.fromJson(Map<String, dynamic> json) {
    return CarDetails(
      car: Car.fromJson(json['car'] as Map<String, dynamic>),
      
      // Mapeo seguro de listas por si vienen vacías []
      technicalReviews: (json['technical_reviews'] as List? ?? [])
          .map((item) => TechnicalReview.fromJson(item as Map<String, dynamic>))
          .toList(),
          
      infractions: (json['infractions'] as List? ?? [])
          .map((item) => Infraction.fromJson(item as Map<String, dynamic>))
          .toList(),
          
      complains: (json['complains'] as List? ?? [])
          .map((item) => Complain.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  // Por si necesitas enviar toda la estructura de vuelta o guardarla en caché local
  Map<String, dynamic> toJson() {
    return {
      'car': car.toJson(),
      'technical_reviews': technicalReviews.map((item) => item.toJson()).toList(),
      'infractions': infractions.map((item) => item.toJson()).toList(),
      'complains': complains.map((item) => item.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'CarDetails(car: ${car.plate}, reviews: ${technicalReviews.length}, infractions: ${infractions.length}, complains: ${complains.length})';
  }
}