// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';
// import 'package:flutter_tts/flutter_tts.dart';

// const String kTileBaseUrl = 'https://tiles.gocab.org/tile';
// const String nominatimBaseUrl = "https://search.gocab.org";
// const String nominatimApiKey =
//     "af54352b6a36c2b66a54b813bdac6e16985d03d98eb9437d83c3ce0619e719ee";
// const String osrmBaseUrl = "http://route.gocab.org/route/v1/driving";

// class OsmMapPage extends StatefulWidget {
//   const OsmMapPage({super.key});

//   @override
//   State<OsmMapPage> createState() => _OsmMapPageState();
// }

// class _OsmMapPageState extends State<OsmMapPage> {
//   // ======== Map & Zoom ========
//   final MapController mapController = MapController();
//   double _zoom = 13.0;
//   bool _showTileWarning = false;
//   String _tileWarningText = '';
//   DateTime _lastSnackTime = DateTime.fromMillisecondsSinceEpoch(0);
//   Timer? _warningTimer;

//   // ======== Search ========
//   final TextEditingController searchController = TextEditingController();
//   Timer? _debounce;
//   List<Map<String, dynamic>> searchResults = [];
//   bool searchLoading = false;
//   LatLng? selectedPoint;
//   String? selectedName;

//   // ======== Route / Trip ========
//   final FlutterTts tts = FlutterTts();
//   LatLng? startPoint;
//   LatLng? endPoint;
//   List<LatLng> routePoints = [];
//   String distanceText = "";
//   String durationText = "";
//   bool tripStarted = false;
//   int currentStepIndex = 0;
//   Timer? stepTimer;
//   double speedKmh = 50.0;

//   // ======== From/To Controllers ========a
//   final TextEditingController fromCoordsController = TextEditingController();
//   final TextEditingController toCoordsController = TextEditingController();
//   bool selectingFrom = true;

//   @override
//   void initState() {
//     super.initState();
//     _initTts();
//   }

//   Future<void> _initTts() async {
//     await tts.setLanguage("ar-SA");
//     await tts.setPitch(1.0);
//     await tts.setSpeechRate(0.92);
//     await tts.setVolume(0.95);
//     await tts.awaitSpeakCompletion(true);
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     _warningTimer?.cancel();
//     stepTimer?.cancel();
//     searchController.dispose();
//     fromCoordsController.dispose();
//     toCoordsController.dispose();
//     tts.stop();
//     super.dispose();
//   }

//   // ================= Tile Error =================
//   void _onTileError(TileImage tile, Object error) {
//     final z = tile.coordinates.z;
//     final x = tile.coordinates.x;
//     final y = tile.coordinates.y;
//     final msg = 'فشل تحميل التايل (z=$z x=$x y=$y) — خطأ شبكة/سيرفر';

//     setState(() {
//       _showTileWarning = true;
//       _tileWarningText = msg;
//     });

//     _warningTimer?.cancel();
//     _warningTimer = Timer(const Duration(seconds: 4), () {
//       if (mounted) setState(() => _showTileWarning = false);
//     });

//     final now = DateTime.now();
//     if (now.difference(_lastSnackTime) >= const Duration(seconds: 3)) {
//       _lastSnackTime = now;
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
//         );
//       }
//     }
//     debugPrint('Tile error z=$z x=$x y=$y -> $error');
//   }

//   // ================= Search =================
//   void onSearchChanged(String value) {
//     _debounce?.cancel();
//     _debounce = Timer(const Duration(milliseconds: 350), () async {
//       if (value.trim().isEmpty) return;
//       setState(() => searchLoading = true);

//       final uri = Uri.parse("$nominatimBaseUrl/search").replace(
//         queryParameters: {
//           "q": value,
//           "format": "json",
//           "limit": "8",
//           "accept-language": "ar",
//         },
//       );

//       try {
//         final res = await http.get(
//           uri,
//           headers: {"X-API-Key": nominatimApiKey},
//         );
//         if (res.statusCode == 200) {
//           searchResults = (jsonDecode(res.body) as List)
//               .cast<Map<String, dynamic>>();
//         } else {
//           searchResults = [];
//         }
//       } catch (_) {
//         searchResults = [];
//       }

//       setState(() => searchLoading = false);
//     });
//   }

//   void selectSearchResult(Map<String, dynamic> item) {
//     final lat = double.parse(item["lat"]);
//     final lon = double.parse(item["lon"]);
//     final point = LatLng(lat, lon);

//     final fullName = item["display_name"] ?? "موقع غير معروف";
//     final parts = fullName.split(',');
//     final shortName = parts.length >= 2
//         ? "${parts[0].trim()} ، ${parts[1].trim()}"
//         : fullName;

//     setState(() {
//       selectedPoint = point;
//       selectedName = shortName;
//       searchResults.clear();
//       searchController.clear();
//     });

//     mapController.move(point, 16);
//   }

//   // ================= Reverse Geocoding =================
//   Future<void> reverseGeocode(LatLng point) async {
//     final uri = Uri.parse("$nominatimBaseUrl/reverse").replace(
//       queryParameters: {
//         "lat": point.latitude.toString(),
//         "lon": point.longitude.toString(),
//         "format": "json",
//         "accept-language": "ar",
//       },
//     );

