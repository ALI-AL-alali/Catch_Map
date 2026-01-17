import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:map/core/const/endpoint.dart';
import 'package:map/screen/map_screen.dart';
import 'package:map/services/create_ride_api.dart';

import '../core/helpers/socket_events.dart' hide MapScreen;
import '../core/utils/cachenetwork.dart';
import '../models/driver_available_model.dart';

// ---------------- DriverItem ----------------
class DriverItem {
  final String driverId;
  final String bidId;
  final String driverName;
  final String basePrice;
  int? driverPrice;
  final String status;

  final double totalSeconds = 30;
  double remainingSeconds = 30;
  Timer? _timer;

  final String driverMockName;
  final String driverMockImageUrl;

  VoidCallback? onRemoveWithAnimation;

  DriverItem({
    required this.driverId,
    required this.driverName,
    required this.basePrice,
    required this.status,
    this.driverPrice,
    this.driverMockImageUrl = "https://i.pravatar.cc/150?img=1",
    required this.driverMockName, required this.bidId,
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
  final VoidCallback onPriceUpdated;
  final SocketEvents socketEvents;
  final int rideId;


  const AnimatedDriverCard({
    super.key,
    required this.driverItem,
    required this.onAccept,
    required this.onReject, required this.onPriceUpdated, required this.socketEvents, required this.rideId,
  });

  @override
  State<AnimatedDriverCard> createState() => _AnimatedDriverCardState();
}

class _AnimatedDriverCardState extends State<AnimatedDriverCard> with TickerProviderStateMixin {
  late AnimationController _enterController;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  late Animation<double> _scale;

  AnimationController? _exitController;
  Animation<Offset>? _slideOut;
  Animation<double>? _rotateOut;
  Animation<double>? _sizeAnimation;
  Animation<double>? _fadeExitAnimation;

  bool isExiting = false;

  final double totalSeconds = 30;
  double remainingSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _slide = Tween<Offset>(begin: const Offset(1.2, 0), end: Offset.zero)
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(_enterController);

    _fade = Tween<double>(begin: 0, end: 1).animate(_enterController);
    _scale = Tween<double>(begin: 0.95, end: 1.0).animate(_enterController);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _enterController.forward();
    });

    _startTimer();

  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        remainingSeconds -= 0.1;
        if (remainingSeconds <= 0) {
          remainingSeconds = 0;
          timer.cancel();
          _rejectWithAnimation();
        }
      });
    });
  }

  void _rejectWithAnimation() {
    if (isExiting || !mounted) return;
    isExiting = true;
    _timer?.cancel();

    _startExitAnimation(
      slideEnd: const Offset(-2, 1),
      rotateEnd: 0.3,
      onComplete: widget.onReject,
    );
  }

  void _acceptWithAnimation() {
    if (isExiting || !mounted) return;
    isExiting = true;
    _timer?.cancel();

    _startExitAnimation(
      slideEnd: const Offset(2, 1),
      rotateEnd: -0.3,
      onComplete: widget.onAccept,
    );
  }

  void _startExitAnimation({
    required Offset slideEnd,
    required double rotateEnd,
    required VoidCallback onComplete,
  }) {
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideOut = Tween<Offset>(begin: Offset.zero, end: slideEnd)
        .animate(CurvedAnimation(parent: _exitController!, curve: Curves.easeIn));

    _rotateOut = Tween<double>(begin: 0, end: rotateEnd)
        .animate(CurvedAnimation(parent: _exitController!, curve: Curves.easeIn));

    _sizeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _exitController!,
        curve: const Interval(0.5, 1, curve: Curves.easeOut),
      ),
    );

    _fadeExitAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _exitController!,
        curve: const Interval(0.5, 1, curve: Curves.easeOut),
      ),
    );

    _exitController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        onComplete();
      }
    });

    _exitController!.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _enterController.dispose();
    _exitController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = remainingSeconds / totalSeconds;

    final card = Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipOval(
                  child: Image.network(
                    widget.driverItem.driverMockImageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.driverItem.driverName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "تقييم 4.8 ⭐",  // يمكن تعديل التقييم إذا كانت البيانات متوفرة
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "السعر المبدئي: ${widget.driverItem.basePrice} ل.س",
              style: const TextStyle(color: Colors.grey),
            ),
            if (widget.driverItem.driverPrice != null)
              Text(
                "عرض السائق: ${widget.driverItem.driverPrice} ل.س",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              "معرف الرحلة: ${widget.driverItem.driverId}",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _showUpdatePriceDialog(widget.driverItem),
              child: Text(
                'تغيير السعر',
                style: TextStyle(color: Colors.blue),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _rejectWithAnimation,
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
                    onTap: _acceptWithAnimation,
                    child: SizedBox(
                      height: 48,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            // زر القبول مع تقدم الأنيميشن (عرض التقدم على الزر)
                            FractionallySizedBox(
                              widthFactor: progress,
                              alignment: Alignment.centerRight,
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const Center(
                              child: Text(
                                "قبول",
                                style: TextStyle(
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
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (isExiting && _sizeAnimation != null) {
      return FadeTransition(
        opacity: _fadeExitAnimation!,
        child: SizeTransition(
          sizeFactor: _sizeAnimation!,
          child: Transform.rotate(
            angle: _rotateOut!.value,
            child: SlideTransition(position: _slideOut!, child: card),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: card),
      ),
    );
  }

  Future<void> _showUpdatePriceDialog(DriverItem item) async {
    final TextEditingController priceController =
    TextEditingController(text: item.driverPrice?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تحديث السعر'),
          content: TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'أدخل السعر الجديد',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final newPrice = double.tryParse(priceController.text);

                if (newPrice == null || newPrice <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('الرجاء إدخال سعر صحيح'),
                    ),
                  );
                  return;
                }

                // تحديث السعر
                setState(() {
                  item.driverPrice = newPrice.toInt();
                });

                // ارسال التحديث عبر Socket
                widget.socketEvents.updatePrice(newPrice: newPrice, bidId: item.bidId, rideId: widget.rideId);

                // إزالة الكارد من الواجهة
                widget.onPriceUpdated();

                // إغلاق نافذة الحوار
                Navigator.pop(context);
              },
              child: const Text('تحديث السعر'),
            )

          ],
        );
      },
    );
  }
}




