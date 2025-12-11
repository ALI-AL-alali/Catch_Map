import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'package:map/core/const/endpoint.dart';


class AuthApi {
  static Future<User> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(EndPoint.login),
      headers: {
        "Accept": "application/json",
      },
      body: {
        "email": email,
        "password": password,
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return User.fromJson(data);
    } else {
      throw Exception(data["message"] ?? "حدث خطأ أثناء تسجيل الدخول");
    }
  }
}
