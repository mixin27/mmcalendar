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

            val config = readWidgetConfig(widgetData)
            Log.d(TAG, "Widget config: $config")

            val views = RemoteViews(context.packageName, R.layout.widget_layout_full_calendar)

            // Read configuration
            val showHolidays = widgetData.getBoolean("show_holidays", true)
            val showAstrology = widgetData.getBoolean("show_astrology", false)
            val showLastUpdated = widgetData.getBoolean("show_last_updated", false)
//            val theme = widgetData.getString("widget_theme", "gradientBlue") ?: "gradientBlue"

            // Read data
            val myanmarDate = widgetData.getString("myanmar_date", "") ?: ""
            val westernDate = widgetData.getString("western_date", "") ?: ""
            val moonPhase = widgetData.getString("moon_phase", "") ?: ""
            val fortnightDay = widgetData.getString("fortnight_day", "") ?: ""
            val fortnightDayText = widgetData.getString("fortnight_day_text", "") ?: ""
            val holidays = widgetData.getString("holidays", "") ?: ""
            val astroInfo = buildAstrologyText(widgetData)
            val lastUpdated = widgetData.getString("last_updated", "") ?: ""

            // Parse Western date into components
            val (day, month, year) = parseWesternDateFull(westernDate)

            // Update Western date
            views.setTextViewText(R.id.western_day, day)
            views.setTextViewText(R.id.western_month, month)
            views.setTextViewText(R.id.western_year, year)

            // Update Myanmar date
            views.setTextViewText(R.id.myanmar_date, myanmarDate)

            // Load moon phase image
            loadMoonPhaseImage(context, views, widgetData)

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
            val isToday = isToday(widgetData)
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

    private fun loadMoonPhaseImage(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences
    ) {
        try {
            val imagePath = widgetData.getString("moon_phase_image_path", null)
            imagePath?.let {
                val file = File(it)
                if (file.exists()) {
                    val bitmap = BitmapFactory.decodeFile(it)
                    views.setImageViewBitmap(R.id.moon_phase_image, bitmap)
                    views.setViewVisibility(R.id.moon_phase_image, View.VISIBLE)
                    Log.d(TAG, "✅ Moon phase image loaded")
                } else {
                    Log.w(TAG, "⚠️ Moon phase image file not found")
                    views.setViewVisibility(R.id.moon_phase_image, View.GONE)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error loading moon phase image", e)
            views.setViewVisibility(R.id.moon_phase_image, View.GONE)
        }
    }

    private fun buildAstrologyText(widgetData: SharedPreferences): String {
        val items = mutableListOf<String>()

        val sabbath = widgetData.getString("sabbath_info", "")
        val yatyaza = widgetData.getString("yatyaza_info", "")
        val pyathada = widgetData.getString("pyathada_info", "")
        val astroDays = widgetData.getString("astrological_days", "")

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
            // "light" -> R.drawable.widget_background_light
            "traditional" -> R.drawable.widget_background_traditional
            "gradientPurple" -> R.drawable.widget_background_gradient_purple
            "gradientTeal" -> R.drawable.widget_background_gradient_teal
            else -> R.drawable.widget_bg_full // default blue gradient
        }

        views.setInt(R.id.widget_root, "setBackgroundResource", bgDrawable)

        // Text colors are already white in XML for gradient themes
        // For light theme, you'd need to update text colors
        /*
        if (theme == "light") {
            views.setTextColor(R.id.western_day, "#1A1A1A".toColorInt())
            views.setTextColor(R.id.western_month, "#666666".toColorInt())
            views.setTextColor(R.id.western_year, "#666666".toColorInt())
            views.setTextColor(R.id.myanmar_date, "#1A1A1A".toColorInt())
            views.setTextColor(R.id.moon_phase_name, "#FF6F00".toColorInt())
            views.setTextColor(R.id.fortnight_day, "#666666".toColorInt())
        }
        */
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