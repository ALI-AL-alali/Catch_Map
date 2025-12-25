import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:map/core/const/endpoint.dart';
import 'package:map/services/create_ride_api.dart';

import '../core/helpers/socket_events.dart';
import '../models/driver_available_model.dart';

// ---------------- DriverItem ----------------
class DriverItem {
  final int driverId;
  final String driverName;
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
    required this.driverId,
    required this.driverName,
    required this.basePrice,
    required this.status,
    this.driverPrice,
    this.driverMockImageUrl = "https://i.pravatar.cc/150?img=1", required this.driverMockName,
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
  SocketEvents socketEvents = SocketEvents();







  @override
  void initState() {
    super.initState();


    _uiUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) setState(() {});
    });

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

    setState(() {});
    _exitController!.forward();
  }



  @override
  Widget build(BuildContext context) {
    final item = widget.driverItem;
    double progress = item.remainingSeconds / item.totalSeconds;

    Widget cardContent = Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    item.driverMockImageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, size: 50),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.driverName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      "تقييم 4.8 ⭐",
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
              "السعر المبدئي: ${item.basePrice} ل.س",
              style: const TextStyle(color: Colors.grey),
            ),
            if (item.driverPrice != null)
              Text(
                "عرض السائق: ${item.driverPrice} ل.س",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 12),

            const SizedBox(height: 12),
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
                          // الخلفية الكاملة فاتحة
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.green.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          // الجزء المتبقي (اللون الغامق) يتناقص مع الوقت
                          FractionallySizedBox(
                            alignment:
                                Alignment.centerRight, // يمشي من اليمين لليسار
                            widthFactor:
                                progress, // كل ما ينقص الوقت، هذا يتناقص
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green.shade700,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          // النص فوقها
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

            OutlinedButton(
              onPressed: (){
                socketEvents.startListeningToSocketEvents('ride:price-update', 'update');
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("عرض مزايدة"),
            ),
          ],
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

// ---------------- MockOffersScreen (Overlay) ----------------
class MockOffersScreen extends StatefulWidget {
  final VoidCallback? onClose;
  final int rideId;

  const MockOffersScreen({super.key, this.onClose, required this.rideId});

  @override
  State<MockOffersScreen> createState() => _MockOffersScreenState();
}

class _MockOffersScreenState extends State<MockOffersScreen> {
  final List<DriverItem> activeOffers = [];
  final SocketEvents socketEvents = SocketEvents();



  Future<void> _fetchBids() async {
    final rideServices= RideApiService();
    try {
      final response = await getBids(widget.rideId); // ride_id = 15

      if (!mounted) return;

      final List<DriverItem> items = response.data.bids.map((bid) {
        final item = DriverItem(
          driverId: bid.driver.id,               // 53
          driverName: bid.driver.name,            // "32سائق تجريبي"
          basePrice: int.parse(
            bid.price.split('.').first,           // "888.00" → 888
          ),
          driverPrice: int.parse(
            bid.price.split('.').first,
          ),
          status: bid.isAccepted ? "accepted" : "pending",
          driverMockName: bid.driver.name,
          driverMockImageUrl:
          "https://i.pravatar.cc/150?img=${bid.driver.id}",
        );

        item.onRemoveWithAnimation = () => _removeOfferItem(item);

        item.startTimer(() {
          if (mounted) _removeOfferItem(item);
        });

        return item;
      }).toList();


      setState(() {
        activeOffers
          ..clear()
          ..addAll(items);
      });


      // setState(() {
      //   activeOffers.clear();
      //   activeOffers.addAll(items);
      // });
    } catch (e) {
      debugPrint("Error fetching bids: $e");
    }
  }


  static Future<BidsResponse> getBids(int rideId) async {
    final t = await token;
    debugPrint('TOKEN => $t');

    final response = await http.get(
      Uri.parse("${EndPoint.getDriver}/$rideId/bids"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $t",
      },
    );

    debugPrint('STATUS CODE => ${response.statusCode}');
    debugPrint('BODY => ${response.body}');

    if (response.statusCode == 200) {
      return BidsResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("فشل تحميل العروض");
    }
  }


  void _loadBidsFromSocket() {
    socketEvents.requestRideBids(
      rideId: widget.rideId,
      onData: (response) {
        if (!mounted) return;

        final List bids = response['data']['bids'];

        final items = bids.map<DriverItem>((bid) {
          final item = DriverItem(
            driverId: bid['driver']['id'],
            driverName: bid['driver']['name'],
            basePrice: int.parse(bid['price']),
            driverPrice: int.parse(bid['price']),
            status: bid['status'],
            driverMockName: bid['driver']['name'],
            driverMockImageUrl:
            'https://i.pravatar.cc/150?img=${bid['driver']['id']}',
          );

          item.onRemoveWithAnimation = () => _removeOfferItem(item);

          item.startTimer(() {
            if (mounted) _removeOfferItem(item);
          });

          return item;
        }).toList();

        setState(() {
          activeOffers
            ..clear()
            ..addAll(items);
        });
      },
    );
  }





  @override
  void initState() {
    super.initState();
    _fetchBids();
    // _addMockDriversSequentially();
    // _loadBidsFromSocket();

  }

  // void _addMockDriversSequentially() async {
  //   for (var i = 0; i < mockDrivers.length; i++) {
  //     await Future.delayed(const Duration(seconds: 2));
  //     final driver = mockDrivers[i];
  //     final item = DriverItem(
  //       driverEmail: "driver_$i",
  //       basePrice: 20000,
  //       driverPrice: driver["price"],
  //       status: "pending",
  //       driverMockName: driver["name"],
  //       driverMockImageUrl: driver["image"],
  //     );
  //
  //     item.onRemoveWithAnimation = () => _removeOfferItem(item);
  //
  //     if (!mounted) return;
  //     setState(() => activeOffers.add(item));
  //
  //     item.startTimer(() {
  //       if (mounted) _removeOfferItem(item);
  //     });
  //   }
  // }

  void _removeOfferItem(DriverItem item) async{
    item.cancelTimer();

    if (!mounted) return;
     socketEvents.startListeningToSocketEvents('bid:rejected','rejected');
    setState(() => activeOffers.remove(item));
  }

  void _acceptOffer(String driverEmail) async {
    if (!mounted) return;
     socketEvents.startListeningToSocketEvents('bid:accepted','accepted');
    await ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("تم اختيار السائق: $driverEmail")));
    if (widget.onClose != null) widget.onClose!();
  }

  @override
  void dispose() {
    for (var offer in activeOffers) offer.cancelTimer();
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
                            driverItem: item,
                            onAccept: () => _acceptOffer(item.driverId.toString()),
                            onReject: () => item.onRemoveWithAnimation?.call(),
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
