import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gml;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// ====== your project imports ======
import 'package:map/core/helpers/socket_events.dart';
import 'package:map/core/utils/cachenetwork.dart';
import 'package:map/models/distance_result_model.dart';
import 'package:map/models/driver_model.dart';
import 'package:map/screen/get_driver_screen.dart';
import 'package:map/services/create_ride_api.dart';
import 'package:map/services/distance_api_service.dart';
import 'package:map/services/get_driver.dart';
import 'package:map/widgets/route_card.dart';

class MapRoutePage extends StatefulWidget {
  final String startPoint;
  final String endPoint;
  final double startLatitude;
  final double startLongitude;
  final double endLatitude;
  final double endLongitude;

  const MapRoutePage({
    super.key,
    required this.startPoint,
    required this.endPoint,
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
  });

  @override
  State<MapRoutePage> createState() => _MapRoutePageState();
}

class _MapRoutePageState extends State<MapRoutePage> {
  // ===== Map =====
  final MapController mapController = MapController();
  static const String tilesUrlTemplate =
      "https://tiles.gocab.org/tile/{z}/{x}/{y}.png";

  // نقاط الرحلة (ثابتة من HomePage)
  late final LatLng startLatLng;
  late final LatLng endLatLng;

  // Route
  List<LatLng> routePoints = [];
  bool loadingRoute = true;

  // ✅ NEW: route meta from OSRM
  double? routeDistanceMeters; // meters
  double? routeDurationSeconds; // seconds

  // Drivers (socket)
  Set<Marker> driverMarkers = {};
  bool showDriversOverlay = false;

  // Distance card
  DistanceResult? serverResult;

  // Services
  final SocketEvents socketEvents = SocketEvents();
  final DistanceApiService apiService = DistanceApiService();

  // Ride
  int? currentRideId;
  Timer? _locationTimer;

  // =========================
  // ✅ Helpers (Price/Format)
  // =========================
  static const int pricePerKm = 9000;

  int _estimatePriceFromMeters(double meters) {
    final km = meters / 1000.0;
    final raw = km * pricePerKm;

    // تقريب لطيف (اختياري) لأقرب 500
    final rounded = (raw / 500).round() * 500;
    return rounded.toInt();
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return "${meters.toStringAsFixed(0)} م";
    return "${(meters / 1000).toStringAsFixed(2)} كم";
  }

