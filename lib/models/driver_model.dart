class DriverModel {
  final bool success;
  final int count;
  final List<DriverData> data;

  DriverModel({
    required this.success,
    required this.count,
    required this.data,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      success: json['success'],
      count: json['count'],
      data: List<DriverData>.from(
        json['data'].map((x) => DriverData.fromJson(x)),
      ),
    );
  }
}

class DriverData {
  final int id;
  final int userId;
  final double? currentLat;
  final double? currentLng;
  final String vehicleType;
  final String vehiclePlate;
  final String status;
  final bool isApproved;
  final String createdAt;
  final String updatedAt;
  final User user;

  DriverData({
    required this.id,
    required this.userId,
    required this.currentLat,
    required this.currentLng,
    required this.vehicleType,
    required this.vehiclePlate,
    required this.status,
    required this.isApproved,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
  });

  factory DriverData.fromJson(Map<String, dynamic> json) {
    return DriverData(
      id: json['id'],
      userId: json['user_id'],
      currentLat: json['current_lat'] != null
          ? (json['current_lat'] as num).toDouble()
          : null,
      currentLng: json['current_lng'] != null
          ? (json['current_lng'] as num).toDouble()
          : null,
      vehicleType: json['vehicle_type'],
      vehiclePlate: json['vehicle_plate'],
      status: json['status'],
      isApproved: json['is_approved'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      user: User.fromJson(json['user']),
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final String role;
  final String phone;
  final String createdAt;
  final String updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.emailVerifiedAt,
    required this.role,
    required this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      emailVerifiedAt: json['email_verified_at'],
      role: json['role'],
      phone: json['phone'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
