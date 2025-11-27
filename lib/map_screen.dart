import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer();

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  late AnimationController polyAnimController;
  List<LatLng> animatedRoute = [];

  LatLng? startPoint;
  LatLng? endPoint;

  String distance = "";
  String duration = "";

  static final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(33.5138, 36.2765),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();

    polyAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    polyAnimController.addListener(() {
      if (_polylines.isEmpty) return;
      final points = _polylines.first.points;
      double t = Curves.easeInOut.transform(polyAnimController.value);
      int count = (points.length * t).floor();
      if (count < 2) return;

      setState(() {
        animatedRoute = points.sublist(0, count);
      });
    });
  }

  @override
  void dispose() {
    polyAnimController.dispose();
    super.dispose();
  }

  BitmapDescriptor startIcon = BitmapDescriptor.defaultMarkerWithHue(
    BitmapDescriptor.hueGreen,
  );
  BitmapDescriptor endIcon = BitmapDescriptor.defaultMarkerWithHue(
    BitmapDescriptor.hueRed,
  );

  void _addMarker(LatLng pos) {
    setState(() {
      if (startPoint == null) {
        // نقطة البداية
        startPoint = pos;
        _markers.add(
          Marker(
            markerId: const MarkerId('start'),
            position: pos,
            icon: startIcon,
            infoWindow: const InfoWindow(title: 'نقطة البداية'),
          ),
        );
      } else if (endPoint == null) {
        endPoint = pos;
        _markers.add(
          Marker(
            markerId: const MarkerId('end'),
            position: pos,
            icon: endIcon,
            infoWindow: const InfoWindow(title: 'نقطة النهاية'),
          ),
        );
        _getRoute();
      } else {
        _markers.clear();
        _polylines.clear();
        animatedRoute.clear();

        startPoint = pos;
        endPoint = null;
        distance = "";
        duration = "";

        _markers.add(
          Marker(
            markerId: const MarkerId('start'),
            position: pos,
            icon: startIcon,
            infoWindow: const InfoWindow(title: 'نقطة البداية'),
          ),
        );
      }
    });
  }

  Future<void> _getRoute() async {
    if (startPoint == null || endPoint == null) return;

    final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/'
      '${startPoint!.longitude},${startPoint!.latitude};'
      '${endPoint!.longitude},${endPoint!.latitude}?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode != 200) {
        _showError('خطأ: ${response.statusCode}');
        return;
      }

      final data = jsonDecode(response.body);
      final route = data['routes'][0];

      distance = "${(route['distance'] / 1000).toStringAsFixed(2)} كم";
      duration = "${(route['duration'] / 60).toStringAsFixed(0)} دقيقة";

      final coords = route['geometry']['coordinates'] as List;
      List<LatLng> points = coords.map((c) => LatLng(c[1], c[0])).toList();

      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: Colors.black,
            width: 4,
          ),
        );
      });

      animatedRoute.clear();
      polyAnimController.forward(from: 0);
    } catch (e) {
      _showError("فشل: $e");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Map OSRM Route')),
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: _markers,
        polylines: {
          if (animatedRoute.isNotEmpty)
            Polyline(
              polylineId: const PolylineId("animated"),
              points: animatedRoute,
              width: 4,
              color: Colors.black,
            ),
        },
        onTap: _addMarker,
        myLocationEnabled: true,
        zoomControlsEnabled: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showInfo,
        child: const Icon(Icons.info),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  void _showInfo() {
    if (startPoint == null || endPoint == null) {
      _showError("حدد نقطتين أولاً");
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text(
            "معلومات الطريق",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("المسافة: $distance"),
            const SizedBox(height: 8),
            Text("المدة: $duration"),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("حسناً"),
            ),
          ),
        ],
      ),
    );
  }
}
