import 'package:flutter/material.dart';
import 'package:map/screen/user_selection_screen.dart';
import 'services/notifications_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await initNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Catch Bidding',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const UserSelectionScreen(),
    );
  }
}
