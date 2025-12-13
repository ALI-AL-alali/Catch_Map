package com.example.map

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "ride_notification_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // إنشاء قناة الإشعارات
        createRideChannel()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "showRideNotification") {
                val price = call.argument<String>("price") ?: "250000"
                val progress = call.argument<Int>("progress") ?: 50
                showRideNotification(price, progress)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun createRideChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Ride Progress"
            val descriptionText = "Ongoing ride notification"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL, name, importance).apply {
                description = descriptionText
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            }

            val manager: NotificationManager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun showRideNotification(price: String, progress: Int) {
        val remoteViews = RemoteViews(packageName, R.layout.ride_progress_card)

        // فقط السعر والخط المتحرك، إزالة أي نصوص غير مستخدمة
        remoteViews.setTextViewText(R.id.priceText, price)
        remoteViews.setProgressBar(R.id.progressBar, 100, progress, false)

        val builder = NotificationCompat.Builder(this, CHANNEL)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setCustomContentView(remoteViews)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setOngoing(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        with(NotificationManagerCompat.from(this)) {
            notify(1, builder.build())
        }
    }
}
