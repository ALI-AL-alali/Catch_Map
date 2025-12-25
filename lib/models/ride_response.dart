class RideCreateResponse {
  final bool success;
  final String message;
  final RideData data;

  RideCreateResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory RideCreateResponse.fromJson(Map<String, dynamic> json) {
    return RideCreateResponse(
      success: json['success'],
      message: json['message'],
      data: RideData.fromJson(json['data']),
    );
  }
}

class RideData {
  final int rideId;
  final String rideNumber;
  final String status;
  final String pickupAddress;
  final String dropoffAddress;
  final String distance;
  final int estimatedDuration;
  final String estimatedPrice;
  final String requestedAt;

  RideData({
    required this.rideId,
    required this.rideNumber,
    required this.status,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.distance,
    required this.estimatedDuration,
    required this.estimatedPrice,
    required this.requestedAt,
  });

  factory RideData.fromJson(Map<String, dynamic> json) {
    return RideData(
      rideId: json['ride_id'],
      rideNumber: json['ride_number'],
      status: json['status'],
      pickupAddress: json['pickup_address'],
      dropoffAddress: json['dropoff_address'],
      distance: json['distance'],
      estimatedDuration: json['estimated_duration'],
      estimatedPrice: json['estimated_price'],
      requestedAt: json['requested_at'],
    );
  }
}