  String _formatDuration(double seconds) {
    final totalMinutes = (seconds / 60).round();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h <= 0) return "$m دقيقة";
    return "$h ساعة و $m دقيقة";
  }

  @override
  void initState() {
    super.initState();

    startLatLng = LatLng(widget.startLatitude, widget.startLongitude);
    endLatLng = LatLng(widget.endLatitude, widget.endLongitude);

    _loadRoute();
    _getServerDistance();

    _initSocket(); // ✅ جديد
  }

  bool _socketReady = false;

  Future<void> _initSocket() async {
    if (_socketReady) return;

    await socketEvents.openSocketCustomerConnection();
    _socketReady = true;

    socketEvents.listenToNearbyDrivers((drivers) {
      final markers = drivers.map<Marker>((driver) {
        final lat = ((driver['lat'] ?? driver['latitude']) as num).toDouble();
        final lng = ((driver['lng'] ?? driver['longitude']) as num).toDouble();

        return Marker(
          point: LatLng(lat, lng),
          width: 44,
          height: 44,
          child: const _DriverMarkerWidget(),
        );
      }).toSet();

      if (!mounted) return;
      setState(() => driverMarkers = markers);
    });

    _fetchNearbyDrivers(startLatLng.latitude, startLatLng.longitude);

    _nearbyTimer?.cancel();
    _nearbyTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchNearbyDrivers(startLatLng.latitude, startLatLng.longitude);
    });
  }

  Timer? _nearbyTimer;

  @override
  void dispose() {
    _nearbyTimer?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  // =========================
  // OSRM Route (points + distance + duration)
  // =========================
  Future<void> _loadRoute() async {
    setState(() => loadingRoute = true);

    try {
      final result = await _getRouteWithMeta(
        widget.startLatitude,
        widget.startLongitude,
        widget.endLatitude,
        widget.endLongitude,
      );

      if (!mounted) return;

      setState(() {
        routePoints = result.points;
        routeDistanceMeters = result.distanceMeters;
        routeDurationSeconds = result.durationSeconds;
        loadingRoute = false;
      });

      // Fit bounds (فقط إذا في نقاط)
      if (routePoints.length >= 2) {
        final bounds = LatLngBounds.fromPoints(routePoints);
        mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
        );
      } else {
        mapController.move(startLatLng, 14);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingRoute = false);
    }
  }

  // ✅ NEW: return points + distance + duration
  Future<_OsrmRouteResult> _getRouteWithMeta(
    double startLat,
    double startLon,
    double endLat,
    double endLon,
  ) async {
    final url =
        "http://route.gocab.org/route/v1/driving/"
        "$startLon,$startLat;$endLon,$endLat"
        "?overview=full&steps=true&geometries=geojson";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Failed to load route');
    }

    final data = jsonDecode(response.body);
    final routes = data["routes"] as List?;
    if (routes == null || routes.isEmpty) {
      throw Exception("No routes found");
    }

    final route = routes[0];
    final distance = (route["distance"] as num).toDouble(); // meters
    final duration = (route["duration"] as num).toDouble(); // seconds

    final coords = route["geometry"]["coordinates"] as List;
    final points = coords
        .map<LatLng>(
          (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
        )
        .toList();

    return _OsrmRouteResult(
      points: points,
      distanceMeters: distance,
      durationSeconds: duration,
    );
  }

  // =========================
  // Nearby drivers (socket)
  // =========================
  void _fetchNearbyDrivers(double lat, double lng) {
    socketEvents.getNearbyDrivers(pickUpLat: lat, pickUpLng: lng);
  }

  // =========================
  // Server distance (RouteCard)
  // =========================
  Future<void> _getServerDistance() async {
    final from = gml.LatLng(startLatLng.latitude, startLatLng.longitude);
    final to = gml.LatLng(endLatLng.latitude, endLatLng.longitude);

    final result = await apiService.getDistance(from: from, to: to);
    if (!mounted) return;
    if (result != null) setState(() => serverResult = result);
  }

  // =========================
  // Confirm Trip (نفس شغلك)
  // =========================
  void _confirmTrip() async {
    await _showPriceAdjustmentSheet();
  }

  void _startSendingLocationInRide() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final String? customerIdStr = Cachenetwork.getdata("user_id");
        if (customerIdStr == null) return;

        final int customerId = int.parse(customerIdStr);
        socketEvents.sendCustomerLocation(
          customerId: customerId,
          lat: position.latitude,
          lng: position.longitude,
          rideId: currentRideId!,
        );
      } catch (_) {}
    });
  }

  Future<void> _showPriceAdjustmentSheet() async {
    // ✅ NEW: السعر التقديري الدقيق من OSRM
    final meters = routeDistanceMeters;
    final estimated = meters == null ? null : _estimatePriceFromMeters(meters);

    // ✅ خلي السعر الابتدائي = التقديري (أولوية) ثم serverResult ثم default
    int price = estimated ?? serverResult?.calculated_price ?? 20000;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ NEW: عرض السعر التقديري والمسافة والوقت قبل التحكم
                  if (routeDistanceMeters != null &&
                      routeDurationSeconds != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "تفاصيل الرحلة",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "من: ${widget.startPoint}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "إلى: ${widget.endPoint}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "المسافة: ${_formatDistance(routeDistanceMeters!)}",
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "الوقت: ${_formatDuration(routeDurationSeconds!)}",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text(
                                "السعر التقديري: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "${estimated ?? price} ل.س",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 14),

                  // ====== UI التحكم بالسعر (نفسه ما انحذف) ======
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => setModalState(() {
                          price = (price - 1000)
                              .clamp(0, double.infinity)
                              .toInt();
                        }),
                        icon: const Icon(
                          Icons.remove_circle,
                          color: Colors.red,
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        "$price ل.س",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        onPressed: () => setModalState(() => price += 1000),
                        icon: const Icon(
                          Icons.add_circle,
                          color: Colors.green,
                          size: 36,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ====== زر جلب السائقين (نفسه) ======
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final rideServices = RideApiService();

                        // ✅ NEW: استخدم المسافة والوقت الحقيقيين إن توفروا
                        final distanceKm = (routeDistanceMeters ?? 0) / 1000.0;
                        final durationSec = (routeDurationSeconds ?? 0).toInt();

                        final response = await rideServices.createRide(
                          startAddress: widget.startPoint,
                          endAddress: widget.endPoint,
                          distance: distanceKm == 0 ? 25.2 : distanceKm,
                          estimatedDuration: durationSec == 0
                              ? 2500
                              : durationSec,
                          estimatedPrice: price.toDouble(),
                        );

                        currentRideId = response.data.rideId;

                        await socketEvents.openSocketCustomerConnection();
                        socketEvents.newRide(
                          pickupAddress: widget.startPoint,
                          dropOffAddress: widget.endPoint,
                          distance: distanceKm == 0 ? 25.2 : distanceKm,
                          estimatedDuration: durationSec == 0
                              ? 2500
                              : durationSec,
                          estimatedPrice: price.toDouble(),
                        );

                        _startSendingLocationInRide();

                        final driversResponse = await fetchDrivers();
                        final List<DriverData> drivers =
                            driversResponse?.data ?? [];

                        if (!mounted) return;
                        Navigator.pop(context);
                        _showDriverSearchSheet(price: price, drivers: drivers);
                      } catch (_) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("فشل إنشاء الرحلة أو جلب السائقين"),
                          ),
                        );
                      }
                    },
                    child: const Text("جلب السائقين"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDriverSearchSheet({
    required dynamic price,
    required List<DriverData> drivers,
  }) {
    int currentCount = drivers.length;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "عدد السائقين: $currentCount",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    width: 120,
                    child: Stack(
                      children: [
                        for (
                          int i = 0;
                          i < (currentCount > 3 ? 3 : currentCount);
                          i++
                        )
                          Positioned(
                            left: i * 28,
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundImage: NetworkImage(
                                "https://i.pravatar.cc/150?img=1",
                              ),
                            ),
                          ),
                        if (currentCount > 3)
                          Positioned(
                            left: 3 * 28,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.grey.shade300,
                              child: Text(
                                "+${currentCount - 3}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "اضغط على الزر لبدء البحث عن أقرب السائقين المتاحين.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    socketEvents.sendCustomerPickupLocation(
                      pickupLat: startLatLng.latitude,
                      pickupLng: startLatLng.longitude,
                    );
                    socketEvents.joinRide(rideId: currentRideId!);

                    if (!mounted) return;
                    Navigator.pop(context);
                    setState(() => showDriversOverlay = true);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: Colors.black26,
                  ),
                  child: const Text(
                    "بحث عن السائقين",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  // =========================
  // Markers
  // =========================
  List<Marker> _buildMarkers() {
    final markers = <Marker>[
      Marker(
        point: startLatLng,
        width: 46,
        height: 46,
        child: const _StartMarkerWidget(),
      ),
      Marker(
        point: endLatLng,
        width: 46,
        height: 46,
        child: const _EndMarkerWidget(),
      ),
    ];

    markers.addAll(driverMarkers);

    return markers;
  }

  // ✅ NEW: كارد احترافي دائم فوق الخريطة (حتى لو serverResult ما رجع)
  Widget _topTripInfoCard() {
    final meters = routeDistanceMeters;
    final secs = routeDurationSeconds;

    // لسه ما اجا المسار
    if (meters == null || secs == null) return const SizedBox.shrink();

    final estimated = _estimatePriceFromMeters(meters);

    return Card(
      elevation: 6,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "من: ${widget.startPoint}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "إلى: ${widget.endPoint}",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 16),
            Row(
              children: [
                Expanded(child: Text("المسافة: ${_formatDistance(meters)}")),
                Expanded(child: Text("الوقت: ${_formatDuration(secs)}")),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "السعر التقديري: $estimated ل.س",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = _buildMarkers();

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text("المسار")),
          body: Stack(
            children: [
              FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: startLatLng,
                  initialZoom: 14,
                  minZoom: 3,
                  maxZoom: 19,
                  // 🚫 لا onTap => ما في تحديد نقاط
                ),
                children: [
                  TileLayer(
                    urlTemplate: tilesUrlTemplate,
                    userAgentPackageName: 'com.example.map',
                  ),

                  // ✅ Polyline فقط إذا فيه نقاط كفاية
                  if (routePoints.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          color: Colors.black,
                          strokeWidth: 3,
                        ),
                      ],
                    ),

                  MarkerLayer(markers: markers),
                ],
              ),

              if (loadingRoute)
                const Positioned.fill(
                  child: Center(child: CircularProgressIndicator()),
                ),

              // ✅ NEW: كارد احترافي فوق
              Positioned(top: 0, left: 0, right: 0, child: _topTripInfoCard()),

              // ✅ RouteCard تبعك (ما انحذف) بس نزّلناه شوي لتجنب التداخل
              if (serverResult != null)
                Positioned(
                  top: 150,
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
        ),

        if (showDriversOverlay)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: MockOffersScreen(
                rideId: currentRideId!,
                price: (serverResult?.calculated_price ?? 20000).toDouble(),
                onClose: () => setState(() => showDriversOverlay = false),
              ),
            ),
          ),
      ],
    );
  }
}

// =========================
// Local model for OSRM result
// =========================
class _OsrmRouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  _OsrmRouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

// =========================
// Marker widgets
// =========================

class _StartMarkerWidget extends StatelessWidget {
  const _StartMarkerWidget();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.22),
            shape: BoxShape.circle,
          ),
        ),
        const Icon(Icons.location_pin, color: Colors.green, size: 40),
      ],
    );
  }
}

class _EndMarkerWidget extends StatelessWidget {
  const _EndMarkerWidget();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.22),
            shape: BoxShape.circle,
          ),
        ),
        const Icon(Icons.flag, color: Colors.red, size: 36),
      ],
    );
  }
}

class _DriverMarkerWidget extends StatelessWidget {
  const _DriverMarkerWidget();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.20),
            shape: BoxShape.circle,
          ),
        ),
        const Icon(Icons.directions_car, color: Colors.blue, size: 28),
      ],
    );
  }
}