//     try {
//       final res = await http.get(uri, headers: {"X-API-Key": nominatimApiKey});
//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final fullName = data["display_name"] ?? "موقع غير معروف";
//         final parts = fullName.split(',');
//         final shortName = parts.length >= 2
//             ? "${parts[0].trim()} ، ${parts[1].trim()}"
//             : fullName;
//         if (!mounted) return;
//         setState(() => selectedName = shortName);
//       } else {
//         setState(() => selectedName = "موقع غير معروف");
//       }
//     } catch (_) {
//       setState(() => selectedName = "فشل جلب العنوان");
//     }
//   }

//   // ================= Route =================
//   Future<void> getRoute() async {
//     if (startPoint == null || endPoint == null) return;

//     final url =
//         "$osrmBaseUrl/"
//         "${startPoint!.longitude},${startPoint!.latitude};"
//         "${endPoint!.longitude},${endPoint!.latitude}"
//         "?overview=full&steps=true&geometries=geojson";

//     try {
//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode != 200) return;

//       final data = jsonDecode(response.body);
//       if (data["code"] != "Ok") return;

//       final route = data["routes"][0];
//       final distance = (route["distance"] as num);
//       final duration = (route["duration"] as num);

//       distanceText = "${(distance / 1000).toStringAsFixed(2)} كم";
//       durationText = "${(duration / 60).toStringAsFixed(0)} دقيقة";

//       final coords = route["geometry"]["coordinates"] as List;
//       routePoints = coords
//           .map(
//             (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
//           )
//           .toList();

//       if (routePoints.isNotEmpty) {
//         final bounds = LatLngBounds.fromPoints(routePoints);
//         mapController.fitCamera(
//           CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
//         );
//       }

//       setState(() {});
//     } catch (e) {
//       print("Error fetching route: $e");
//     }
//   }

//   void startTrip() async {
//     if (routePoints.isEmpty) return;
//     stepTimer?.cancel();
//     tripStarted = true;
//     setState(() {});
//     if (tts != null) await tts.speak("تم بدء الرحلة.");
//   }

//   void resetTrip() {
//     stepTimer?.cancel();
//     tripStarted = false;
//     setState(() {});
//   }

//   // ================= Map UI =================
//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text("الخريطة الشاملة"),
//           backgroundColor: Colors.deepPurple,
//         ),
//         body: Stack(
//           children: [
//             // ================= MAP =================
//             FlutterMap(
//               mapController: mapController,
//               options: MapOptions(
//                 initialCenter: const LatLng(33.5138, 36.2765),
//                 initialZoom: _zoom,
//                 minZoom: 1,
//                 maxZoom: 22,
//                 onPositionChanged: (pos, _) {
//                   setState(() => _zoom = pos.zoom);
//                 },
//                 onTap: (_, p) async {
//                   if (selectingFrom) {
//                     setState(() {
//                       startPoint = p;
//                       fromCoordsController.text =
//                           "${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}";
//                     });
//                   } else {
//                     setState(() {
//                       endPoint = p;
//                       toCoordsController.text =
//                           "${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}";
//                     });
//                   }
//                   selectedPoint = p;
//                   selectedName = null;
//                   await reverseGeocode(p);
//                 },
//               ),
//               children: [
//                 TileLayer(
//                   urlTemplate: '$kTileBaseUrl/{z}/{x}/{y}.png',
//                   errorTileCallback: (tile, error, stackTrace) {
//                     _onTileError(tile, error);
//                   },
//                 ),
//                 PolylineLayer<Object>(
//                   polylines: routePoints.isNotEmpty
//                       ? [
//                           Polyline<Object>(
//                             points: routePoints,
//                             color: Colors.black,
//                             strokeWidth: 4,
//                           ),
//                         ]
//                       : [],
//                 ),

//                 MarkerLayer(
//                   markers: [
//                     if (startPoint != null)
//                       Marker(
//                         point: startPoint!,
//                         width: 40,
//                         height: 40,
//                         child: const Icon(
//                           Icons.location_pin,
//                           color: Colors.green,
//                           size: 40,
//                         ),
//                       ),
//                     if (endPoint != null)
//                       Marker(
//                         point: endPoint!,
//                         width: 40,
//                         height: 40,
//                         child: Icon(Icons.flag, color: Colors.red, size: 40),
//                       )
//                     else if (selectedPoint != null)
//                       Marker(
//                         point: selectedPoint!,
//                         width: 40,
//                         height: 40,
//                         child: const Icon(
//                           Icons.location_on,
//                           color: Colors.orange,
//                           size: 36,
//                         ),
//                       ),
//                   ],
//                 ),
//               ],
//             ),

//             // ================= Search UI =================
//             Positioned(
//               top: 16,
//               left: 12,
//               right: 12,
//               child: Card(
//                 elevation: 6,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Column(
//                   children: [
//                     TextField(
//                       controller: searchController,
//                       onChanged: onSearchChanged,
//                       decoration: InputDecoration(
//                         hintText: "ابحث عن أي مكان...",
//                         prefixIcon: const Icon(Icons.search),
//                         filled: true,
//                         fillColor: Colors.white,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(14),
//                           borderSide: BorderSide.none,
//                         ),
//                       ),
//                     ),
//                     if (searchLoading) const LinearProgressIndicator(),
//                     if (searchResults.isNotEmpty)
//                       ListView.builder(
//                         itemCount: searchResults.length,
//                         itemBuilder: (_, i) {
//                           final item = searchResults[i];
//                           return ListTile(
//                             title: Text(item["display_name"] ?? ""),
//                             onTap: () => selectSearchResult(item),
//                           );
//                         },
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
