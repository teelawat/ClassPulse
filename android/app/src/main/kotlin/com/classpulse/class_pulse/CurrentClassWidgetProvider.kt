package com.classpulse.class_pulse

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class CurrentClassWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.current_class_widget_layout)

            // Read preferences written by home_widget Dart library
            val prefs = HomeWidgetPlugin.getData(context)
            val subject = prefs.getString("current_subject", "ไม่มีคาบเรียนขณะนี้") ?: "ไม่มีคาบเรียนขณะนี้"
            val teacher = prefs.getString("current_teacher", "-") ?: "-"
            val time = prefs.getString("current_time", "-") ?: "-"
            val status = prefs.getString("current_status", "ไม่มีเรียนแล้ววันนี้") ?: "ไม่มีเรียนแล้ววันนี้"

            // Update Views
            views.setTextViewText(R.id.widget_subject, subject)
            views.setTextViewText(R.id.widget_teacher, teacher)
            views.setTextViewText(R.id.widget_time, time)
            views.setTextViewText(R.id.widget_status, status)

            // Setup click intent to launch MainActivity
            val intent = Intent(context, MainActivity::class.java)
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val pendingIntent = PendingIntent.getActivity(context, 0, intent, flags)
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
