import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GraphHopperService {
  final String apiKey = "4321bfb9-ba5b-40f7-9c39-45c3b84c5ca3";

  Future<Map<String, dynamic>?> getRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final url = Uri.parse(
      "https://graphhopper.com/api/1/route?"
      "point=${start.latitude},${start.longitude}"
      "&point=${end.latitude},${end.longitude}"
      "&profile=car"
      "&locale=ar"
      "&points_encoded=false"
      "&key=$apiKey",
    );

    try {
      final res = await http.get(url);
      if (res.statusCode != 200) return null;

      return jsonDecode(res.body);
    } catch (e) {
      return null;
    } 
  }
}
