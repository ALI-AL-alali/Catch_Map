class User {
  final int userId;
  final String userType;
  final String token;
  final String name;

  User({
    required this.userId,
    required this.userType,
    required this.token,
    required this.name,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json["user_id"],
      userType: json["user_type"],
      token: json["token"],
      name: json["name"],
    );
  }

  Map<String, dynamic> toJson() {
    return {"user_id": userId, "user_type": userType, "token": token};
  }
}
