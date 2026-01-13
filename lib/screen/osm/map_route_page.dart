// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:http/http.dart' as http;
// import 'package:latlong2/latlong.dart';

// class MapRoutePage extends StatelessWidget {
//   final String startPoint;
//   final String endPoint;
//   final double startLatitude;
//   final double startLongitude;
//   final double endLatitude;
//   final double endLongitude;

//   const MapRoutePage({
//     super.key,
//     required this.startPoint,
//     required this.endPoint,
//     required this.startLatitude,
//     required this.startLongitude,
//     required this.endLatitude,
//     required this.endLongitude,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("المسار")),
//       body: FutureBuilder<List<LatLng>>(
//         future: _getRoute(
//           startLatitude,
//           startLongitude,
//           endLatitude,
//           endLongitude,
//         ),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text("حدث خطأ"));
//           }

//           final routePoints = snapshot.data ?? [];

//           return FlutterMap(
//             options: MapOptions(
//               initialCenter: routePoints.isNotEmpty
//                   ? routePoints.first
//                   : const LatLng(33.5138, 36.2765),
//               initialZoom: 13,
//             ),
//             children: [
//               TileLayer(
//                 urlTemplate: "https://tiles.gocab.org/tile/{z}/{x}/{y}.png",
//               ),
//               PolylineLayer(
//                 polylines: [
//                   Polyline(
//                     points: routePoints,
//                     color: Colors.blue,
//                     strokeWidth: 5,
//                   ),
//                 ],
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Future<List<LatLng>> _getRoute(
//     double startLat,
//     double startLon,
//     double endLat,
//     double endLon,
//   ) async {
//     final url =
//         "http://route.gocab.org/route/v1/driving/$startLon,$startLat;$endLon,$endLat?overview=full&steps=true&geometries=geojson";
//     final response = await http.get(Uri.parse(url));

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       final coords = data["routes"][0]["geometry"]["coordinates"] as List;
//       return coords.map<LatLng>((coord) => LatLng(coord[1], coord[0])).toList();
//     } else {
//       throw Exception('Failed to load route');
//     }
//   }
// }
