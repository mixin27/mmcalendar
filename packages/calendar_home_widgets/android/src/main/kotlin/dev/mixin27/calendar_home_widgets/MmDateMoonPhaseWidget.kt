package dev.mixin27.calendar_home_widgets

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.Color
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import java.util.Calendar

class MmDateMoonPhaseWidget: AppWidgetProvider() {
    override fun onUpdate(
        context: Context?,
        appWidgetManager: AppWidgetManager?,
        appWidgetIds: IntArray?
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        appWidgetIds?.forEach { updateAppWidget(context!!, appWidgetManager!!, it) }
//        scheduleMidnightUpdate(context!!)
    }

//    override fun onEnabled(context: Context?) {
//        super.onEnabled(context)
//        scheduleMidnightUpdate(context!!)
//    }
//
//    override fun onDisabled(context: Context?) {
//        super.onDisabled(context)
//        cancelMidnightUpdate(context!!)
//    }

    private fun updateAppWidget(context: Context, manager: AppWidgetManager, appWidgetId: Int) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val views = RemoteViews(context.packageName, R.layout.plugin_mmdate_moon_phase_widget)

        val isPublicHoliday = prefs.getString("isPublicHoliday", "");
        val isHoliday = isPublicHoliday.toBoolean();
        if (isHoliday) {
            views.setTextColor(R.id.mmdate_mp_date, Color.parseColor("#FF0000"))
        } else {
            views.setTextColor(R.id.mmdate_mp_date, Color.parseColor("#0000FF"))
        }

        val title = prefs.getString("title", "MyanmarCalendar")
        views.setTextViewText(R.id.mmdate_mp_title, title)

        val myanmarDate = prefs.getString("myanmar_date_full", "Unknown")
        views.setTextViewText(R.id.mmdate_mp_date, myanmarDate)

        val imagePath = prefs.getString("moonPhase", null)

        imagePath?.let {
            val bitmap = BitmapFactory.decodeFile(it)
            views.setImageViewBitmap(R.id.mmdate_mp_moon_phase, bitmap)
        }

        val intent = context.packageManager?.getLaunchIntentForPackage(context.packageName)
        val pi = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_IMMUTABLE)
        views.setOnClickPendingIntent(R.id.mmdate_moon_phase_root, pi)

        manager.updateAppWidget(appWidgetId, views)
    }

    // ----------------------------
    // Midnight update scheduling
    // ----------------------------
    private fun scheduleMidnightUpdate(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        val intent = Intent(context, MoonPhaseWidget::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(
                AppWidgetManager.EXTRA_APPWIDGET_IDS,
                AppWidgetManager.getInstance(context)
                    .getAppWidgetIds(ComponentName(context, MoonPhaseWidget::class.java))
            )
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val calendar = Calendar.getInstance().apply {
            timeInMillis = System.currentTimeMillis()
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 1)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)

            // If it's already past 00:01 today, schedule for tomorrow
            if (before(Calendar.getInstance())) {
                add(Calendar.DAY_OF_MONTH, 1)
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (alarmManager.canScheduleExactAlarms()) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    calendar.timeInMillis,
                    pendingIntent
                )
            } else {
                // fallback to inexact
                alarmManager.setInexactRepeating(
                    AlarmManager.RTC_WAKEUP,
                    calendar.timeInMillis,
                    AlarmManager.INTERVAL_DAY,
                    pendingIntent
                )
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // For Android < 12
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                calendar.timeInMillis,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                calendar.timeInMillis,
                pendingIntent
            )
        }

        Log.d("MmDateMpWidget", "Alarm is set up.")
    }

    private fun cancelMidnightUpdate(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, MoonPhaseWidget::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
        Log.d("MmDateMpWidget", "Alarm is cancelled.")
    }
}