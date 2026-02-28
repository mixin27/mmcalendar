package dev.mixin27.mmcalendar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import androidx.core.graphics.toColorInt
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

/**
 * Myanmar Month Calendar Widget Provider (4x4)
 *
 * Displays Myanmar calendar month grid with:
 * - Myanmar dates (waxing/waning + fortnight day)
 * - Moon phase indicators (full moon, new moon)
 * - Holiday markers
 * - Today highlight
 * - Western date correspondence
 */
class MyanmarMonthWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val TAG = "MyanmarMonthWidget"

        // Calendar cell IDs (42 cells = 7 days × 6 rows)
        private val CELL_IDS = intArrayOf(
            // Row 1
            R.id.mm_day_1, R.id.mm_day_2, R.id.mm_day_3, R.id.mm_day_4,
            R.id.mm_day_5, R.id.mm_day_6, R.id.mm_day_7,
            // Row 2
            R.id.mm_day_8, R.id.mm_day_9, R.id.mm_day_10, R.id.mm_day_11,
            R.id.mm_day_12, R.id.mm_day_13, R.id.mm_day_14,
            // Row 3
            R.id.mm_day_15, R.id.mm_day_16, R.id.mm_day_17, R.id.mm_day_18,
            R.id.mm_day_19, R.id.mm_day_20, R.id.mm_day_21,
            // Row 4
            R.id.mm_day_22, R.id.mm_day_23, R.id.mm_day_24, R.id.mm_day_25,
            R.id.mm_day_26, R.id.mm_day_27, R.id.mm_day_28,
            // Row 5
            R.id.mm_day_29, R.id.mm_day_30, R.id.mm_day_31, R.id.mm_day_32,
            R.id.mm_day_33, R.id.mm_day_34, R.id.mm_day_35,
            // Row 6
            R.id.mm_day_36, R.id.mm_day_37, R.id.mm_day_38, R.id.mm_day_39,
            R.id.mm_day_40, R.id.mm_day_41, R.id.mm_day_42
        )

        // Moon phase indicator IDs
        private val MOON_INDICATOR_IDS = intArrayOf(
            R.id.moon_1, R.id.moon_2, R.id.moon_3, R.id.moon_4,
            R.id.moon_5, R.id.moon_6, R.id.moon_7,
            R.id.moon_8, R.id.moon_9, R.id.moon_10, R.id.moon_11,
            R.id.moon_12, R.id.moon_13, R.id.moon_14,
            R.id.moon_15, R.id.moon_16, R.id.moon_17, R.id.moon_18,
            R.id.moon_19, R.id.moon_20, R.id.moon_21,
            R.id.moon_22, R.id.moon_23, R.id.moon_24, R.id.moon_25,
            R.id.moon_26, R.id.moon_27, R.id.moon_28,
            R.id.moon_29, R.id.moon_30, R.id.moon_31, R.id.moon_32,
            R.id.moon_33, R.id.moon_34, R.id.moon_35,
            R.id.moon_36, R.id.moon_37, R.id.moon_38, R.id.moon_39,
            R.id.moon_40, R.id.moon_41, R.id.moon_42
        )

        // Holiday indicator IDs
        private val HOLIDAY_INDICATOR_IDS = intArrayOf(
            R.id.holiday_1, R.id.holiday_2, R.id.holiday_3, R.id.holiday_4,
            R.id.holiday_5, R.id.holiday_6, R.id.holiday_7,
            R.id.holiday_8, R.id.holiday_9, R.id.holiday_10, R.id.holiday_11,
            R.id.holiday_12, R.id.holiday_13, R.id.holiday_14,
            R.id.holiday_15, R.id.holiday_16, R.id.holiday_17, R.id.holiday_18,
            R.id.holiday_19, R.id.holiday_20, R.id.holiday_21,
            R.id.holiday_22, R.id.holiday_23, R.id.holiday_24, R.id.holiday_25,
            R.id.holiday_26, R.id.holiday_27, R.id.holiday_28,
            R.id.holiday_29, R.id.holiday_30, R.id.holiday_31, R.id.holiday_32,
            R.id.holiday_33, R.id.holiday_34, R.id.holiday_35,
            R.id.holiday_36, R.id.holiday_37, R.id.holiday_38, R.id.holiday_39,
            R.id.holiday_40, R.id.holiday_41, R.id.holiday_42
        )
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        Log.d(TAG, "onUpdate called for ${appWidgetIds.size} Myanmar month widgets")
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
            Log.d(TAG, "Updating Myanmar month widget $widgetId")

            val views = RemoteViews(context.packageName, R.layout.widget_layout_myanmar_month)
            val timelineMonthJson = WidgetTimelineResolver
                .resolveCurrentMonthEntry(widgetData)
                ?.toString()

            // Read Myanmar month data (timeline-first, then legacy fallback)
            val myanmarMonthJson = timelineMonthJson
                ?: widgetData.getString("myanmar_month_data", null)

            if (myanmarMonthJson.isNullOrEmpty()) {
                Log.w(TAG, "No Myanmar month data found")
                showEmptyState(views)
            } else {
                // Parse and display Myanmar month data
                val monthData = parseMonthData(myanmarMonthJson)
                displayMyanmarMonth(views, monthData, widgetData)
            }

            // Apply theme
            val theme = widgetData.getString("widget_theme", "gradientBlue") ?: "gradientBlue"
            applyTheme(views, theme)

            // Set up click handler
            setupClickHandler(context, views, widgetId)

            // Update widget
            appWidgetManager.updateAppWidget(widgetId, views)
            Log.d(TAG, "Myanmar month widget $widgetId updated successfully")

        } catch (e: Exception) {
            Log.e(TAG, "Error updating Myanmar month widget $widgetId", e)
        }
    }

    /**
     * Parse Myanmar month data from JSON
     */
    private fun parseMonthData(json: String): MyanmarMonthData {
        try {
            val jsonObject = JSONObject(json)
            val daysArray = jsonObject.getJSONArray("days")

            val days = mutableListOf<MyanmarDayData>()
            for (i in 0 until daysArray.length()) {
                val dayObj = daysArray.getJSONObject(i)
                days.add(MyanmarDayData(
                    westernYear = dayObj.getInt("western_year"),
                    westernMonth = dayObj.getInt("western_month"),
                    westernDay = dayObj.getInt("western_day"),
                    myanmarYear = dayObj.getInt("myanmar_year"),
                    myanmarMonth = dayObj.getInt("myanmar_month"),
                    myanmarMonthName = dayObj.getString("myanmar_month_name"),
                    moonPhase = dayObj.getInt("moon_phase"),
                    fortnightDay = dayObj.getInt("fortnight_day"),
                    hasHoliday = dayObj.getBoolean("has_holiday"),
                    isToday = dayObj.getBoolean("is_today"),
                    isCurrentMonth = dayObj.getBoolean("is_current_month")
                ))
            }

            return MyanmarMonthData(
                myanmarYear = jsonObject.getInt("myanmar_year"),
                myanmarMonth = jsonObject.getInt("myanmar_month"),
                myanmarMonthName = jsonObject.getString("myanmar_month_name"),
                westernYear = jsonObject.getInt("western_year"),
                westernMonth = jsonObject.getInt("western_month"),
                westernMonthName = jsonObject.getString("western_month_name"),
                days = days
            )
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing month data", e)
            throw e
        }
    }

    /**
     * Display Myanmar month calendar
     */
    private fun displayMyanmarMonth(
        views: RemoteViews,
        monthData: MyanmarMonthData,
        widgetData: SharedPreferences
    ) {
        // Determine if light theme
        val theme = widgetData.getString("widget_theme", "gradientBlue") ?: "gradientBlue"

        // Update header
        views.setTextViewText(R.id.myanmar_month_year, monthData.myanmarMonthName)
        views.setTextViewText(R.id.western_month_year, "${monthData.westernMonthName} ${monthData.westernYear}")

        // Display Myanmar weekday headers
        displayWeekdayHeaders(views, widgetData)

        // Display each day in the grid
        for (i in monthData.days.indices) {
            if (i >= CELL_IDS.size) break

            val dayData = monthData.days[i]
            val cellId = CELL_IDS[i]
            val moonId = MOON_INDICATOR_IDS[i]
            val holidayId = HOLIDAY_INDICATOR_IDS[i]

            // Show cell
            views.setViewVisibility(cellId, View.VISIBLE)

            // Format Myanmar date text
            val dayText = formatMyanmarDay(dayData, widgetData)
            views.setTextViewText(cellId, dayText)

            // Style based on state
            if (dayData.isToday) {
                // Today - highlight with yellow circle
                views.setInt(cellId, "setBackgroundResource", R.drawable.today_cell_bg)
                views.setTextColor(cellId, "#000000".toColorInt())
            } else if (!dayData.isCurrentMonth) {
                // Previous/Next month - dimmed
                views.setInt(cellId, "setBackgroundResource", 0)
                if (theme == "light") {
                    views.setTextColor(cellId, "#BDBDBD".toColorInt()) // Light grey for light theme
                } else {
                    views.setTextColor(cellId, "#666666".toColorInt()) // Dark grey for dark theme
                }
            } else {
                // Current month - normal
                views.setInt(cellId, "setBackgroundResource", 0)
                if (theme == "light") {
                    views.setTextColor(cellId, "#1A1A1A".toColorInt()) // Dark text for light theme
                } else {
                    views.setTextColor(cellId, "#FFFFFF".toColorInt()) // Light text for dark theme
                }
            }

            // Moon phase indicator (full moon or new moon)
            if (dayData.moonPhase == 1 || dayData.moonPhase == 3) {
                views.setViewVisibility(moonId, View.VISIBLE)
                val moonColor = if (dayData.moonPhase == 1) "#FFD700" else {
                    if (theme == "light") "#757575" else "#E0E0E0"
                }
                views.setInt(moonId, "setColorFilter", moonColor.toColorInt())
            } else {
                views.setViewVisibility(moonId, View.GONE)
            }

            // Holiday indicator
            if (dayData.hasHoliday) {
                views.setViewVisibility(holidayId, View.VISIBLE)
            } else {
                views.setViewVisibility(holidayId, View.GONE)
            }
        }

        // Update today info at bottom
        val todayData = monthData.days.find { it.isToday }
        if (todayData != null) {
            val todayText = "${convertToMyanmarNumber(todayData.myanmarYear, widgetData)} ${todayData.myanmarMonthName} ${formatMoonPhase(todayData.moonPhase, widgetData)} ${convertToMyanmarNumber(todayData.fortnightDay, widgetData)} ရက်"
            views.setTextViewText(R.id.today_myanmar, todayText)
            views.setViewVisibility(R.id.today_myanmar, View.VISIBLE)
        }
    }

    /**
     * Display Myanmar weekday headers
     */
    private fun displayWeekdayHeaders(views: RemoteViews, widgetData: SharedPreferences) {
        val language = resolveLanguage(widgetData)

        var weekdays = arrayOf("နွေ", "လာ", "ဂါ", "ဟူး", "ကြာ", "သော", "နေ")
        if (language == "en") {
            weekdays = arrayOf("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat")
        }

        val headerIds = intArrayOf(
            R.id.weekday_1, R.id.weekday_2, R.id.weekday_3, R.id.weekday_4,
            R.id.weekday_5, R.id.weekday_6, R.id.weekday_7
        )

        for (i in weekdays.indices) {
            views.setTextViewText(headerIds[i], weekdays[i])
        }
    }

    /**
     * Format Myanmar day for display
     * Shows: moon phase + fortnight day
     * Example: "လဆန်း ၅" or "လဆုတ် ၁၅"
     */
    private fun formatMyanmarDay(dayData: MyanmarDayData, widgetData: SharedPreferences): String {
        val moonPhase = formatMoonPhase(dayData.moonPhase, widgetData)
        val day = convertToMyanmarNumber(dayData.fortnightDay, widgetData)
        return "$moonPhase\n$day"
    }

    /**
     * Format moon phase name in Myanmar
     */
    private fun formatMoonPhase(moonPhase: Int, widgetData: SharedPreferences): String {
        val items = mutableListOf<String>()
        val moonPhaseNames = widgetData.getString("moon_phase_names", "")
        if (!moonPhaseNames.isNullOrEmpty() && moonPhaseNames != "null") {
            items.addAll(moonPhaseNames.split(",").map { it.trim() })
        }

        if (items.isEmpty()) {
            return when (moonPhase) {
                0 -> "လဆန်း" // Waxing
                1 -> "လပြည့်" // Full Moon
                2 -> "လဆုတ်" // Waning
                3 -> "လကွယ်" // New Moon
                else -> ""
            }
        }

        return items[moonPhase]
    }

    /**
     * Convert number to Myanmar numerals
     */
    private fun convertToMyanmarNumber(number: Int, widgetData: SharedPreferences): String {
        val language = resolveLanguage(widgetData)
        if (language == "en") {
            return number.toString()
        }

        val myanmarDigits = arrayOf("၀", "၁", "၂", "၃", "၄", "၅", "၆", "၇", "၈", "၉")
        return number.toString().map {
            myanmarDigits[it.toString().toInt()]
        }.joinToString("")
    }

    /**
     * Show empty state when no data available
     */
    private fun showEmptyState(views: RemoteViews) {
        views.setTextViewText(R.id.myanmar_month_year, "Myanmar Calendar")
        views.setTextViewText(R.id.western_month_year, "Loading...")

        // Hide all cells
        for (cellId in CELL_IDS) {
            views.setViewVisibility(cellId, View.GONE)
        }
    }

    /**
     * Apply theme to widget
     */
    private fun applyTheme(views: RemoteViews, theme: String) {
        val bgDrawable = when (theme) {
            "light" -> R.drawable.widget_background_light
            "dark" -> R.drawable.widget_background_dark
            "traditional" -> R.drawable.widget_background_traditional
            "gradientBlue" -> R.drawable.widget_background_gradient_blue
            "gradientPurple" -> R.drawable.widget_background_gradient_purple
            "gradientTeal" -> R.drawable.widget_background_gradient_teal
            else -> R.drawable.widget_bg_calendar
        }

        views.setInt(R.id.widget_root, "setBackgroundResource", bgDrawable)

        // Adjust text colors for light theme
        if (theme == "light") {
            views.setTextColor(R.id.myanmar_month_year, "#1A1A1A".toColorInt())
            views.setTextColor(R.id.western_month_year, "#666666".toColorInt())
            views.setTextColor(R.id.today_myanmar, "#1A1A1A".toColorInt())
        } else {
            views.setTextColor(R.id.myanmar_month_year, "#FFFFFF".toColorInt())
            views.setTextColor(R.id.western_month_year, "#FFFFFF".toColorInt())
            views.setTextColor(R.id.today_myanmar, "#FFFFFF".toColorInt())
        }
    }

    private fun resolveLanguage(widgetData: SharedPreferences): String {
        val calendarLanguage = widgetData.getString("calendar_language", null)
        if (!calendarLanguage.isNullOrEmpty()) {
            return calendarLanguage
        }
        return widgetData.getString("widget_language", "en") ?: "en"
    }

    /**
     * Set up click handler
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
                launchIntent.putExtra("widget_type", "myanmar_month")
                launchIntent.putExtra("open_page", "calendar")

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

    /**
     * Data class for Myanmar month
     */
    private data class MyanmarMonthData(
        val myanmarYear: Int,
        val myanmarMonth: Int,
        val myanmarMonthName: String,
        val westernYear: Int,
        val westernMonth: Int,
        val westernMonthName: String,
        val days: List<MyanmarDayData>
    )

    /**
     * Data class for Myanmar day
     */
    private data class MyanmarDayData(
        val westernYear: Int,
        val westernMonth: Int,
        val westernDay: Int,
        val myanmarYear: Int,
        val myanmarMonth: Int,
        val myanmarMonthName: String,
        val moonPhase: Int,
        val fortnightDay: Int,
        val hasHoliday: Boolean,
        val isToday: Boolean,
        val isCurrentMonth: Boolean
    )
}
