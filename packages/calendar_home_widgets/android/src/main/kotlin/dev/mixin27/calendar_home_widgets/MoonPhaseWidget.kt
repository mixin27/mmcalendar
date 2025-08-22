package dev.mixin27.calendar_home_widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.BitmapFactory
import android.widget.RemoteViews

class MoonPhaseWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context?,
        appWidgetManager: AppWidgetManager?,
        appWidgetIds: IntArray?
    ) {
        val prefs = context?.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val views = RemoteViews(context?.packageName, R.layout.plugin_moon_phase_widget)

        if (prefs != null) {
            val moonPhaseTitle = prefs.getString("moonPhaseTitle", "MyanmarCalendar")
            views.setTextViewText(R.id.moon_phase_title, moonPhaseTitle)

            val moonPhaseText = prefs.getString("moonPhaseMM", "--")
            views.setTextViewText(R.id.moon_phase_text, moonPhaseText)

            val imagePath = prefs.getString("moonPhase", null)

            imagePath?.let {
                val bitmap = BitmapFactory.decodeFile(it)
                views.setImageViewBitmap(R.id.widget_moon_phase, bitmap)
            }

        }

        val intent = context?.packageManager?.getLaunchIntentForPackage(context.packageName)
        val pi = PendingIntent.getActivity(context!!, 0, intent, PendingIntent.FLAG_IMMUTABLE)
        views.setOnClickPendingIntent(R.id.moon_phase_root, pi)
        appWidgetIds?.forEach { appWidgetManager?.updateAppWidget(it, views) }
    }
}