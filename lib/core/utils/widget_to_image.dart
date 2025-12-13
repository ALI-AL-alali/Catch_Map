import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

class WidgetToImage {
  final ScreenshotController _controller = ScreenshotController();

  /// يلتقط صورة من أي Widget ويرجع Uint8List جاهزة للاستخدام
  Future<Uint8List?> captureWidget(Widget widget) async {
    return await _controller.captureFromWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 400, // أقصى عرض للكارد
                maxHeight: 600, // أقصى ارتفاع للكارد
              ),
              child: widget,
            ),
          ),
        ),
      ),
      delay: const Duration(milliseconds: 300),
      pixelRatio: 3, // جودة الصورة
    );
  }
}
