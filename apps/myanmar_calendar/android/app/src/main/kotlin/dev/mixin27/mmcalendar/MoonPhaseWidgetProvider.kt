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
 * Moon Phase Widget Provider (2x2)
 *
 * Purpose: Beautiful moon phase display with minimal text
 * Features:
 * - Large moon visual with glow effect
 * - Moon phase name
 * - Fortnight day
 * - Myanmar date (compact)
 * - Next phase countdown (optional)
 */
class MoonPhaseWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val TAG = "MoonPhaseWidget"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        Log.d(TAG, "onUpdate called for ${appWidgetIds.size} moon phase widgets")
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
            Log.d(TAG, "Updating moon phase widget $widgetId")

            val views = RemoteViews(context.packageName, R.layout.widget_layout_moon_phase)

            // Read data
            val myanmarDate = widgetData.getString("myanmar_date", "") ?: ""
            val moonPhase = widgetData.getString("moon_phase", "") ?: ""
            val fortnightDay = widgetData.getString("fortnight_day", "") ?: ""
            val moonPhaseValue = widgetData.getInt("moon_phase_value", 0)
            val theme = widgetData.getString("widget_theme", "dark") ?: "dark"

            // Extract compact Myanmar date (month and day only)
            val compactMyanmarDate = extractCompactMyanmarDate(myanmarDate)

            // Update Myanmar date (compact)
            views.setTextViewText(R.id.myanmar_date_compact, compactMyanmarDate)

            // Load moon phase image
            loadMoonPhaseImage(context, views, widgetData)

            // Update moon phase name
            views.setTextViewText(R.id.moon_phase_name, moonPhase)

            // Update fortnight day
            val fortnightText = formatFortnightDay(fortnightDay)
            views.setTextViewText(R.id.fortnight_day, fortnightText)

            // Calculate and display next phase
            val nextPhaseInfo = calculateNextPhase(moonPhaseValue, fortnightDay.toIntOrNull() ?: 1)
            views.setTextViewText(R.id.next_phase, nextPhaseInfo)

            // Apply theme
            applyTheme(views, theme)

            // Set up click handler
            setupClickHandler(context, views, widgetId)

            // Update widget
            appWidgetManager.updateAppWidget(widgetId, views)
            Log.d(TAG, "Moon phase widget $widgetId updated successfully")

        } catch (e: Exception) {
            Log.e(TAG, "Error updating moon phase widget $widgetId", e)
        }
    }

    /**
     * Extract compact Myanmar date (remove year)
     * Example: "၁၃၈၆ နတ်တော် လဆုတ် ၈ ရက်" -> "နတ်တော် လဆုတ် ၈"
     */
    private fun extractCompactMyanmarDate(fullDate: String): String {
        return try {
            val parts = fullDate.split(" ")
            if (parts.size >= 4) {
                // Skip year (first part), join month and fortnight
                "${parts[1]} ${parts[2]} ${parts[3]}"
            } else {
                fullDate
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting compact Myanmar date", e)
            fullDate
        }
    }

    /**
     * Format fortnight day with Myanmar number
     * Example: "8" -> "၈ ရက်"
     */
    private fun formatFortnightDay(fortnightDay: String): String {
        return try {
            val day = fortnightDay.toIntOrNull() ?: return fortnightDay
            val myanmarDay = convertToMyanmarNumber(day)
            "$myanmarDay ရက်"
        } catch (e: Exception) {
            Log.e(TAG, "Error formatting fortnight day", e)
            fortnightDay
        }
    }

    /**
     * Convert number to Myanmar numerals
     */
    private fun convertToMyanmarNumber(number: Int): String {
        val myanmarDigits = arrayOf("၀", "၁", "၂", "၃", "၄", "၅", "၆", "၇", "၈", "၉")
        return number.toString().map { myanmarDigits[it.toString().toInt()] }.joinToString("")
    }

    /**
     * Calculate next moon phase
     * 0 = Waxing, 1 = Full Moon, 2 = Waning, 3 = New Moon
     */
    private fun calculateNextPhase(currentPhase: Int, fortnightDay: Int): String {
        return try {
            when (currentPhase) {
                0 -> { // Waxing
                    val daysToFull = 15 - fortnightDay
                    "Full Moon in ${daysToFull}d"
                }
                1 -> { // Full Moon
                    "New Moon in 15d"
                }
                2 -> { // Waning
                    val daysToNew = 15 - fortnightDay
                    "New Moon in ${daysToNew}d"
                }
                3 -> { // New Moon
                    "Full Moon in 15d"
                }
                else -> ""
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error calculating next phase", e)
            ""
        }
    }

    /**
     * Load moon phase image with glow effect
     */
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
                    views.setViewVisibility(R.id.moon_outer_glow, View.VISIBLE)
                    Log.d(TAG, "✅ Moon phase image loaded")
                } else {
                    Log.w(TAG, "⚠️ Moon phase image file not found")
                    views.setViewVisibility(R.id.moon_phase_image, View.GONE)
                    views.setViewVisibility(R.id.moon_outer_glow, View.GONE)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error loading moon phase image", e)
            views.setViewVisibility(R.id.moon_phase_image, View.GONE)
            views.setViewVisibility(R.id.moon_outer_glow, View.GONE)
        }
    }

    /**
     * Apply theme to widget
     */
    private fun applyTheme(views: RemoteViews, theme: String) {
        val bgDrawable = when (theme) {
            "light" -> R.drawable.widget_background_light
            "traditional" -> R.drawable.widget_background_traditional
            "gradientBlue" -> R.drawable.widget_background_gradient_blue
            "gradientPurple" -> R.drawable.widget_background_gradient_purple
            "gradientTeal" -> R.drawable.widget_background_gradient_teal
            else -> R.drawable.widget_bg_moon // default dark
        }

        views.setInt(R.id.widget_root, "setBackgroundResource", bgDrawable)

        // Adjust text colors for light theme
        if (theme == "light") {
            views.setTextColor(R.id.myanmar_date_compact, "#666666".toColorInt())
            views.setTextColor(R.id.moon_phase_name, "#1A1A1A".toColorInt())
            views.setTextColor(R.id.fortnight_day, "#666666".toColorInt())
            views.setTextColor(R.id.next_phase_label, "#999999".toColorInt())
            views.setTextColor(R.id.next_phase, "#FF6F00".toColorInt())
        } else {
            // Dark themes use white text
            views.setTextColor(R.id.myanmar_date_compact, "#FFFFFF".toColorInt())
            views.setTextColor(R.id.moon_phase_name, "#FFFFFF".toColorInt())
            views.setTextColor(R.id.fortnight_day, "#FFFFFF".toColorInt())
            views.setTextColor(R.id.next_phase_label, "#999999".toColorInt())
            views.setTextColor(R.id.next_phase, "#FFD700".toColorInt())
        }
    }

    /**
     * Set up click handler to open app
     */
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
                launchIntent.putExtra("widget_type", "moon_phase")
                launchIntent.putExtra("open_page", "astrology") // Open to astrology/moon page

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
}