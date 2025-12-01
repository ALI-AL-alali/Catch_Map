import 'dart:async';
import 'package:flutter/material.dart';

// ---------------- DriverItem ----------------
class DriverItem {
  final String driverEmail;
  final int basePrice;
  int? driverPrice;
  final String status;

  final double totalSeconds = 30;
  double remainingSeconds = 30;
  Timer? _timer;

  final String driverMockName;
  final String driverMockImageUrl;

  VoidCallback? onRemoveWithAnimation;

  DriverItem({
    required this.driverEmail,
    required this.basePrice,
    required this.status,
    this.driverPrice,
    this.driverMockName = "سائق متاح",
    this.driverMockImageUrl = "https://i.pravatar.cc/150?img=1",
  });

  void startTimer(VoidCallback onFinish) {
    if (_timer != null && _timer!.isActive) return;

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      remainingSeconds -= 0.1;
      if (remainingSeconds <= 0) {
        cancelTimer();
        onFinish();
      }
    });
  }

  void cancelTimer() {
    _timer?.cancel();
  }
}

// ---------------- Animated Driver Card ----------------
class AnimatedDriverCard extends StatefulWidget {
  final DriverItem driverItem;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const AnimatedDriverCard({
    super.key,
    required this.driverItem,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<AnimatedDriverCard> createState() => _AnimatedDriverCardState();
}

class _AnimatedDriverCardState extends State<AnimatedDriverCard>
    with TickerProviderStateMixin {
  late AnimationController _enterController;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  late Animation<double> _scale;

  AnimationController? _exitController;
  Animation<double>? _sizeAnimation;
  Animation<double>? _fadeExitAnimation;
  Animation<Offset>? _slideOut;
  Animation<double>? _rotateOut;
  bool isExiting = false;

  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();

    // تحديث واجهة المستخدم بشكل متزامن مع المؤقت لتحديث تأثير الانسحاب اللوني
    _uiUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) setState(() {});
    });

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _slide = Tween<Offset>(begin: const Offset(1.2, 0), end: Offset.zero)
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(_enterController);

    _fade = Tween<double>(begin: 0, end: 1).animate(_enterController);
    _scale = Tween<double>(begin: 0.95, end: 1.0).animate(_enterController);

    _enterController.forward();

    widget.driverItem.onRemoveWithAnimation = removeWithAnimation;
  }

  @override
  void dispose() {
    _enterController.dispose();
    _exitController?.dispose();
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  void removeWithAnimation() {
    if (!mounted || isExiting) return;

    isExiting = true;
    _uiUpdateTimer?.cancel();
    widget.driverItem.cancelTimer();

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-2.0, 1.0),
    ).animate(CurvedAnimation(parent: _exitController!, curve: Curves.easeIn));

    _rotateOut = Tween<double>(begin: 0, end: 0.3).animate(
      CurvedAnimation(parent: _exitController!, curve: Curves.easeIn),
    );

    _sizeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _exitController!,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );

    _fadeExitAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _exitController!,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );

    _exitController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onReject();
      }
    });

    setState(() {});
    _exitController!.forward();
  }

  void acceptWithAnimation() {
    if (!mounted || isExiting) return;

    isExiting = true;
    _uiUpdateTimer?.cancel();
    widget.driverItem.cancelTimer();

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(2.0, 1.0),
    ).animate(CurvedAnimation(parent: _exitController!, curve: Curves.easeIn));

    _rotateOut = Tween<double>(begin: 0, end: -0.3).animate(
      CurvedAnimation(parent: _exitController!, curve: Curves.easeIn),
    );

    _sizeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _exitController!,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );

    _fadeExitAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _exitController!,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );

    _exitController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAccept();
      }
    });

    setState(() {});
    _exitController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.driverItem;

    // حساب نسبة التقدم (0.0 في البداية، 1.0 في النهاية)
    double progress = (item.totalSeconds - item.remainingSeconds) / item.totalSeconds;

    Widget cardContent = Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة واسم السائق
            Row(
              children: [
                ClipOval(
                  child: Image.network(
                    item.driverMockImageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person_pin, size: 50, color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.driverMockName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("تقييم 4.8 ⭐",
                        style: TextStyle(
                            fontSize: 14, color: Colors.amber.shade700)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text("السعر المبدئي: ${item.basePrice} ل.س",
                style: const TextStyle(color: Colors.grey)),
            if (item.driverPrice != null)
              Text("عرض السائق: ${item.driverPrice} ل.س",
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // أزرار الرفض والقبول (القسم المعدل)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: removeWithAnimation,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("رفض"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Stack( // استخدم Stack لدمج شريط التقدم مع الزر
                    alignment: Alignment.center,
                    children: [
                      // 1. شريط التقدم (الخلفية المتغيرة)
                      SizedBox(
                        height: 48,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            // قيمة الشريط تبدأ من 1.0 وتقل إلى 0.0 (لإحداث تأثير الانسحاب)
                            value: 1.0 - progress,
                            // اللون الفاتح هو لون الخلفية
                            backgroundColor: Colors.green.shade200,
                            // اللون الداكن هو اللون الذي ينسحب (المساحة المتبقية)
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
                            minHeight: 48,
                          ),
                        ),
                      ),

                      // 2. الزر الفعلي (خلفية شفافة لتظهر الخلفية المتحركة)
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent, // خلفية شفافة
                            foregroundColor: Colors.white,
                            elevation: 0, // إزالة الظل
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: isExiting ? null : acceptWithAnimation,
                          child: const Text("قبول"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    // حالة الانسحاب مع تزامن اللون
    if (isExiting && _sizeAnimation != null && _fadeExitAnimation != null) {
      Widget animatedExit = Transform.rotate(
        angle: _rotateOut!.value,
        child: SlideTransition(position: _slideOut!, child: cardContent),
      );

      return FadeTransition(
        opacity: _fadeExitAnimation!,
        child: SizeTransition(
            sizeFactor: _sizeAnimation!, axisAlignment: -1, child: animatedExit),
      );
    }

    // العرض الطبيعي للكارد مع دخول متحرك
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: cardContent),
      ),
    );
  }
}

// ---------------- Mock Offers Screen ----------------
class MockOffersScreen extends StatefulWidget {
  const MockOffersScreen({super.key});

  @override
  State<MockOffersScreen> createState() => _MockOffersScreenState();
}

class _MockOffersScreenState extends State<MockOffersScreen> {
  final List<DriverItem> activeOffers = [];

  final List<Map<String, dynamic>> mockDrivers = [
    {
      "name": "driver1",
      "image": "https://i.pravatar.cc/150?img=4",
      "price": 25000,
    },
    {
      "name": "driver2 ",
      "image": "https://i.pravatar.cc/150?img=5",
      "price": 22000,
    },
    {
      "name": " driver3",
      "image": "https://i.pravatar.cc/150?img=7",
      "price": 27000,
    },
  ];

  @override
  void initState() {
    super.initState();
    _addMockDriversSequentially();
  }

  void _addMockDriversSequentially() async {
    for (var i = 0; i < mockDrivers.length; i++) {
      await Future.delayed(const Duration(seconds: 1));
      final driver = mockDrivers[i];
      final item = DriverItem(
        driverEmail: "driver_$i",
        basePrice: 20000,
        driverPrice: driver["price"],
        status: "pending",
        driverMockName: driver["name"],
        driverMockImageUrl: driver["image"],
      );

      item.onRemoveWithAnimation = () => _removeOfferItem(item);

      if (!mounted) return;
      setState(() {
        activeOffers.add(item);
      });

      item.startTimer(() {
        if (mounted) _removeOfferItem(item);
      });
    }
  }

  void _removeOfferItem(DriverItem item) {
    item.cancelTimer();
    if (!mounted) return;
    setState(() {
      activeOffers.remove(item);
    });
  }

  void _acceptOffer(String driverEmail) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("تم اختيار السائق: $driverEmail")),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    for (var offer in activeOffers) {
      offer.cancelTimer();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("السائقين")),
      body: activeOffers.isEmpty
          ? const Center(child: Text("جاري جلب العروض..."))
          : ListView(
        children: activeOffers
            .map(
              (item) => AnimatedDriverCard(
            key: ValueKey(item.driverEmail),
            driverItem: item,
            onAccept: () => _acceptOffer(item.driverEmail),
            onReject: () => item.onRemoveWithAnimation?.call(),
          ),
        )
            .toList(),
      ),
    );
  }
}