// ---------------- MockOffersScreen (Overlay) ----------------
class MockOffersScreen extends StatefulWidget {
  final VoidCallback? onClose;
  final int rideId;
  final double price;
  final String startPoint;
  final String endPoint;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;

  const MockOffersScreen({super.key, this.onClose, required this.rideId, required this.price, required this.startPoint, required this.endPoint, required this.startLat, required this.startLng, required this.endLat, required this.endLng});

  @override
  State<MockOffersScreen> createState() => _MockOffersScreenState();
}

class _MockOffersScreenState extends State<MockOffersScreen> {
  final List<DriverItem> activeOffers = [];
  final SocketEvents socketEvents = SocketEvents();

  void _onBidsReceived(dynamic response) {


    // طباعة الاستجابة بالكامل للمراجعة
    debugPrint('Received response: $response');

    // تأكد من أن الاستجابة تحتوي على بيانات صحيحة
    if (response != null) {
      // تأكد من وجود ride_id و price
      if (response['ride_id'] != null && response['price'] != null) {
        // هنا، لا نحتاج للتحقق من 'driver' لأننا نعلم أن الاستجابة تحتوي على 'driver_id'
        final int rideId = response['ride_id'];  // الحصول على ride_id

        // تحويل السعر إلى double في حالة كان من نوع int
        final double price = (response['price'] is int)
            ? (response['price'] as int).toDouble()
            : response['price'];  // التأكد أن السعر هو double

        final String driverId = response['driver_id'];  // الحصول على ID السائق (بدون 'driver')
        final String bidId = response['bid_id'] ?? '';  // الحصول على ID السائق (بدون 'driver')

        // طباعة البيانات للمراجعة
        debugPrint('📥 BID EVENT RECEIVED => Ride ID: $rideId, Driver ID: $driverId, Price: $price, bid: $bidId');

        // تحقق إذا كان العرض موجودًا مسبقًا
        final alreadyExists = activeOffers.any((item) => item.driverId == driverId);

        // إذا كان العرض موجودًا بالفعل، نقوم بتخطيه
        if (alreadyExists) return;

        // إنشاء عنصر العرض باستخدام البيانات المستلمة
        final item = DriverItem(
          driverId: driverId,  // ID السائق
          driverName: 'Unknown',  // لا يوجد اسم السائق في البيانات، يمكننا إضافة "Unknown" كمثال
          basePrice: price.toString(),  // تحويل السعر إلى قيمة نصية
          driverPrice: price.toInt(),  // تحويل السعر إلى int
          status: 'available',  // يمكنك تعديل الحالة بناءً على احتياجاتك
          driverMockName: 'Unknown',  // اسم السائق لعرضه في الكارد
          driverMockImageUrl: 'https://i.pravatar.cc/150?img=$driverId', // صورة السائق عشوائية
          bidId: bidId, // صورة السائق عشوائية
        );

        // إضافة العرض الجديد إلى القائمة
        setState(() {
          activeOffers.add(item);  // إضافة العنصر الجديد إلى القائمة
        });
      } else {
        // في حال كانت بيانات الرحلة أو السعر ناقصة
        debugPrint("Ride ID or Price is missing: ${response.toString()}");
      }
    } else {
      // إذا كانت الاستجابة null
      debugPrint("Received null response");
    }
  }










  Future<void> _initSocket() async {

    socketEvents.requestRideBids(
      rideId: widget.rideId,
      price: widget.price,
      onData: _onBidsReceived,
    );
  }

  String? acceptedDriverId;


