package com.classpulse.class_pulse

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class TodayScheduleWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.today_schedule_widget_layout)

            // Read preferences
            val prefs = HomeWidgetPlugin.getData(context)
            val dayTitle = prefs.getString("today_day_title", "ตารางเรียนวันนี้") ?: "ตารางเรียนวันนี้"
            val slotsCount = prefs.getInt("today_slots_count", 0)

            views.setTextViewText(R.id.widget_day_title, dayTitle)

            if (slotsCount == 0) {
                // Show placeholder, hide schedule rows
                views.setViewVisibility(R.id.widget_placeholder, View.VISIBLE)
                views.setViewVisibility(R.id.widget_rows_container, View.GONE)
            } else {
                // Show schedule rows, hide placeholder
                views.setViewVisibility(R.id.widget_placeholder, View.GONE)
                views.setViewVisibility(R.id.widget_rows_container, View.VISIBLE)

                // Row 1
                views.setViewVisibility(R.id.row1, View.VISIBLE)
                val s1Subject = prefs.getString("slot1_subject", "-") ?: "-"
                val s1Time = prefs.getString("slot1_time", "-") ?: "-"
                val s1Badge = prefs.getString("slot1_badge", "") ?: ""
                views.setTextViewText(R.id.slot1_subject, s1Subject)
                views.setTextViewText(R.id.slot1_time, s1Time)
                views.setTextViewText(R.id.slot1_badge, s1Badge)
                styleBadge(views, R.id.slot1_badge, s1Badge)

                // Divider 1 & Row 2
                if (slotsCount >= 2) {
                    views.setViewVisibility(R.id.divider1, View.VISIBLE)
                    views.setViewVisibility(R.id.row2, View.VISIBLE)
                    val s2Subject = prefs.getString("slot2_subject", "-") ?: "-"
                    val s2Time = prefs.getString("slot2_time", "-") ?: "-"
                    val s2Badge = prefs.getString("slot2_badge", "") ?: ""
                    views.setTextViewText(R.id.slot2_subject, s2Subject)
                    views.setTextViewText(R.id.slot2_time, s2Time)
                    views.setTextViewText(R.id.slot2_badge, s2Badge)
                    styleBadge(views, R.id.slot2_badge, s2Badge)
                } else {
                    views.setViewVisibility(R.id.divider1, View.GONE)
                    views.setViewVisibility(R.id.row2, View.GONE)
                }

                // Divider 2 & Row 3
                if (slotsCount >= 3) {
                    views.setViewVisibility(R.id.divider2, View.VISIBLE)
                    views.setViewVisibility(R.id.row3, View.VISIBLE)
                    val s3Subject = prefs.getString("slot3_subject", "-") ?: "-"
                    val s3Time = prefs.getString("slot3_time", "-") ?: "-"
                    val s3Badge = prefs.getString("slot3_badge", "") ?: ""
                    views.setTextViewText(R.id.slot3_subject, s3Subject)
                    views.setTextViewText(R.id.slot3_time, s3Time)
                    views.setTextViewText(R.id.slot3_badge, s3Badge)
                    styleBadge(views, R.id.slot3_badge, s3Badge)
                } else {
                    views.setViewVisibility(R.id.divider2, View.GONE)
                    views.setViewVisibility(R.id.row3, View.GONE)
                }
            }

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

    private fun styleBadge(views: RemoteViews, viewId: Int, badgeText: String) {
        when (badgeText) {
            "เรียนอยู่", "กำลังเรียน" -> {
                views.setInt(viewId, "setBackgroundResource", R.drawable.widget_badge_current_bg)
                views.setTextColor(viewId, android.graphics.Color.parseColor("#FF1B5E20")) // Dark green text
            }
            "ถัดไป" -> {
                views.setInt(viewId, "setBackgroundResource", R.drawable.widget_badge_next_bg)
                views.setTextColor(viewId, android.graphics.Color.parseColor("#FFE65100")) // Dark orange text
            }
            else -> {
                // Completed, break, or other status
                views.setInt(viewId, "setBackgroundResource", R.drawable.widget_status_badge_bg)
                // Set color to slate-600 or white semi-transparent
                views.setTextColor(viewId, android.graphics.Color.parseColor("#FF64748B"))
            }
        }
    }
}
