import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/const/endpoint.dart';
import '../models/driver_model.dart';


Future<DriverModel?> fetchDrivers() async {
  try {
    final String apiUrl = Uri.parse(EndPoint.drivers).toString();

    final response = await http.get(Uri.parse(apiUrl),

      headers: {
      "Content-Type": "application/json",
      "Authorization":"Bearer ${token}",

      },);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      return DriverModel.fromJson(jsonData);
    } else {
      // لو صار خطأ من السيرفر
      print("Failed to load drivers: ${response.statusCode}");
      return null;
    }
  } catch (e) {
    print("Error fetching drivers: $e");
    return null;
  }
}
