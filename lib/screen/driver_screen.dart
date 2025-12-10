import 'dart:async';
import 'package:flutter/material.dart';
import 'package:map/widgets/price_bottom_sheet.dart';

// ---------------- AnimatedCustomerCard ----------------
class AnimatedCustomerCard extends StatefulWidget {
  final Map<String, dynamic> customer;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onChangePrice;

  const AnimatedCustomerCard({
    super.key,
    required this.customer,
    required this.onAccept,
    required this.onReject,
    required this.onChangePrice,
  });

  @override
  State<AnimatedCustomerCard> createState() => _AnimatedCustomerCardState();
}

class _AnimatedCustomerCardState extends State<AnimatedCustomerCard>
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

  double totalSeconds = 30;
  double remainingSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _slide = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: Offset.zero,
    ).chain(CurveTween(curve: Curves.easeOutBack)).animate(_enterController);

    _fade = Tween<double>(begin: 0, end: 1).animate(_enterController);
    _scale = Tween<double>(begin: 0.95, end: 1.0).animate(_enterController);

    // تشغيل الأنيميشن بعد فاصل قصير لإعطاء تأثير ظهور متدرج
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _enterController.forward();
    });

    startTimer();
  }

  @override
  void dispose() {
    _enterController.dispose();
    _exitController?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        remainingSeconds -= 0.1;
        if (remainingSeconds <= 0) {
          remainingSeconds = 0;
          timer.cancel();
          removeWithAnimation();
        }
      });
    });
  }

  void removeWithAnimation() {
    if (!mounted || isExiting) return;

    isExiting = true;
    _timer?.cancel();

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-2.0, 1.0),
    ).animate(CurvedAnimation(parent: _exitController!, curve: Curves.easeIn));

    _rotateOut = Tween<double>(
      begin: 0,
      end: 0.3,
    ).animate(CurvedAnimation(parent: _exitController!, curve: Curves.easeIn));

    _sizeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController!,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _fadeExitAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController!,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _exitController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onReject();
      }
    });

    _exitController!.forward();
  }

  void acceptWithAnimation() {
    if (!mounted || isExiting) return;

    isExiting = true;
    _timer?.cancel();

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(2.0, 1.0),
    ).animate(CurvedAnimation(parent: _exitController!, curve: Curves.easeIn));

    _rotateOut = Tween<double>(
      begin: 0,
      end: -0.3,
    ).animate(CurvedAnimation(parent: _exitController!, curve: Curves.easeIn));

    _sizeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController!,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _fadeExitAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController!,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _exitController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAccept();
      }
    });

    _exitController!.forward();
  }

  @override
  Widget build(BuildContext context) {
    double progress = remainingSeconds / totalSeconds;

    Widget cardContent = Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: double.infinity, // الكارد أعرض
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  ClipOval(
                    child: Container(
                      color: Colors.grey.shade300,
                      width: 60, // أعرض شوي
                      height: 60,
                      child: const Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.customer["name"],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${widget.customer["start"]} ➡ ${widget.customer["end"]}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "السعر الحالي: ${widget.customer["price"]} ل.س",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Buttons
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
                    child: GestureDetector(
                      onTap: isExiting ? null : acceptWithAnimation,
                      child: SizedBox(
                        height: 48,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.green.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            FractionallySizedBox(
                              alignment: Alignment.centerRight,
                              widthFactor: progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                "قبول",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onChangePrice,
                  child: const Text("تغيير السعر"),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (isExiting && _sizeAnimation != null && _fadeExitAnimation != null) {
      Widget animatedExit = Transform.rotate(
        angle: _rotateOut!.value,
        child: SlideTransition(position: _slideOut!, child: cardContent),
      );

      return FadeTransition(
        opacity: _fadeExitAnimation!,
        child: SizeTransition(
          sizeFactor: _sizeAnimation!,
          axisAlignment: -1,
          child: animatedExit,
        ),
      );
    }

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: cardContent),
      ),
    );
  }
}

// ---------------- DriverScreen مع ظهور الكاردات بالتتابع ----------------
class DriverScreen extends StatefulWidget {
  final String driverName;
  const DriverScreen({super.key, required this.driverName});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  List<Map<String, dynamic>> allCustomers = [
    {"name": "أحمد", "start": "دمشق", "end": "حلب", "price": 50},
    {"name": "ليلى", "start": "حمص", "end": "دمشق", "price": 35},
    {"name": "فاطمة", "start": "حماه", "end": "حلب", "price": 45},
  ];

  List<Map<String, dynamic>> visibleCustomers = [];

  @override
  void initState() {
    super.initState();
    _showCustomersSequentially();
  }

  void _showCustomersSequentially() async {
    for (var customer in allCustomers) {
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // فاصل زمني بين كل كارد وكارد
      if (!mounted) return;
      setState(() {
        visibleCustomers.add(customer);
      });
    }
  }

  void _openPriceSheet(int index) {
    showPriceBottomSheet(
      context: context,
      currentPrice: visibleCustomers[index]["price"],
      onSave: (newPrice) {
        setState(() {
          visibleCustomers[index]["price"] = newPrice;
        });
      },
    );
  }

  void _acceptCustomer(int index) {
    print("تم قبول العميل ${visibleCustomers[index]["name"]}");
  }

  void _rejectCustomer(int index) {
    setState(() {
      visibleCustomers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "واجهة السائق - ${widget.driverName}",
          style: const TextStyle(
            fontFamily: "Tajawal",
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 5,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: visibleCustomers.length,
          itemBuilder: (context, index) {
            final customer = visibleCustomers[index];
            return AnimatedCustomerCard(
              key: ValueKey(customer["name"]),
              customer: customer,
              onAccept: () => _acceptCustomer(index),
              onReject: () => _rejectCustomer(index),
              onChangePrice: () => _openPriceSheet(index),
            );
          },
        ),
      ),
    );
  }
}
