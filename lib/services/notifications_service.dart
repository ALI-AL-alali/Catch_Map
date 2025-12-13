import 'package:flutter/services.dart';

class NativeNotifications {
  static const platform = MethodChannel('ride_notification_channel');

  /// عرض إشعار بالكارد المبسط (السعر وخط التقدم فقط)
  static Future<void> showRideNotification({
    required String price,
    required int progress,
  }) async {
    try {
      await platform.invokeMethod('showRideNotification', {
        "price": price,
        "progress": progress,
      });
    } on PlatformException catch (e) {
      print("Failed to show notification: ${e.message}");
    }
  }
}
