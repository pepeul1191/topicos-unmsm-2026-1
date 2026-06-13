// lib/models/detector_config.dart
class DetectorConfig {
  final String model;
  final String sourceType;
  final String source;

  DetectorConfig({
    required this.model,
    required this.sourceType,
    required this.source,
  });

  Map<String, String> toQueryParams() {
    return {
      'tipo_fuente': sourceType,
      'fuente': source,
      'modelo': model,
    };
  }

  @override
  String toString() {
    return 'DetectorConfig(model: $model, sourceType: $sourceType, source: $source)';
  }
}