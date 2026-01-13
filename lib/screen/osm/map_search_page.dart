import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapSearchPage extends StatefulWidget {
  const MapSearchPage({super.key});

  @override
  State<MapSearchPage> createState() => _MapSearchPageState();
}

class _MapSearchPageState extends State<MapSearchPage> {
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();

  LatLng? selectedPoint;
  String? selectedName;
  double currentZoom = 15.0;

  Timer? debounce;
  List<Map<String, dynamic>> searchResults = [];
  bool loading = false;

  static const String tilesUrlTemplate =
      "https://tiles.gocab.org/tile/{z}/{x}/{y}.png";

  static const String nominatimBaseUrl = "https://search.gocab.org";
  static const String nominatimApiKey =
      "af54352b6a36c2b66a54b813bdac6e16985d03d98eb9437d83c3ce0619e719ee";

  // ===================== SEARCH =====================
  void onSearchChanged(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 350), () async {
      if (value.trim().isEmpty) return;
      setState(() => loading = true);

      final uri = Uri.parse("$nominatimBaseUrl/search").replace(
        queryParameters: {
          "q": value,
          "format": "json",
          "limit": "8",
          "accept-language": "ar",
        },
      );

      final res = await http.get(uri, headers: {"X-API-Key": nominatimApiKey});

      if (res.statusCode == 200) {
        searchResults = (jsonDecode(res.body) as List)
            .cast<Map<String, dynamic>>();
      } else {
        searchResults = [];
      }

      setState(() => loading = false);
    });
  }

  void selectSearchResult(Map<String, dynamic> item) {
    final lat = double.parse(item["lat"]);
    final lon = double.parse(item["lon"]);
    final point = LatLng(lat, lon);

    final fullName = item["display_name"] ?? "موقع غير معروف";
    final parts = fullName.split(',');
    final shortName = parts.length >= 2
        ? "${parts[0].trim()} ، ${parts[1].trim()}"
        : fullName;

    setState(() {
      selectedPoint = point;
      selectedName = shortName;
      searchResults.clear();
      searchController.clear();
    });

    mapController.move(point, 16);
  }

  // ===================== REVERSE GEOCODING =====================
  Future<void> reverseGeocode(LatLng point) async {
    final uri = Uri.parse("$nominatimBaseUrl/reverse").replace(
      queryParameters: {
        "lat": point.latitude.toString(),
        "lon": point.longitude.toString(),
        "format": "json",
        "accept-language": "ar",
      },
    );

    try {
      final res = await http.get(uri, headers: {"X-API-Key": nominatimApiKey});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final fullName = data["display_name"] ?? "موقع غير معروف";

        final parts = fullName.split(',');
        final shortName = parts.length >= 2
            ? "${parts[0].trim()} ، ${parts[1].trim()}"
            : fullName;

        if (!mounted) return;
        setState(() => selectedName = shortName);
      } else {
        setState(() => selectedName = "موقع غير معروف");
      }
    } catch (_) {
      setState(() => selectedName = "فشل جلب العنوان");
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    debounce?.cancel();
    super.dispose();
  }

  // ===================== NAVIGATION =====================
  void completeSelection() {
    if (selectedPoint != null && selectedName != null) {
      Navigator.pop(context, {
        'name': selectedName,
        'latitude': selectedPoint!.latitude,
        'longitude': selectedPoint!.longitude,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("خريطة + بحث"),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Card(
                color: Colors.black.withOpacity(0.7),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    "Zoom ${currentZoom.toStringAsFixed(1)}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: const LatLng(33.5138, 36.2765),
                initialZoom: currentZoom,
                minZoom: 3,
                maxZoom: 19,
                onPositionChanged: (pos, _) {
                  setState(() => currentZoom = pos.zoom);
                },
                onTap: (_, p) async {
                  setState(() {
                    selectedPoint = p;
                    selectedName = null;
                  });
                  await reverseGeocode(p);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: tilesUrlTemplate,
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: [
                    if (selectedPoint != null)
                      Marker(
                        point: selectedPoint!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // ===================== SEARCH UI =====================
            Positioned(
              top: 16,
              left: 12,
              right: 12,
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "ابحث عن أي مكان...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (loading) const LinearProgressIndicator(),
                  if (searchResults.isNotEmpty)
                    Container(
                      height: 180,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (_, i) {
                          final item = searchResults[i];
                          return ListTile(
                            title: Text(
                              item["display_name"] ?? "",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => selectSearchResult(item),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // ===================== INFO CARD =====================
            if (selectedPoint != null && selectedName != null)
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedName!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "الإحداثيات: ${selectedPoint!.latitude.toStringAsFixed(5)}, ${selectedPoint!.longitude.toStringAsFixed(5)}",
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.copy),
                            label: const Text("نسخ الإحداثيات"),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(
                                  text:
                                      "${selectedPoint!.latitude}, ${selectedPoint!.longitude}",
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("تم نسخ الإحداثيات"),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        // "إتمام" Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: completeSelection,
                            child: const Text("إتمام"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
