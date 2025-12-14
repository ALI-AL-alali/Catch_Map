import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:map/core/const/endpoint.dart';
import 'package:map/core/utils/cachenetwork.dart';
import 'package:map/models/user.dart';

class AuthApi {
  static Future<User?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(EndPoint.login),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"email": email, "password": password}),
      );

      final json = jsonDecode(response.body);

      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200 && json["success"] == true) {
        final data = json["data"];
        final user = User(
          userId: data["user"]["id"],
          userType: data["user"]["role"],
          token: data["token"],
          name: data["user"]["name"],
        );

        await Cachenetwork.insert("token", user.token);
        await Cachenetwork.insert("user_type", user.userType);
        await Cachenetwork.insert("user_id", user.userId.toString());

        token=Cachenetwork.getdata("token");
        print(token);

        return user;
      } else {
        return null;
      }
    } catch (e) {
      print("خطأ اتصال: $e");
      return null;
    }
  }
}
