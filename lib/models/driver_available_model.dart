class AvailableDriversResponse {
  final bool success;
  final String message;
  final Meta meta;
  final List<DriverItem> data;

  AvailableDriversResponse({
    required this.success,
    required this.message,
    required this.meta,
    required this.data,
  });

  factory AvailableDriversResponse.fromJson(Map<String, dynamic> json) {
    return AvailableDriversResponse(
      success: json['success'],
      message: json['message'],
      meta: Meta.fromJson(json['meta']),
      data: (json['data'] as List)
          .map((e) => DriverItem.fromJson(e))
          .toList(),
    );
  }
}

class Meta {
  final int radiusKm;
  final int limit;
  final int totalFound;

  Meta({
    required this.radiusKm,
    required this.limit,
    required this.totalFound,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      radiusKm: json['radius_km'],
      limit: json['limit'],
      totalFound: json['total_found'],
    );
  }
}
class DriverItem {
  final Driver driver;
  final double distanceKm;
  final String estimatedArrival;

  DriverItem({
    required this.driver,
    required this.distanceKm,
    required this.estimatedArrival,
  });

  factory DriverItem.fromJson(Map<String, dynamic> json) {
    return DriverItem(
      driver: Driver.fromJson(json['driver']),
      distanceKm: (json['distance_km'] as num).toDouble(),
      estimatedArrival: json['estimated_arrival'],
    );
  }
}
class Driver {
  final int id;
  final int userId;
  final String name;
  final String phone;
  final String vehicleType;
  final String vehiclePlate;
  final DriverLocation location;
  final bool hasLocation;
  final String status;

  Driver({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.vehicleType,
    required this.vehiclePlate,
    required this.location,
    required this.hasLocation,
    required this.status,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      phone: json['phone'],
      vehicleType: json['vehicle_type'],
      vehiclePlate: json['vehicle_plate'],
      location: DriverLocation.fromJson(json['location']),
      hasLocation: json['has_location'],
      status: json['status'],
    );
  }
}

class DriverLocation {
  final double lat;
  final double lng;
  final DateTime updatedAt;

  DriverLocation({
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    return DriverLocation(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}



