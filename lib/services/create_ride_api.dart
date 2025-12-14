import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/const/endpoint.dart';

class RideApiService {
  Future<void> createRide({
    required String startAddress,
    required String endAddress,
    required double distance,
    required int estimatedDuration,
    required dynamic estimatedPrice,
  }) async {
    try {
      final url = Uri.parse(EndPoint.ride);

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization":"Bearer ${token}",

        },
        body: jsonEncode({
          "pickup_address": startAddress,
          "dropoff_address": endAddress,
          "distance": distance,
          "estimated_duration": estimatedDuration,
          "estimated_price": estimatedPrice,
        }),
      );

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Failed to create ride");
      }
    } catch (e) {
      print("ERROR: $e");
      rethrow; // مهم إذا بدك تتعامل مع الخطأ فوق
    }
  }
}
