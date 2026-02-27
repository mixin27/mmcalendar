package dev.mixin27.mmcalendar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import androidx.core.graphics.toColorInt
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

/**
 * Full Calendar Widget Provider (4x2 or 4x3)
 *
 * Purpose: Complete date information with beautiful moon phase
 * Features:
 * - Myanmar date
 * - Western date (day, month, year)
 * - Moon phase with glow effect
 * - Holidays
 * - Astrology info
 * - Today badge
 * - Last updated timestamp
 */
class FullCalendarWidgetProvider : HomeWidgetProvider() {
    companion object {
        private const val TAG = "FullCalendarWidget"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        Log.d(TAG, "onUpdate called for ${appWidgetIds.size} full calendar widgets")
        appWidgetIds.forEach { widgetId ->
            updateWidget(context, appWidgetManager, widgetId, widgetData)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences
    ) {
        try {
            Log.d(TAG, "Updating full calendar widget $widgetId")

            val dataReader = WidgetDataReader(widgetData)
            val config = readWidgetConfig(widgetData)
            Log.d(TAG, "Widget config: $config")

            val views = RemoteViews(context.packageName, R.layout.widget_layout_full_calendar)

            // Read configuration
            val showHolidays = widgetData.getBoolean("show_holidays", true)
            val showAstrology = widgetData.getBoolean("show_astrology", false)
            val showLastUpdated = widgetData.getBoolean("show_last_updated", false)

            // Read data
            val myanmarDate = dataReader.getString("myanmar_date")
            val westernDate = dataReader.getString("western_date")
            val moonPhase = dataReader.getString("moon_phase")
            val fortnightDayText = dataReader.getString("fortnight_day_text")
            val holidays = dataReader.getString("holidays")
            val astroInfo = buildAstrologyText(dataReader)
            val lastUpdated = dataReader.getString("last_updated")

            // Parse Western date into components
            val (day, month, year) = parseWesternDateFull(westernDate)

            // Update Western date
            views.setTextViewText(R.id.western_day, day)
            views.setTextViewText(R.id.western_month, month)
            views.setTextViewText(R.id.western_year, year)

            // Update Myanmar date
            views.setTextViewText(R.id.myanmar_date, myanmarDate)

            // Load moon phase image
            loadMoonPhaseImage(views, dataReader.getString("moon_phase_image_path"))

            // Update moon phase name
            views.setTextViewText(R.id.moon_phase_name, moonPhase)

            // Update fortnight day
            views.setTextViewText(R.id.fortnight_day, fortnightDayText)

            // Holidays
            if (showHolidays && holidays.isNotEmpty() && holidays != "null") {
                views.setTextViewText(R.id.holidays, "🎉 $holidays")
                views.setViewVisibility(R.id.holidays, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.holidays, View.GONE)
            }

            // Astrology
            if (showAstrology && astroInfo.isNotEmpty()) {
                views.setTextViewText(R.id.astrology_info, astroInfo)
                views.setViewVisibility(R.id.astrology_info, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.astrology_info, View.GONE)
            }

            // Today badge
            val isToday = dataReader.hasTimelineData() || isToday(widgetData)
            views.setViewVisibility(
                R.id.today_badge,
                if (isToday) View.VISIBLE else View.GONE
            )

            // Last updated
            if (showLastUpdated && lastUpdated.isNotEmpty()) {
                views.setTextViewText(R.id.last_updated, "Updated: $lastUpdated")
                views.setViewVisibility(R.id.last_updated, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.last_updated, View.GONE)
            }

            // Apply theme
            applyTheme(views, config.theme)

            // Set up click handler
            setupClickHandler(context, views, widgetId)

            // Update widget
            appWidgetManager.updateAppWidget(widgetId, views)
            Log.d(TAG, "Full calendar widget $widgetId updated successfully")

        } catch (e: Exception) {
            Log.e(TAG, "Error updating full calendar widget $widgetId", e)
        }
    }

    private fun parseWesternDateFull(westernDate: String): Triple<String, String, String> {
        return try {
            // Expected format: "12 December 2024"
            val parts = westernDate.split(" ")
            if (parts.size >= 3) {
                val day = parts[0]
                val month = parts[1]
                val year = parts[2]
                Triple(day, month, year)
            } else {
                Triple("--", "---", "----")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing western date: $westernDate", e)
            Triple("--", "---", "----")
        }
    }

    private fun loadMoonPhaseImage(views: RemoteViews, imagePath: String) {
        try {
            if (imagePath.isNotEmpty()) {
                val file = File(imagePath)
                if (file.exists()) {
                    val bitmap = BitmapFactory.decodeFile(imagePath)
                    views.setImageViewBitmap(R.id.moon_phase_image, bitmap)
                    views.setViewVisibility(R.id.moon_phase_image, View.VISIBLE)
                    Log.d(TAG, "✅ Moon phase image loaded")
                    return
                }
            }
            Log.w(TAG, "⚠️ Moon phase image file not found")
            views.setViewVisibility(R.id.moon_phase_image, View.GONE)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error loading moon phase image", e)
            views.setViewVisibility(R.id.moon_phase_image, View.GONE)
        }
    }

    private fun buildAstrologyText(dataReader: WidgetDataReader): String {
        val items = mutableListOf<String>()

        val sabbath = dataReader.getString("sabbath_info")
        val yatyaza = dataReader.getString("yatyaza_info")
        val pyathada = dataReader.getString("pyathada_info")
        val astroDays = dataReader.getString("astrological_days")

        if (!sabbath.isNullOrEmpty() && sabbath != "null") items.add(sabbath)
        if (!yatyaza.isNullOrEmpty() && yatyaza != "null") items.add(yatyaza)
        if (!pyathada.isNullOrEmpty() && pyathada != "null") items.add(pyathada)

        if (!astroDays.isNullOrEmpty() && astroDays != "null") {
            items.addAll(astroDays.split(",").map { it.trim() })
        }

        return items.joinToString(" • ")
    }

    private fun isToday(widgetData: SharedPreferences): Boolean {
        // You can implement proper date comparison here
        val lastUpdated = widgetData.getString("last_updated", "") ?: ""
        return lastUpdated.isNotEmpty()
    }


    private fun readWidgetConfig(prefs: SharedPreferences): WidgetConfig {
        val size = prefs.getString("widget_size", "medium") ?: "medium"
        val theme = prefs.getString("widget_theme", "light") ?: "light"

        // Check if data exists to determine visibility
        val hasMyanmarDate = !prefs.getString("myanmar_date", "").isNullOrEmpty()
        val hasWesternDate = !prefs.getString("western_date", "").isNullOrEmpty()
        val hasHolidays = !prefs.getString("holidays", "").isNullOrEmpty()
        val hasAstrology = (
                !prefs.getString("sabbath_info", "").isNullOrEmpty() ||
                        !prefs.getString("yatyaza_info", "").isNullOrEmpty() ||
                        !prefs.getString("pyathada_info", "").isNullOrEmpty() ||
                        !prefs.getString("astrological_days", "").isNullOrEmpty()
                )

        return WidgetConfig(
            size = size,
            theme = theme,
            showMyanmarDate = hasMyanmarDate,
            showWesternDate = hasWesternDate,
            showHolidays = hasHolidays,
            showAstrology = hasAstrology,
            language = prefs.getString("widget_language", "my") ?: "my"
        )
    }
    private fun applyTheme(views: RemoteViews, theme: String) {
        val bgDrawable = when (theme) {
            "dark" -> R.drawable.widget_background_dark
            "light" -> R.drawable.widget_background_light
            "traditional" -> R.drawable.widget_background_traditional
            "gradientPurple" -> R.drawable.widget_background_gradient_purple
            "gradientTeal" -> R.drawable.widget_background_gradient_teal
            else -> R.drawable.widget_bg_full // default blue gradient
        }

        views.setInt(R.id.widget_root, "setBackgroundResource", bgDrawable)

        val isLightTheme = theme == "light"
        val primaryText = if (isLightTheme) "#1C2430" else "#F7FBFF"
        val secondaryText = if (isLightTheme) "#5E6C80" else "#E6EEF8"
        val accentText = if (isLightTheme) "#A86800" else "#FFE08A"

        views.setTextColor(R.id.widget_title, secondaryText.toColorInt())
        views.setTextColor(R.id.western_day, primaryText.toColorInt())
        views.setTextColor(R.id.western_month, secondaryText.toColorInt())
        views.setTextColor(R.id.western_year, secondaryText.toColorInt())
        views.setTextColor(R.id.myanmar_date, primaryText.toColorInt())
        views.setTextColor(R.id.holidays, accentText.toColorInt())
        views.setTextColor(R.id.moon_phase_name, accentText.toColorInt())
        views.setTextColor(R.id.fortnight_day, secondaryText.toColorInt())
        views.setTextColor(R.id.astrology_info, secondaryText.toColorInt())
        views.setTextColor(R.id.last_updated, secondaryText.toColorInt())
    }

    private fun setupClickHandler(
        context: Context,
        views: RemoteViews,
        widgetId: Int
    ) {
        try {
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                launchIntent.putExtra("opened_from_widget", true)
                launchIntent.putExtra("widget_id", widgetId)
                launchIntent.putExtra("widget_type", "full_calendar")

                val flags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }

                val pendingIntent = PendingIntent.getActivity(
                    context,
                    widgetId,
                    launchIntent,
                    flags
                )

                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error setting up click handler", e)
        }
    }

    private data class WidgetConfig(
        val size: String,
        val theme: String,
        val showMyanmarDate: Boolean,
        val showWesternDate: Boolean,
        val showHolidays: Boolean,
        val showAstrology: Boolean,
        val language: String
    )

}
