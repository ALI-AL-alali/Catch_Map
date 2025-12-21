import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map/core/const/endpoint.dart';
import 'package:map/core/helpers/socket_events.dart';
import 'package:map/services/get_driver.dart';
import 'dart:async';
import '../../services/graphhopper_service.dart';
import '../../services/distance_api_service.dart';
import '../../models/distance_result_model.dart';
import '../models/driver_model.dart';
import '../services/create_ride_api.dart';
import '../widgets/route_card.dart';
import 'package:geolocator/geolocator.dart';

import 'get_driver_screen.dart'; // إضافة مكتبة geolocator
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _controller = Completer();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool showDriversOverlay = false; // يتحكم بظهور Overlay السائقين

  late AnimationController polyAnimController;
  List<LatLng> animatedRoute = [];

  LatLng? startPoint;
 LatLng? endPoint;

  DistanceResult? serverResult;

  String graphDistance = "";
  String graphDuration = "";

  final graphhopper = GraphHopperService();
  final apiService = DistanceApiService();
  final SocketEvents socketEvents = SocketEvents();

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
  BitmapDescriptor driverIcon = BitmapDescriptor.defaultMarkerWithHue(
    BitmapDescriptor.hueAzure, // رمز السيارة
  );

  List<LatLng> drivers = [
    LatLng(33.5140, 36.2767), // مواقع السيارات
    LatLng(33.5150, 36.2770),
    LatLng(33.5125, 36.2750),
    LatLng(33.5160, 36.2780),
  ];

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

    _getCurrentLocation();
    _addDriverMarkers(); // إضافة الماركرات الخاصة بالسيارات

  }

  // إضافة الماركرات الخاصة بالسيارات المتواجدة
  void _addDriverMarkers() {
    for (int i = 0; i < drivers.length; i++) {
      _markers.add(
        Marker(
          markerId: MarkerId('driver_$i'), // تعيين معرف فريد لكل سيارة
          position: drivers[i],
          icon: driverIcon, // تخصيص الأيقونة
          infoWindow: InfoWindow(
            title: "سيارة ${i + 1}",
            snippet: "الموقع: ${drivers[i].latitude}, ${drivers[i].longitude}",
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    polyAnimController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      startPoint = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: startPoint!,
          icon: startIcon,
        ),
      );
      // يمكنك تحديث الكاميرا على الموقع الجديد
      _controller.future.then((controller) {
        controller.animateCamera(CameraUpdate.newLatLngZoom(startPoint!, 14));
      });
    });
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

  void _confirmTrip() async{
    if (startPoint != null && endPoint != null) {
      await _showPriceAdjustmentSheet(); // هنا بنفتح البوتم شي

    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("حدد نقطتين أولًا")));
    }

    // if (startPoint != null && endPoint != null) {
    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(const SnackBar(content: Text("تم تأكيد الرحلة")));
    //   Navigator.of(context).push(
    //     MaterialPageRoute(
    //       builder: (_) => MockOffersScreen(),
    //     ),
    //   );
    // }
  }





   _showPriceAdjustmentSheet() {
    int price = serverResult?.calculated_price ?? 20000;

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
                  /// التحكم بالسعر
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          setModalState(() {
                            price = (price - 1000).clamp(0, double.infinity).toInt();
                          });
                        },
                        icon: const Icon(Icons.remove_circle, color: Colors.red, size: 36),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        "$price ل.س",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        onPressed: () {
                          setModalState(() {
                            price += 1000;
                          });
                        },
                        icon: const Icon(Icons.add_circle, color: Colors.green, size: 36),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () async {
                      try {
                        // إنشاء الرحلة
                        await RideApiService().createRide(
                          startAddress: "المزة",
                          endAddress: "الميدان",
                          distance: 25.2,
                          estimatedDuration: 2500,
                          estimatedPrice: price.toDouble(),
                        );
                        await socketEvents.openSocketCustomerConnection();
                        // جلب السائقين من الباك
                        final driversResponse = await fetchDrivers();
                        final List<DriverData> drivers = driversResponse?.data ?? [];



                        Navigator.pop(context); // اغلاق البوتم شيت
                        _showDriverSearchSheet(price: price, drivers: drivers);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("فشل إنشاء الرحلة أو جلب السائقين")),
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

  void _showDriverSearchSheet({required dynamic price, required List<DriverData> drivers}) {
    int currentCount = drivers.length;
    List<DriverData> displayList = currentCount > 3 ? drivers.sublist(0, 3) : drivers;

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

              /// صور السائقين + عددهم
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "عدد السائقين: $currentCount",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 40,
                    width: 120,
                    child: Stack(
                      children: [
                        for (int i = 0; i < (currentCount > 3 ? 3 : currentCount); i++)
                          Positioned(
                            left: i * 28,
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundImage: NetworkImage(
                                "https://i.pravatar.cc/150?img=1", // صورة واحدة افتراضية لكل السائقين
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
                                style: const TextStyle(fontWeight: FontWeight.bold),
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
                  onPressed: () async{

                    socketEvents.sendCustomerPickupLocation(pickupLat: startPoint!.latitude, pickupLng: startPoint!.longitude);
                    // socketEvents.listenToAvailableDrivers();
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




  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
        ),

        if (showDriversOverlay)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5), // خلفية شفافة على الخريطة
              child: MockOffersScreen(
                onClose: () => setState(() => showDriversOverlay = false),
              ),
            ),
          ),
      ],
    );
  }
}
