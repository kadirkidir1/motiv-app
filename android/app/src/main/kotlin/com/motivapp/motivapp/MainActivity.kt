package com.motivapp.motivapp

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import android.app.NotificationChannel
import android.app.NotificationManager

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.motivapp.motivapp/alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val delaySeconds = call.argument<Int>("delaySeconds") ?: 10
                    val title = call.argument<String>("title") ?: "Test"
                    val body = call.argument<String>("body") ?: "Bildirim"
                    scheduleAlarm(delaySeconds, title, body)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun scheduleAlarm(delaySeconds: Int, title: String, body: String) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        
        // Bildirim türüne göre sabit request code kullan
        val requestCode = when {
            title.contains("Günaydın") || title.contains("Good Morning") -> 1001
            title.contains("Gün Sonu") || title.contains("End of Day") -> 1002
            title.contains("Serinizi") || title.contains("Keep Your Streak") -> 1003
            title.contains("Görev") || title.contains("Task") -> title.hashCode()
            else -> title.hashCode()
        }
        
        val intent = Intent(this, AlarmReceiver::class.java).apply {
            putExtra("title", title)
            putExtra("body", body)
            putExtra("requestCode", requestCode)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val triggerTime = System.currentTimeMillis() + (delaySeconds * 1000L)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (alarmManager.canScheduleExactAlarms()) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
            }
        } else {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
        }
    }
}

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val title = intent.getStringExtra("title") ?: "Bildirim"
        val body = intent.getStringExtra("body") ?: "Test"
        val requestCode = intent.getIntExtra("requestCode", 0)
        
        createNotificationChannel(context)
        
        // Bildirime tıklayınca uygulamayı aç
        val appIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            appIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(context, "alarm_channel")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        NotificationManagerCompat.from(context).notify(requestCode, notification)
    }
    
    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "alarm_channel",
                "Alarm Notifications",
                NotificationManager.IMPORTANCE_HIGH
            )
            val notificationManager = context.getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
}
