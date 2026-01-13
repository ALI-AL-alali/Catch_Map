import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String baseUrl = "https://search.gocab.org";
  static const String apiKey =
      "af54352b6a36c2b66a54b813bdac6e16985d03d98eb9437d83c3ce0619e719ee";

  static Future<List<Map<String, dynamic>>> searchLocation(String query) async {
    final uri = Uri.parse("$baseUrl/search").replace(
      queryParameters: {
        'q': query,
        'format': 'json',
        'limit': '8',
        'accept-language': 'ar',
      },
    );

    final response = await http.get(uri, headers: {'X-API-Key': apiKey});
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }
}
