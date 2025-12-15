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
import java.text.SimpleDateFormat
import java.util.*

/**
 * Monthly Calendar Widget Provider (4x4)
 *
 * Purpose: Mini calendar grid showing the current month
 * Features:
 * - Calendar grid with 7x6 layout
 * - Today highlight
 * - Full moon and new moon indicators
 * - Holiday indicators
 * - Myanmar month name
 * - Current date info at bottom
 */
class MonthlyCalendarWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val TAG = "MonthlyCalendarWidget"

        // Calendar cell IDs (you'll need to add these to your layout)
        private val CELL_IDS = arrayOf(
            // Week 1
            R.id.day_1, R.id.day_2, R.id.day_3, R.id.day_4, R.id.day_5, R.id.day_6, R.id.day_7,
            // Week 2
            R.id.day_8, R.id.day_9, R.id.day_10, R.id.day_11, R.id.day_12, R.id.day_13, R.id.day_14,
            // Week 3
            R.id.day_15, R.id.day_16, R.id.day_17, R.id.day_18, R.id.day_19, R.id.day_20, R.id.day_21,
            // Week 4
            R.id.day_22, R.id.day_23, R.id.day_24, R.id.day_25, R.id.day_26, R.id.day_27, R.id.day_28,
            // Week 5
            R.id.day_29, R.id.day_30, R.id.day_31, R.id.day_32, R.id.day_33, R.id.day_34, R.id.day_35,
            // Week 6
            R.id.day_36, R.id.day_37, R.id.day_38, R.id.day_39, R.id.day_40, R.id.day_41, R.id.day_42
        )
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        Log.d(TAG, "onUpdate called for ${appWidgetIds.size} monthly calendar widgets")
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
            Log.d(TAG, "Updating monthly calendar widget $widgetId")

            val views = RemoteViews(context.packageName, R.layout.widget_layout_monthly_calendar)

            // Get current date
            val calendar = Calendar.getInstance()
            val today = calendar.get(Calendar.DAY_OF_MONTH)
            val currentMonth = calendar.get(Calendar.MONTH)
            val currentYear = calendar.get(Calendar.YEAR)

            // Read data
            val myanmarDate = widgetData.getString("myanmar_date", "") ?: ""
            val myanmarMonth = extractMyanmarMonth(myanmarDate)
            val theme = widgetData.getString("widget_theme", "dark") ?: "dark"

            // Update header
            val monthYearText = SimpleDateFormat("MMMM yyyy", Locale.ENGLISH).format(calendar.time)
            views.setTextViewText(R.id.month_year, monthYearText)
            views.setTextViewText(R.id.myanmar_month, myanmarMonth)

            // Update today info at bottom
            views.setTextViewText(R.id.today_myanmar, myanmarDate)

            // Build calendar grid
            buildCalendarGrid(views, calendar, today, widgetData)

            // Apply theme
            applyTheme(views, theme)

            // Set up click handler
            setupClickHandler(context, views, widgetId)

            // Update widget
            appWidgetManager.updateAppWidget(widgetId, views)
            Log.d(TAG, "Monthly calendar widget $widgetId updated successfully")

        } catch (e: Exception) {
            Log.e(TAG, "Error updating monthly calendar widget $widgetId", e)
        }
    }

    /**
     * Build calendar grid for current month
     */
    private fun buildCalendarGrid(
        views: RemoteViews,
        calendar: Calendar,
        today: Int,
        widgetData: SharedPreferences
    ) {
        // Get first day of month
        val firstDayCalendar = calendar.clone() as Calendar
        firstDayCalendar.set(Calendar.DAY_OF_MONTH, 1)
        val firstDayOfWeek = firstDayCalendar.get(Calendar.DAY_OF_WEEK) - 1 // 0 = Sunday

        // Get number of days in month
        val daysInMonth = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)

        // Get previous month's last days
        val prevMonthCalendar = calendar.clone() as Calendar
        prevMonthCalendar.add(Calendar.MONTH, -1)
        val daysInPrevMonth = prevMonthCalendar.getActualMaximum(Calendar.DAY_OF_MONTH)

        var cellIndex = 0
        var currentDay = 1

        // Fill calendar cells
        for (i in 0 until 42) { // 6 weeks * 7 days
            if (i >= CELL_IDS.size) break

            val cellId = CELL_IDS[i]

            when {
                // Previous month days
                i < firstDayOfWeek -> {
                    val day = daysInPrevMonth - firstDayOfWeek + i + 1
                    views.setTextViewText(cellId, day.toString())
                    views.setTextColor(cellId, "#666666".toColorInt())
                    views.setInt(cellId, "setBackgroundResource", 0) // No background
                    views.setViewVisibility(cellId, View.VISIBLE)
                }
                // Current month days
                currentDay <= daysInMonth -> {
                    views.setTextViewText(cellId, currentDay.toString())

                    // Highlight today
                    if (currentDay == today) {
                        views.setTextColor(cellId, "#000000".toColorInt())
                        views.setInt(cellId, "setBackgroundResource", R.drawable.today_cell_bg)
                    } else {
                        views.setTextColor(cellId, "#FFFFFF".toColorInt())
                        views.setInt(cellId, "setBackgroundResource", 0)
                    }

                    views.setViewVisibility(cellId, View.VISIBLE)
                    currentDay++
                }
                // Next month days
                else -> {
                    val day = currentDay - daysInMonth
                    views.setTextViewText(cellId, day.toString())
                    views.setTextColor(cellId, "#666666".toColorInt())
                    views.setInt(cellId, "setBackgroundResource", 0)
                    views.setViewVisibility(cellId, View.VISIBLE)
                    currentDay++
                }
            }
        }
    }

    /**
     * Extract Myanmar month name from full date
     * Example: "၁၃၈၆ နတ်တော် လဆုတ် ၈ ရက်" -> "နတ်တော်"
     */
    private fun extractMyanmarMonth(fullDate: String): String {
        return try {
            val parts = fullDate.split(" ")
            if (parts.size >= 2) {
                parts[1] // Second part is month name
            } else {
                ""
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting Myanmar month", e)
            ""
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
            else -> R.drawable.widget_bg_calendar // default dark
        }

        views.setInt(R.id.widget_root, "setBackgroundResource", bgDrawable)

        // Adjust header text colors for light theme
        if (theme == "light") {
            views.setTextColor(R.id.month_year, "#1A1A1A".toColorInt())
            views.setTextColor(R.id.myanmar_month, "#666666".toColorInt())
            views.setTextColor(R.id.today_myanmar, "#1A1A1A".toColorInt())
        } else {
            views.setTextColor(R.id.month_year, "#FFFFFF".toColorInt())
            views.setTextColor(R.id.myanmar_month, "#E0E0E0".toColorInt())
            views.setTextColor(R.id.today_myanmar, "#FFFFFF".toColorInt())
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
                launchIntent.putExtra("widget_type", "monthly_calendar")
                launchIntent.putExtra("open_page", "calendar") // Open to calendar view

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