import 'package:flutter/material.dart';
import 'package:map/core/utils/widget_to_image.dart';
import 'package:map/screen/driver_screen.dart';
import 'package:map/screen/map_page.dart';
import 'package:map/services/notifications_service.dart';
import 'package:map/widgets/ride_progress_card.dart';
import 'map_screen.dart';

class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? selectedType;
  String? selectedName;

  final List<String> customers = ["زينة", "رزان", "محمد"];
  final List<String> drivers = ["فداء", "علي", "جمال"];

  String? selectedMapScreen;
  final List<String> mapScreens = ["MapScreen", "MapPage"];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // إعداد الرسوم المتحركة
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NativeNotifications.showRideNotification(
        price: '25000',
        progress: 0,
      );
    });
    // // إضافة الكود الخاص بالإشعارات بعد بناء الواجهة
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   final widgetToImage = WidgetToImage();
    //   final bytes = await widgetToImage.captureWidget(
    //     RideProgressCard(
    //       eta: "10 min",
    //       price: "250000",
    //       plate: "123456",
    //       progress: 0.5,
    //     ),
    //   );

    //   if (bytes != null) {
    //     await showRideNotification(bytes);
    //   }
    // });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("اختيار المستخدم"),
        backgroundColor: const Color(0xff6a11cb),
        actions: [
          DropdownButton<String>(
            value: selectedMapScreen,
            hint: const Text(
              "اختر الخريطة",
              style: TextStyle(color: Colors.white),
            ),
            dropdownColor: Colors.purple,
            iconEnabledColor: Colors.white,
            underline: const SizedBox(),
            items: mapScreens.map((screen) {
              return DropdownMenuItem(
                value: screen,
                child: Text(
                  screen,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
            onChanged: (val) {
              setState(() {
                selectedMapScreen = val;
              });
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: SingleChildScrollView(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "مرحبا بك!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff6a11cb),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "اختر نوع المستخدم للبدء",
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.purple.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Colors.purple,
                      ),
                    ),
                    hint: const Text("اختر نوع المستخدم"),
                    initialValue: selectedType,
                    items: ["زبون", "سائق"].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedType = val;
                        selectedName = null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  if (selectedType != null)
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.blue.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: Colors.blue,
                        ),
                      ),
                      hint: Text(
                        selectedType == "زبون" ? "اختر الزبون" : "اختر السائق",
                      ),
                      initialValue: selectedName,
                      items: (selectedType == "زبون" ? customers : drivers).map(
                        (name) {
                          return DropdownMenuItem(
                            value: name,
                            child: Text(name),
                          );
                        },
                      ).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedName = val;
                        });
                      },
                    ),
                  const SizedBox(height: 30),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        backgroundColor: const Color(0xff6a11cb),
                        shadowColor: Colors.purpleAccent,
                        elevation: 8,
                      ),
                      onPressed:
                          (selectedName == null || selectedMapScreen == null)
                          ? null
                          : () {
                              Widget nextScreen;
                              if (selectedType == "زبون") {
                                nextScreen = selectedMapScreen == "MapScreen"
                                    ? MapScreen()
                                    : const MapPage();
                              } else {
                                nextScreen = DriverScreen(
                                  driverName: selectedName!,
                                );
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => nextScreen),
                              );
                            },
                      child: const Text(
                        "دخول",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedOpacity(
                    opacity: selectedType != null ? 1 : 0,
                    duration: const Duration(milliseconds: 500),
                    child: const Text(
                      "ابدأ رحلتك الآن",
                      style: TextStyle(color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
