class User {
  final int userId;
  final String userType;
  final String token;

  User({
    required this.userId,
    required this.userType,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json["user_id"],
      userType: json["user_type"],
      token: json["token"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "user_id": userId,
      "user_type": userType,
      "token": token,
    };
  }
}
