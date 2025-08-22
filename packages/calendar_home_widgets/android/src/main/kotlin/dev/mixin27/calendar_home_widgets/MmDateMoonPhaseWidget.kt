package dev.mixin27.calendar_home_widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.BitmapFactory
import android.graphics.Color
import android.widget.RemoteViews

class MmDateMoonPhaseWidget: AppWidgetProvider() {
    override fun onUpdate(
        context: Context?,
        appWidgetManager: AppWidgetManager?,
        appWidgetIds: IntArray?
    ) {
        val prefs = context?.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val views = RemoteViews(context?.packageName, R.layout.plugin_mmdate_moon_phase_widget)

        if (prefs != null) {
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
        }

        val intent = context?.packageManager?.getLaunchIntentForPackage(context.packageName)
        val pi = PendingIntent.getActivity(context!!, 0, intent, PendingIntent.FLAG_IMMUTABLE)
        views.setOnClickPendingIntent(R.id.mmdate_moon_phase_root, pi)
        appWidgetIds?.forEach { appWidgetManager?.updateAppWidget(it, views) }
    }
}