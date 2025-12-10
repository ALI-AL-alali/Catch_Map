import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController mapController = MapController();
  final FlutterTts tts = FlutterTts();

  LatLng? startPoint;
  LatLng? endPoint;

  List<LatLng> routePoints = [];
  String distanceText = "";
  String durationText = "";

  List<Map<String, dynamic>> importantStepsRaw = [];
  List<String> arabicInstructions = [];

  bool voiceEnabled = true;
  bool tripStarted = false;
  int currentStepIndex = 0;
  Timer? stepTimer;

  double speedKmh = 50.0;

  // خانات الإحداثيات فقط
  final TextEditingController fromCoordsController = TextEditingController();
  final TextEditingController toCoordsController = TextEditingController();

  // هل النقر يحدد نقطة "من" أم "إلى"
  bool selectingFrom = true;

  static const String osrmBaseUrl =
      "http://route.aiactive.co.uk/route/v1/driving";

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await tts.setLanguage("ar-SA");
    await tts.setPitch(1.0);
    await tts.setSpeechRate(0.92);
    await tts.setVolume(0.95);
    await tts.awaitSpeakCompletion(true);
  }

  @override
  void dispose() {
    stepTimer?.cancel();
    tts.stop();
    fromCoordsController.dispose();
    toCoordsController.dispose();
    super.dispose();
  }

  // ==========================================================
  // حساب المسار من OSRM + زووم تلقائى
  // ==========================================================

  Future<void> getRoute() async {
    if (startPoint == null || endPoint == null) return;

    final url =
        "$osrmBaseUrl/"
        "${startPoint!.longitude},${startPoint!.latitude};"
        "${endPoint!.longitude},${endPoint!.latitude}"
        "?overview=full&steps=true&geometries=geojson";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);
      if (data["code"] != "Ok") return;

      final route = data["routes"][0];

      final distance = (route["distance"] as num);
      final duration = (route["duration"] as num);

      distanceText = "${(distance / 1000).toStringAsFixed(2)} كم";
      durationText = "${(duration / 60).toStringAsFixed(0)} دقيقة";

      final coords = route["geometry"]["coordinates"] as List;
      routePoints = coords
          .map(
            (c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
          )
          .toList();

      // خطوات مهمة
      importantStepsRaw.clear();
      arabicInstructions.clear();
      currentStepIndex = 0;
      tripStarted = false;
      stepTimer?.cancel();

      final legs = route["legs"] as List;
      if (legs.isNotEmpty) {
        for (final step in legs[0]["steps"]) {
          final maneuver = step["maneuver"];
          final type = (maneuver["type"] ?? "").toString();

          const importantTypes = {
            "turn",
            "roundabout",
            "fork",
            "merge",
            "depart",
            "arrive",
          };

          if (importantTypes.contains(type)) {
            importantStepsRaw.add(step);
            arabicInstructions.add(_translateStepToArabic(step));
          }
        }
      }

      // ⬇⬇⬇ الزووم التلقائى على المسار ⬇⬇⬇
      if (routePoints.length >= 2) {
        final bounds = LatLngBounds.fromPoints(routePoints);
        // padding علشان المسار ما يلتصق بحافة الشاشة
        mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(40)),
        );
      }

      setState(() {});
    } catch (_) {
      // تجاهل الأخطاء البسيطة
    }
  }

  // ==========================================================
  // بدء الرحلة + النطق
  // ==========================================================

  void startTrip() async {
    if (importantStepsRaw.isEmpty) return;

    stepTimer?.cancel();
    currentStepIndex = 0;
    tripStarted = true;
    setState(() {});

    if (voiceEnabled) {
      await tts.speak("تم بدء الرحلة.");
    }

    _scheduleNextStep();
  }

  void resetTrip() {
    stepTimer?.cancel();
    tripStarted = false;
    currentStepIndex = 0;
    setState(() {});
  }

  void _scheduleNextStep() {
    stepTimer?.cancel();
    if (!tripStarted || !voiceEnabled) return;
    if (currentStepIndex >= importantStepsRaw.length) {
      tripStarted = false;
      setState(() {});
      return;
    }

    final step = importantStepsRaw[currentStepIndex];
    final distance = (step["distance"] as num);
    final speedMs = (speedKmh * 1000 / 3600);
    double wait = (distance / speedMs) - 8;
    if (wait < 1) wait = 1;
    if (wait > 20) wait = 20;

    stepTimer = Timer(Duration(seconds: wait.round()), () async {
      await _speakStep(step);
      currentStepIndex++;
      _scheduleNextStep();
    });
  }

  Future<void> _speakStep(step) async {
    final text = _translateStepToArabic(step);
    await tts.stop();
    await tts.speak(text);
  }

  // ==========================================================
  // الترجمة للعربية
  // ==========================================================

  String _translateStepToArabic(step) {
    final maneuver = step["maneuver"];
    final type = (maneuver["type"] ?? "").toString();
    final modifier = (maneuver["modifier"] ?? "").toString();
    final road = (step["name"] ?? "").toString();
    final dist = step["distance"] ?? 0;

    String d = dist > 0 ? " لمسافة ${_fmt(dist)}" : "";
    String r = road.isNotEmpty ? " إلى شارع $road" : "";

    switch (type) {
      case "depart":
        return "ابدأ السير$r$d.";
      case "arrive":
        return "لقد وصلت إلى وجهتك.";
      case "turn":
        return _turn(modifier, r, d);
      case "roundabout":
        return "ادخل الدوار ثم اخرج$r$d.";
      case "fork":
        return "اسلك التفرع المناسب$r$d.";
      case "merge":
        return "اندمج مع الطريق$r$d.";
      default:
        return "تابع السير$r$d.";
    }
  }

  String _turn(String m, String r, String d) {
    switch (m) {
      case "right":
        return "انعطف يمينًا$r$d.";
      case "left":
        return "انعطف يسارًا$r$d.";
      case "slight right":
        return "انعطف ميلاً إلى اليمين$r$d.";
      case "slight left":
        return "انعطف ميلاً إلى اليسار$r$d.";
      case "sharp right":
        return "انعطف بحدة إلى اليمين$r$d.";
      case "sharp left":
        return "انعطف بحدة إلى اليسار$r$d.";
      default:
        return "انعطف$r$d.";
    }
  }

  String _fmt(num m) {
    if (m < 1000) return "${m.toStringAsFixed(0)} متر";
    return "${(m / 1000).toStringAsFixed(1)} كم";
  }

  // ==========================================================
  // عند النقر على الخريطة
  // ==========================================================

  void _setFrom(LatLng p) {
    setState(() {
      startPoint = p;
      fromCoordsController.text =
          "${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}";
    });
    if (endPoint != null) getRoute();
  }

  void _setTo(LatLng p) {
    setState(() {
      endPoint = p;
      toCoordsController.text =
          "${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}";
    });
    if (startPoint != null) getRoute();
  }

  void _swap() {
    setState(() {
      final tmp = startPoint;
      startPoint = endPoint;
      endPoint = tmp;

      final tmp2 = fromCoordsController.text;
      fromCoordsController.text = toCoordsController.text;
      toCoordsController.text = tmp2;
    });

    if (startPoint != null && endPoint != null) getRoute();
  }

  // ==========================================================
  // واجهة المستخدم
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("خريطة التاكسى")),
        body: Stack(
          children: [
            // الخريطة
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: LatLng(33.5138, 36.2765),
                initialZoom: 13,
                onTap: (tapPos, p) {
                  if (selectingFrom) {
                    _setFrom(p);
                  } else {
                    _setTo(p);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "http://tiles.aiactive.co.uk/tile/{z}/{x}/{y}.png",
                  userAgentPackageName: 'uk.co.aiactive.taxi',
                ),
                PolylineLayer(
                  polylines: [
                    if (routePoints.isNotEmpty)
                      Polyline(
                        points: routePoints,
                        color: Colors.blue,
                        strokeWidth: 5,
                      ),
                  ],
                ),

                MarkerLayer(
                  markers: [
                    if (startPoint != null)
                      Marker(
                        point: startPoint!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.green,
                          size: 40,
                        ),
                      ),
                    if (endPoint != null)
                      Marker(
                        point: endPoint!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.flag,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // بطاقة التحكم في الأعلى
            Positioned(
              top: 10,
              right: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "النقر يحدد: ${selectingFrom ? "من" : "إلى"}",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.touch_app),
                          onPressed: () =>
                              setState(() => selectingFrom = !selectingFrom),
                        ),
                        IconButton(
                          icon: const Icon(Icons.swap_vert),
                          onPressed: _swap,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: fromCoordsController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "من (إحداثيات)",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: toCoordsController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "إلى (إحداثيات)",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // بطاقة التعليمات والرحلة
            if (distanceText.isNotEmpty)
              Positioned(
                bottom: 10,
                right: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(
                              tripStarted ? Icons.stop : Icons.play_arrow,
                            ),
                            label: Text(
                              tripStarted ? "إيقاف الرحلة" : "بدء الرحلة",
                            ),
                            onPressed: importantStepsRaw.isEmpty
                                ? null
                                : () => tripStarted ? resetTrip() : startTrip(),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              voiceEnabled ? Icons.volume_up : Icons.volume_off,
                            ),
                            onPressed: () {
                              setState(() => voiceEnabled = !voiceEnabled);
                              if (!voiceEnabled) {
                                tts.stop();
                                stepTimer?.cancel();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text("المسافة: $distanceText"),
                      Text("الوقت: $durationText"),
                      const Divider(),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          children: arabicInstructions
                              .map(
                                (e) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 3,
                                  ),
                                  child: Text("• $e"),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
