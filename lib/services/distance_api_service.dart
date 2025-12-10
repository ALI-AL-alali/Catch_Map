import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:map/core/const/endpoint.dart';
import '../models/distance_result_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DistanceApiService {
  Future<DistanceResult?> getDistance({
    required LatLng from,
    required LatLng to,
  }) async {
    try {
      final url = Uri.parse(EndPoint.distance);

      final request = http.Request("GET", url);
      request.headers["Content-Type"] = "application/json";
      request.body = jsonEncode({
        "from_lat": from.latitude,
        "from_lng": from.longitude,
        "to_lat": to.latitude,
        "to_lng": to.longitude,
      });

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      print("STATUS: ${res.statusCode}");
      print("BODY: ${res.body}");

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      return DistanceResult.fromJson(data);
    } catch (e) {
      return null;
    }
  }
}
