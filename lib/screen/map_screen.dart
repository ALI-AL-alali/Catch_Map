import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../services/graphhopper_service.dart';
import '../../services/distance_api_service.dart';
import '../../models/distance_result_model.dart';
import '../widgets/route_card.dart';

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

  DistanceResult? serverResult;

  String graphDistance = "";
  String graphDuration = "";

  final graphhopper = GraphHopperService();
  final apiService = DistanceApiService();

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(33.5138, 36.2765),
    zoom: 14,
  );

  BitmapDescriptor startIcon = BitmapDescriptor.defaultMarkerWithHue(
    BitmapDescriptor.hueGreen,
  );
  BitmapDescriptor endIcon = BitmapDescriptor.defaultMarkerWithHue(
    BitmapDescriptor.hueRed,
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
      int count = (_polylines.first.points.length * polyAnimController.value)
          .floor();
      if (count < 2) return;
      setState(() => animatedRoute = _polylines.first.points.sublist(0, count));
    });
  }

  @override
  void dispose() {
    polyAnimController.dispose();
    super.dispose();
  }

  void _addMarker(LatLng pos) async {
    setState(() {
      if (startPoint == null) {
        startPoint = pos;
        _markers.add(
          Marker(
            markerId: const MarkerId('start'),
            position: pos,
            icon: startIcon,
          ),
        );
      } else if (endPoint == null) {
        endPoint = pos;
        _markers.add(
          Marker(markerId: const MarkerId('end'), position: pos, icon: endIcon),
        );
        _getGraphhopperRoute();
        _getServerDistance();
      } else {
        _markers.clear();
        _polylines.clear();
        animatedRoute.clear();
        startPoint = pos;
        endPoint = null;
        serverResult = null;
        graphDistance = "";
        graphDuration = "";
        _markers.add(
          Marker(
            markerId: const MarkerId('start'),
            position: pos,
            icon: startIcon,
          ),
        );
      }
    });
  }

  Future<void> _getGraphhopperRoute() async {
    if (startPoint == null || endPoint == null) return;

    final data = await graphhopper.getRoute(start: startPoint!, end: endPoint!);
    if (data == null) return;

    final path = data["paths"][0];
    graphDistance = "${(path["distance"] / 1000).toStringAsFixed(2)} كم";
    graphDuration = "${(path["time"] / 60000).toStringAsFixed(0)} دقيقة";

    List coords = path["points"]["coordinates"];
    List<LatLng> polyPoints = coords.map((c) => LatLng(c[1], c[0])).toList();

    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: polyPoints,
          color: Colors.black,
          width: 4,
        ),
      );
    });

    animatedRoute.clear();
    polyAnimController.forward(from: 0);
  }

  Future<void> _getServerDistance() async {
    if (startPoint == null || endPoint == null) return;

    final result = await apiService.getDistance(
      from: startPoint!,
      to: endPoint!,
    );
    if (result != null) setState(() => serverResult = result);
  }

  void _confirmTrip() {
    if (startPoint != null && endPoint != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تم تأكيد الرحلة")));
      // إضافة أي منطق إرسال الرحلة هنا
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("حدد نقطتين على الخريطة")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (controller) => _controller.complete(controller),
            markers: _markers,
            polylines: {
              if (animatedRoute.isNotEmpty)
                Polyline(
                  polylineId: const PolylineId('animate'),
                  points: animatedRoute,
                  width: 4,
                  color: Colors.black,
                ),
            },
            onTap: _addMarker,
            myLocationEnabled: true,
            zoomControlsEnabled: true,
          ),
          if (serverResult != null)
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: RouteCard(
                fromName: serverResult!.fromName,
                toName: serverResult!.toName,
                distance: serverResult!.distanceKm,
                duration: serverResult!.durationMin,
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton(
          onPressed: _confirmTrip,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "تأكيد الرحلة",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
