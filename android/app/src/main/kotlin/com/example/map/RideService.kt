package com.example.map

import android.app.*
import android.content.Intent
import android.os.IBinder
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat

class RideService : Service() {

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {

        val remoteViews = RemoteViews(packageName, R.layout.ride_notification)
        remoteViews.setTextViewText(R.id.txtEta, "ETA 10 min")
        remoteViews.setTextViewText(R.id.txtPlate, "Plate 123456")
        remoteViews.setProgressBar(R.id.progressRide, 100, 50, false)

        val notification = NotificationCompat.Builder(this, "ride_channel")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setCustomContentView(remoteViews)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()

        startForeground(1, notification)

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
