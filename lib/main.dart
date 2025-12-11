import 'package:flutter/material.dart';
import 'package:map/core/helpers/app_routes.dart';

// import 'package:map/screen/map_screen.dart';
import 'package:map/screen/user_selection_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const UserSelectionScreen(),
      // initialRoute: AppRoutes.login,
      // routes: AppRoutes.routes,
    );
  }
}
