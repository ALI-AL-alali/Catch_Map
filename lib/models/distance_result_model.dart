class DistanceResult {
  final int id;
  final int fromId;
  final int toId;
  final String distanceKm;
  final String durationMin;

  final String method;
  final String createdAt;

  final String fromName;
  final String toName;

  DistanceResult({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.distanceKm,
    required this.durationMin,
    required this.method,
    required this.createdAt,
    required this.fromName,
    required this.toName,
  });

  factory DistanceResult.fromJson(Map<String, dynamic> json) {
    return DistanceResult(
      id: json["id"],
      fromId: json["from_location_id"],
      toId: json["to_location_id"],
      distanceKm: json["distance_km"],
      durationMin: json["duration_min"],
      method: json["calculation_method"],
      createdAt: json["calculated_at"],
      fromName: json["from_name"],
      toName: json["to_name"],
    );
  }
}