  PersistentBottomSheetController? _bottomSheetController;
  @override
  void initState() {
    super.initState();

    _initSocket();


    bool showDriversOverlay = false;


    // داخل _initSocket()
    socketEvents.listenToRideAccepted((data) {
      if (!mounted || data == null) return;

      final int? rideId = (data['ride_id'] is int)
          ? data['ride_id']
          : int.tryParse('${data['ride_id']}');

      final String? driverId = data['driver_id']?.toString();

      if (rideId == null || rideId != widget.rideId) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم قبول الرحلة من قبل السائق')),
      );

      // ✅ سكّر overlay قبل ما تنتقل
      widget.onClose?.call();

      // ✅ انتقل لصفحة الخريطة مع بيانات الرحلة الحقيقية
      Future.microtask(() {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MapScreen(
              startPoint: widget.startPoint,
              endPoint: widget.endPoint,
              startLatitude: widget.startLat,
              startLongitude: widget.startLng,
              endLatitude: widget.endLat,
              endLongitude: widget.endLng,
              // إذا بدك مرّر rideId/driverId كمان (حسب MapScreen عندك)
            ),
          ),
        );
      });
    });



    _listenToRideStatus();
    // socketEvents.startLocationTracking(rideId: widget.rideId,driverId: item.driverId);




  }


  _listenToRideStatus() {
    socketEvents.listenToRideUpdates((data) {
      if (!mounted || data == null) return;

      final String status = data['status'];
      final int rideId = data['ride_id'];

      if (rideId != widget.rideId) return;
      // Navigator.pop(context);
      _handleRideStatus(status, data);
    });
  }


  void _handleRideStatus(String status, dynamic data) {
    switch (status) {
      case 'arriving':
        _showOnTheWaySheet(data);
        break;

      case 'arrived':
        _showArrivedSheet(data);
        break;

      case 'finished':
      case 'completed':
        socketEvents.stopLocationTracking();
        _showFinishedSheet();
        break;
    }
  }


  void _showOnTheWaySheet(dynamic data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _StatusSheet(
        icon: Icons.directions_car,
        title: 'السائق في طريقه إليك',
        subtitle: 'يرجى الاستعداد',
      ),
    );
  }


  void _showArrivedSheet(dynamic data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _StatusSheet(
        icon: Icons.location_on,
        title: 'السائق وصل',
        subtitle: 'يرجى التوجه إلى موقع الالتقاء',
      ),
    );
  }



  void _showFinishedSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StatusSheet(
        icon: Icons.check_circle,
        title: 'انتهت الرحلة',
        subtitle: 'نتمنى لك رحلة سعيدة 🌸',
      ),
    );
  }







  void _removeOfferItem(DriverItem item) async {
    item.cancelTimer();

    if (!mounted) return;
    // socketEvents.startListeningToSocketEvents('ride:bid:rejected', 'rejected');
    setState(() => activeOffers.remove(item));
  }




  void _acceptOffer(DriverItem item) async {
    final String? customerIdStr = Cachenetwork.getdata("user_id");

    if (customerIdStr == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("خطأ: لم يتم العثور على بيانات المستخدم")),
      );
      return;
    }

    final int customerId = int.parse(customerIdStr);

    socketEvents.acceptBid(
      rideId: widget.rideId,
      bidId: item.bidId,
      driverId: item.driverId,
      customerId: customerId,
      price: item.driverPrice!.toDouble(),
    );

    // socketEvents.startLocationTracking(rideId: widget.rideId,driverId: item.driverId);



    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم قبول عرض السائق")),
    );
    // Navigator.push(context, MaterialPageRoute(builder: (context) => MapScreen(),));

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الخط الصغير بالأعلى
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),

              // اسم السائق
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    item.driverName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // السعر
              Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    item.basePrice,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // رسالة الوصول
              Row(
                children: const [
                  Icon(Icons.location_on, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Driver will arrive at your location',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

            ],
          ),
        );
      },
    );


    widget.onClose?.call();
  }




  @override
  void dispose() {
    for (var offer in activeOffers) offer.cancelTimer();
    socketEvents.stopLocationTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: SafeArea(
        child: SizedBox(
          height: height * 0.65, // ارتفاع Overlay مثل CustomerRideScreen
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                ),
              ),
              Expanded(
                child: activeOffers.isEmpty
                    ? const Center(
                  child: Text(
                    "جاري جلب العروض...",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: activeOffers.length,
                  itemBuilder: (_, index) {
                    final item = activeOffers[index];
                    return AnimatedDriverCard(
                      key: ValueKey(item.driverId),
                      socketEvents: socketEvents,
                      rideId: widget.rideId,
                      driverItem: item,
                      onAccept: () => _acceptOffer(item),
                      onReject: () => _removeOfferItem(item),
                      onPriceUpdated: () => _removeOfferItem(item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusSheet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StatusSheet({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Icon(icon, size: 48, color: Colors.blue),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

