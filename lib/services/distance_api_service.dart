import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/distance_result_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DistanceApiService {
  static const String baseUrl = "http://192.168.100.69:8000/distance-result";

  Future<DistanceResult?> getDistance({
    required LatLng from,
    required LatLng to,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "from_lat": from.latitude,
          "from_lng": from.longitude,
          "to_lat": to.latitude,
          "to_lng": to.longitude,
        }),
      );

      print(res.body);

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      return DistanceResult.fromJson(data);
    } catch (e) {
      return null;
    }
  }
}
