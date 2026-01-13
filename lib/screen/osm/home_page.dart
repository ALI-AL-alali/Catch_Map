import 'package:flutter/material.dart';
import 'package:map/screen/osm/map_screen_flutter_map.dart';
import 'map_search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String? startPoint;
  String? endPoint;
  double? startLatitude;
  double? startLongitude;
  double? endLatitude;
  double? endLongitude;

  late final AnimationController _screenAnim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _screenAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(parent: _screenAnim, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _screenAnim, curve: Curves.easeOutCubic));

    _screenAnim.forward();
  }

  @override
  void dispose() {
    _screenAnim.dispose();
    super.dispose();
  }

  // فتح الخريطة لاختيار نقطة البداية أو النهاية
  Future<void> _selectLocation(bool isStartPoint) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapSearchPage()),
    );

    if (result != null) {
      setState(() {
        if (isStartPoint) {
          startPoint = result['name'];
          startLatitude = result['latitude'];
          startLongitude = result['longitude'];
        } else {
          endPoint = result['name'];
          endLatitude = result['latitude'];
          endLongitude = result['longitude'];
        }
      });
    }
  }

  bool get _canRequest =>
      startPoint != null &&
      endPoint != null &&
      startLatitude != null &&
      startLongitude != null &&
      endLatitude != null &&
      endLongitude != null;

  void _goToRoute() {
    if (!_canRequest) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapRoutePage(
          startPoint: startPoint!,
          endPoint: endPoint!,
          startLatitude: startLatitude!,
          startLongitude: startLongitude!,
          endLatitude: endLatitude!,
          endLongitude: endLongitude!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('نقطة البداية والنهاية'),
          centerTitle: true,
          elevation: 0,
        ),
        body: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              children: [
                _HeaderCard(
                  title: "اختر مسار رحلتك",
                  subtitle:
                      "اضغط على الحقول لتحديد نقطة البداية ونقطة الوصول ثم اضغط طلب.",
                  icon: Icons.route,
                ),
                const SizedBox(height: 14),

                _LocationCard(
                  title: "نقطة البداية",
                  value: startPoint,
                  icon: Icons.my_location,
                  accent: Colors.green,
                  onTap: () => _selectLocation(true),
                ),
                const SizedBox(height: 12),

                _LocationCard(
                  title: "نقطة الوصول",
                  value: endPoint,
                  icon: Icons.flag,
                  accent: Colors.red,
                  onTap: () => _selectLocation(false),
                ),

                const SizedBox(height: 18),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _canRequest
                      ? _SummaryCard(
                          key: const ValueKey("summary_on"),
                          start: startPoint!,
                          end: endPoint!,
                        )
                      : _HintCard(
                          key: const ValueKey("summary_off"),
                          text:
                              "اختر نقطتين ليتفعّل زر الطلب ويظهر ملخص الرحلة هنا.",
                        ),
                ),

                const SizedBox(height: 18),

                _AnimatedActionButton(
                  enabled: _canRequest,
                  onPressed: _goToRoute,
                  text: "طلب",
                  icon: Icons.local_taxi,
                ),

                const SizedBox(height: 10),

                Center(
                  child: Text(
                    "يمكنك تعديل النقاط في أي وقت بالضغط على الحقول.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== UI Widgets =====================

class _HeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.green.withOpacity(0.12),
            Colors.black.withOpacity(0.03),
          ],
        ),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.green.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final String title;
  final String? value;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _LocationCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = (value != null && value!.trim().isNotEmpty);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1.2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: hasValue
                          ? Text(
                              value!,
                              key: const ValueKey("val"),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black87),
                            )
                          : Text(
                              "اضغط للاختيار...",
                              key: const ValueKey("hint"),
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.45),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_left, color: Colors.black.withOpacity(0.35)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  final String text;

  const _HintCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.withOpacity(0.08),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.black.withOpacity(0.55)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black54, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String start;
  final String end;

  const _SummaryCard({super.key, required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            spreadRadius: 0,
            offset: Offset(0, 6),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ملخص المسار",
            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _SummaryRow(label: "من", value: start, icon: Icons.my_location),
          const SizedBox(height: 8),
          _SummaryRow(label: "إلى", value: end, icon: Icons.flag),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _AnimatedActionButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onPressed;
  final String text;
  final IconData icon;

  const _AnimatedActionButton({
    required this.enabled,
    required this.onPressed,
    required this.text,
    required this.icon,
  });

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapCtrl;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.06,
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _tapCtrl,
      builder: (context, child) {
        final scale = 1 - _tapCtrl.value;
        return Transform.scale(scale: scale, child: child);
      },
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: widget.enabled
              ? () async {
                  await _tapCtrl.forward();
                  await _tapCtrl.reverse();
                  widget.onPressed();
                }
              : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.green,
            disabledBackgroundColor: Colors.green.withOpacity(0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: widget.enabled ? 3 : 0,
          ),
          icon: Icon(widget.icon, color: Colors.white),
          label: Text(
            widget.text,
            style: const TextStyle(
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
