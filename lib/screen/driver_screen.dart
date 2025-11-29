import 'package:flutter/material.dart';
import 'package:map/widgets/customer_card.dart';
import 'package:map/widgets/price_bottom_sheet.dart';

class DriverScreen extends StatefulWidget {
  final String driverName;
  const DriverScreen({super.key, required this.driverName});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  List<Map<String, dynamic>> customers = [
    {"name": "أحمد", "start": "دمشق", "end": "حلب", "price": 50},
    {"name": "ليلى", "start": "حمص", "end": "دمشق", "price": 35},
    {"name": "فاطمة", "start": "حماه", "end": "حلب", "price": 45},
  ];

  void _openPriceSheet(int index) {
    showPriceBottomSheet(
      context: context,
      currentPrice: customers[index]["price"],
      onSave: (newPrice) {
        setState(() {
          customers[index]["price"] = newPrice;
        });
      },
    );
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
          itemCount: customers.length,
          itemBuilder: (context, index) {
            return CustomerCard(
              customer: customers[index],
              onAccept: () {},
              onReject: () {},
              onChangePrice: () => _openPriceSheet(index),
            );
          },
        ),
      ),
    );
  }
}
