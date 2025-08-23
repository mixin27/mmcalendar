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
import android.view.View
import android.widget.RemoteViews

class DateAndAstroInfoWidget: AppWidgetProvider() {

    override fun onUpdate(
        context: Context?,
        appWidgetManager: AppWidgetManager?,
        appWidgetIds: IntArray?
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        Log.d("DateAstroWidget", "onUpdate() called")

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
        val views = RemoteViews(context.packageName, R.layout.plugin_date_info_widget)

        //            val themePref = prefs.getString("widget_theme", "ThemeMode.system")
//            // check system theme
//            val uiMode = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
//            val isSystemDark = (uiMode == Configuration.UI_MODE_NIGHT_YES)
//            val useDark = when (themePref) {
//                "ThemeMode.light" -> false
//                "ThemeMode.dark" -> true
//                else -> isSystemDark // follow system
//            }

//            val layoutId = when {
//                minWidth < 150 && minHeight < 150 ->
//                    if (useDark) R.layout.calendar_widget_small_dark else R.layout.calendar_widget_small
//                minWidth < 250 ->
//                    if (useDark) R.layout.calendar_widget_medium_dark else R.layout.calendar_widget_medium
//                else ->
//                    if (useDark) R.layout.calendar_widget_large_dark else R.layout.calendar_widget_large
//            }

        val isPublicHoliday = prefs.getString("isPublicHoliday", "");
        val isHoliday = isPublicHoliday.toBoolean();
        if (isHoliday) {
            views.setTextColor(R.id.widget_myanmar_date, Color.parseColor("#FF0000"))
            views.setTextColor(R.id.widget_day_en, Color.parseColor("#FF0000"))
        } else {
            views.setTextColor(R.id.widget_myanmar_date, Color.parseColor("#0000FF"))
            views.setTextColor(R.id.widget_day_en, Color.parseColor("#0000FF"))
        }

        val title = prefs.getString("title", "MyanmarCalendar")
        views.setTextViewText(R.id.widget_title, title)

        val myanmarDate = prefs.getString("myanmar_date_full", "Unknown")
        views.setTextViewText(R.id.widget_myanmar_date, myanmarDate)

//            val myanmarDow = prefs.getString("myanmar_dow", "Unknown")
//            views.setTextViewText(R.id.widget_title, title)

//            val myanmarDay = prefs.getString("myanmar_day", "Unknown")
//            views.setTextViewText(R.id.widget_title, title)

//            val fortnightDay = prefs.getString("fortnightDay", "Unknown")
//            views.setTextViewText(R.id.widget_title, title)



        val dayEn = prefs.getString("en_day", "--")
        views.setTextViewText(R.id.widget_day_en, dayEn);

        val dowEn = prefs.getString("en_dow", "--")
        views.setTextViewText(R.id.widget_dow_en, dowEn);

        val monthAndYearEn = prefs.getString("en_month_year", "--")
        views.setTextViewText(R.id.widget_month_year_en, monthAndYearEn);


        val sabbath = prefs.getString("sabbath", "--")
        if (sabbath == "--") {
            views.setViewVisibility(R.id.widget_sabbath, View.GONE)
        }
        views.setTextViewText(R.id.widget_sabbath, sabbath)

        val astrologicalDay = prefs.getString("astrologicalDay", "--")
        if (astrologicalDay == "--") {
            views.setViewVisibility(R.id.widget_astrology_day, View.GONE)
        }
        views.setTextViewText(R.id.widget_astrology_day, astrologicalDay)

        val nagapor = prefs.getString("nagapor", "--")
        if (nagapor == "--") {
            views.setViewVisibility(R.id.widget_nagapor, View.GONE)
        }
        views.setTextViewText(R.id.widget_nagapor, nagapor)

        val naga = prefs.getString("naga", "--")
        if (naga == "--") {
            views.setViewVisibility(R.id.widget_naga, View.GONE)
        }
        views.setTextViewText(R.id.widget_naga, naga)

        val mahabote = prefs.getString("mahabote", "Unknown")
        views.setTextViewText(R.id.widget_mahabote, mahabote)

        val nakhat = prefs.getString("nakhat", "Unknown")
        views.setTextViewText(R.id.widget_nakhat, nakhat)

        val yearname = prefs.getString("yearname", "Unknown")
        views.setTextViewText(R.id.widget_yearname, yearname)

//            val isPublicHoliday = prefs.getString("isPublicHoliday", "Unknown")
//            val holidays = prefs.getString("holidays", "Unknown")

        val imagePath = prefs.getString("moonPhase", null)

        imagePath?.let {
            val bitmap = BitmapFactory.decodeFile(it)
            views.setImageViewBitmap(R.id.widget_date_info_moon_phase, bitmap)
        }

        val intent = context.packageManager?.getLaunchIntentForPackage(context.packageName)
        val pi = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_IMMUTABLE)
        views.setOnClickPendingIntent(R.id.widget_root, pi)

        manager.updateAppWidget(appWidgetId, views)
    }

    // ----------------------------
    // Midnight update scheduling
    // ----------------------------
    private fun scheduleMidnightUpdate(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val triggerTime = System.currentTimeMillis() + 60 * 1000 // 1 minute

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

//        val calendar = Calendar.getInstance().apply {
//            timeInMillis = System.currentTimeMillis()
//            set(Calendar.HOUR_OF_DAY, 0)
//            set(Calendar.MINUTE, 1)
//            set(Calendar.SECOND, 0)
//            set(Calendar.MILLISECOND, 0)
//
//            // If it's already past 00:01 today, schedule for tomorrow
//            if (before(Calendar.getInstance())) {
//                add(Calendar.DAY_OF_MONTH, 1)
//            }
//        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (alarmManager.canScheduleExactAlarms()) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    pendingIntent
                )
            } else {
                // fallback to inexact
                alarmManager.setRepeating(
                    AlarmManager.RTC_WAKEUP,
                    triggerTime,
                    60000,
                    pendingIntent
                )
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // For Android < 12
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerTime,
                pendingIntent
            )
        } else {
            alarmManager.setExact(
                AlarmManager.RTC_WAKEUP,
                triggerTime,
                pendingIntent
            )
        }

        Log.d("DateAstroWidget", "Alarm is set up.")
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
        Log.d("DateAstroWidget", "Alarm is cancelled.")
    }
}