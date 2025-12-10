class DistanceResult {
  final String fromName;
  final String toName;
  final String distanceKm;
  final String durationMin;
  final String method;
  final int calculated_price;
  DistanceResult({
    required this.fromName,
    required this.toName,
    required this.distanceKm,
    required this.durationMin,
    required this.method,
    required this.calculated_price,
  });

  factory DistanceResult.fromJson(Map<String, dynamic> json) {
    return DistanceResult(
      fromName: json["from_name"],
      toName: json["to_name"],
      distanceKm: json["distance_km"],
      durationMin: json["duration_min"],
      method: json["calculation_method"],
      calculated_price: json["calculated_price"],
    );
  }
}
