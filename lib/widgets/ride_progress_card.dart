import 'package:flutter/material.dart';

class RideProgressCard extends StatefulWidget {
  final String eta;
  final String price;
  final String plate;
  final double progress;

  const RideProgressCard({
    super.key,
    required this.eta,
    required this.price,
    required this.plate,
    required this.progress,
  });

  @override
  State<RideProgressCard> createState() => _RideProgressCardState();
}

class _RideProgressCardState extends State<RideProgressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _animation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutQuart),
    );
  }

  @override
  void didUpdateWidget(covariant RideProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(begin: _animation.value, end: widget.progress)
          .animate(
            CurvedAnimation(
              parent: _animController,
              curve: Curves.easeOutQuart,
            ),
          );
      _animController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final green = Colors.green;
    final trackWidth = MediaQuery.of(context).size.width - 64;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: green.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car, size: 26),
              const SizedBox(width: 6),
              const Text(
                "Catch",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.place, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.timer, size: 14, color: Colors.black54),
                        const SizedBox(width: 6),
                        Text(
                          'ETA ${widget.eta}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "استمتع برحلتك 🛣️",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.plate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.price,
                    style: TextStyle(
                      color: green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final val = _animation.value.clamp(0.0, 1.0);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: val,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Positioned(
                    left: trackWidth * val - 12,
                    top: -18,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.directions_car, color: green),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
