import 'package:flutter/material.dart';
import 'package:map/screen/auth/login_screen.dart';
import 'package:map/screen/driver_screen.dart';
import 'package:map/screen/map_screen.dart';


class AppRoutes {
  static const String login = "/login";
  static const String mapScreen = "/map_screen";
  static const String driverScreen = "/driver_screen";

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    mapScreen: (context) => const MapScreen(),
    driverScreen: (context) => const DriverScreen(driverName: 'name'),
  };
}
