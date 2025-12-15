package dev.mixin27.mmcalendar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.graphics.Color
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import androidx.core.graphics.toColorInt

class AppHomeWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val TAG = "AppHomeWidgetProvider"

        // Action for widget clicks
        private const val ACTION_WIDGET_CLICK = "dev.mixin27.mmcalendar.WIDGET_CLICK"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        Log.d(TAG, "onUpdate called for ${appWidgetIds.size} widgets")
        appWidgetIds.forEach { widgetId ->
            updateAppWidget(context, appWidgetManager, widgetId, widgetData)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        widgetData: SharedPreferences
    ) {
        Log.d(TAG, "Updating widget $appWidgetId")

        try {
            // Read configuration
            val config = readWidgetConfig(widgetData)
            Log.d(TAG, "Widget config: $config")

            // Determine widget size and layout
            val layoutId = getLayoutForSize(appWidgetManager, appWidgetId, config.size)
            Log.d(TAG, "Using layout: $layoutId for size: ${config.size}")

            val views = RemoteViews(context.packageName, layoutId)

            // Read data from SharedPreferences
            val myanmarDate = widgetData.getString("myanmar_date", null)
            val westernDate = widgetData.getString("western_date", null)
            val moonPhase = widgetData.getString("moon_phase", null)
            val moonPhaseEmoji = widgetData.getString("moon_phase_emoji", null)
            val holidays = widgetData.getString("holidays", null)
            val sabbathInfo = widgetData.getString("sabbath_info", null)
            val yatyazaInfo = widgetData.getString("yatyaza_info", null)
            val pyathadaInfo = widgetData.getString("pyathada_info", null)
            val astrologicalDays = widgetData.getString("astrological_days", null)
            val lastUpdated = widgetData.getString("last_updated", null)

            Log.d(TAG, "Data - Myanmar: $myanmarDate, Western: $westernDate")

            // Apply theme colors
            applyTheme(views, config.theme, context, layoutId)

            // Load and display moon phase image
            loadMoonPhaseImage(context, views, widgetData)

            // Update content based on layout
            updateWidgetContent(
                views,
                config,
                myanmarDate,
                westernDate,
                moonPhase,
                moonPhaseEmoji,
                holidays,
                sabbathInfo,
                yatyazaInfo,
                pyathadaInfo,
                astrologicalDays,
                lastUpdated,
                layoutId
            )

            // Set up click handling to open app
            setupClickHandlers(context, views, appWidgetId)

            // Update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d(TAG, "Widget $appWidgetId updated successfully")

        } catch (e: Exception) {
            Log.e(TAG, "Error updating widget $appWidgetId", e)
        }
    }

    /**
     * Set up click handlers for the widget
     * Clicking anywhere on the widget will open the app
     */
    private fun setupClickHandlers(
        context: Context,
        views: RemoteViews,
        appWidgetId: Int
    ) {
        try {
            // Create intent to launch the main activity
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)

            if (launchIntent != null) {
                // Add flags to ensure proper app launch behavior
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)

                // Add extra data to track that app was opened from widget
                launchIntent.putExtra("opened_from_widget", true)
                launchIntent.putExtra("widget_id", appWidgetId)
                launchIntent.putExtra("timestamp", System.currentTimeMillis())

                // Create pending intent with proper flags for Android 12+
                val flags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }

                val pendingIntent = PendingIntent.getActivity(
                    context,
                    appWidgetId, // Use widget ID as request code to make it unique
                    launchIntent,
                    flags
                )

                // Set click listener on the entire widget root
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                Log.d(TAG, "Click handler set up for widget $appWidgetId")
            } else {
                Log.e(TAG, "Could not get launch intent for package: ${context.packageName}")
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error setting up click handlers", e)
        }
    }

    /**
     * Alternative method: Set up specific click handlers for different widget elements
     * Use this if you want different actions for different parts of the widget
     */
    private fun setupDetailedClickHandlers(
        context: Context,
        views: RemoteViews,
        appWidgetId: Int,
        layoutId: Int
    ) {
        try {
            // Main click - opens app to today's date
            val mainIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (mainIntent != null) {
                mainIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                mainIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                mainIntent.putExtra("opened_from_widget", true)
                mainIntent.putExtra("action", "view_today")

                val flags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }

                val mainPendingIntent = PendingIntent.getActivity(
                    context,
                    appWidgetId,
                    mainIntent,
                    flags
                )

                // Set on root
                views.setOnClickPendingIntent(R.id.widget_root, mainPendingIntent)

                // Set on Myanmar date if you want it to be clickable specifically
                views.setOnClickPendingIntent(R.id.myanmar_date, mainPendingIntent)
            }

            // You can add more specific click handlers here
            // For example, clicking moon phase could open to astrology page
            // if (layoutId != R.layout.widget_layout_small) {
            //     val astrologyIntent = Intent(context, MainActivity::class.java)
            //     astrologyIntent.putExtra("open_page", "astrology")
            //     // ... setup pending intent and attach to moon_phase_image
            // }

        } catch (e: Exception) {
            Log.e(TAG, "Error setting up detailed click handlers", e)
        }
    }

    private fun loadMoonPhaseImage(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences
    ) {
        try {
            // Get the path to the rendered Flutter widget image
            val imagePath = widgetData.getString("moon_phase_image", null)
            Log.d(TAG, "imagePath: $imagePath")

            imagePath?.let {
                val bitmap = BitmapFactory.decodeFile(it)
                views.setImageViewBitmap(R.id.moon_phase_image, bitmap)
                views.setViewVisibility(R.id.moon_phase_image, View.VISIBLE)
                Log.d(TAG, "✅ Moon phase image loaded from: $imagePath")
            }

        } catch (e: Exception) {
            Log.e(TAG, "❌ Error loading moon phase image", e)
            views.setViewVisibility(R.id.moon_phase_image, View.GONE)
        }
    }

    private fun getLayoutForSize(
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        configSize: String
    ): Int {
        // Try to get widget size from AppWidgetManager (Android 12+)
        val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 0)

        return when {
            // User's Flutter config takes priority
            configSize == "small" -> R.layout.widget_layout_small
            configSize == "large" -> R.layout.widget_layout_large
            configSize == "medium" -> R.layout.widget_layout_medium

            // Auto-detect based on actual widget size on home screen
            minWidth < 180 || minHeight < 110 -> R.layout.widget_layout_small
            minWidth >= 250 && minHeight >= 250 -> R.layout.widget_layout_large
            else -> R.layout.widget_layout_medium
        }
    }

    private fun updateWidgetContent(
        views: RemoteViews,
        config: WidgetConfig,
        myanmarDate: String?,
        westernDate: String?,
        moonPhase: String?,
        moonPhaseEmoji: String?,
        holidays: String?,
        sabbathInfo: String?,
        yatyazaInfo: String?,
        pyathadaInfo: String?,
        astrologicalDays: String?,
        lastUpdated: String?,
        layoutId: Int
    ) {
//        if (!lastUpdated.isNullOrEmpty()) {
//            views.setTextViewText(R.id.last_updated, lastUpdated)
//            views.setViewVisibility(R.id.last_updated_label, View.VISIBLE)
//            views.setViewVisibility(R.id.last_updated, View.VISIBLE)
//        } else {
//            views.setViewVisibility(R.id.last_updated_label, View.GONE)
//            views.setViewVisibility(R.id.last_updated, View.GONE)
//        }
        views.setViewVisibility(R.id.last_updated_label, View.GONE)
        views.setViewVisibility(R.id.last_updated, View.GONE)

        // Update Myanmar Date (respect config)
        if (config.showMyanmarDate && !myanmarDate.isNullOrEmpty()) {
            views.setTextViewText(R.id.myanmar_date, myanmarDate)
            views.setViewVisibility(R.id.myanmar_date, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.myanmar_date, View.GONE)
        }

        // Update Western Date (respect config) - only if view exists in layout
        if (layoutId != R.layout.widget_layout_small) {
            Log.d(TAG, "westernDate: ${config.showWesternDate}")
            if (config.showWesternDate && !westernDate.isNullOrEmpty()) {
                views.setTextViewText(R.id.western_date, westernDate)
                views.setViewVisibility(R.id.western_date, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.western_date, View.GONE)
            }
        }

        // Moon Phase Name
        if (!moonPhase.isNullOrEmpty()) {
            views.setTextViewText(R.id.moon_day, moonPhase)
            views.setViewVisibility(R.id.moon_day, View.VISIBLE)
        }

        // Holidays (not in small layout)
        if (layoutId != R.layout.widget_layout_small) {
            if (config.showHolidays && !holidays.isNullOrEmpty() && holidays != "null") {
                val holidayText = "🎉 $holidays"
                views.setTextViewText(R.id.holidays, holidayText)
                views.setViewVisibility(R.id.holidays, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.holidays, View.GONE)
            }
        }

        // Astrology Info (only large layout)
        if (layoutId == R.layout.widget_layout_large) {
            if (config.showAstrology) {
                val astrologyText = buildAstrologyText(sabbathInfo, yatyazaInfo, pyathadaInfo, astrologicalDays)
                if (astrologyText.isNotEmpty()) {
                    views.setTextViewText(R.id.astrology_info, astrologyText)
                    views.setViewVisibility(R.id.astrology_info, View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.astrology_info, View.GONE)
                }
            } else {
                views.setViewVisibility(R.id.astrology_info, View.GONE)
            }
        }
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

    private fun applyTheme(
        views: RemoteViews,
        theme: String,
        context: Context,
        layoutId: Int
    ) {
        // Set background drawable based on theme
        val backgroundDrawable = when (theme) {
            "light" -> R.drawable.widget_background_light
            "dark" -> R.drawable.widget_background_dark
            "traditional" -> R.drawable.widget_background_traditional
            "gradientBlue" -> R.drawable.widget_background_gradient_blue
            "gradientPurple" -> R.drawable.widget_background_gradient_purple
            "gradientTeal" -> R.drawable.widget_background_gradient_teal
            "auto" -> {
                val isDarkMode = context.resources.configuration.uiMode and
                        android.content.res.Configuration.UI_MODE_NIGHT_MASK ==
                        android.content.res.Configuration.UI_MODE_NIGHT_YES
                if (isDarkMode) R.drawable.widget_background_dark else R.drawable.widget_background_light
            }
            else -> R.drawable.widget_background
        }

        views.setInt(R.id.widget_root, "setBackgroundResource", backgroundDrawable)

        // Set text colors based on theme
        val textColor = when (theme) {
            "light" -> "#212121".toColorInt()
            "dark" -> Color.WHITE
            "traditional" -> Color.WHITE
            "gradientBlue" -> Color.WHITE
            "gradientPurple" -> Color.WHITE
            "gradientTeal" -> Color.WHITE
            "auto" -> {
                val isDarkMode = context.resources.configuration.uiMode and
                        android.content.res.Configuration.UI_MODE_NIGHT_MASK ==
                        android.content.res.Configuration.UI_MODE_NIGHT_YES
                if (isDarkMode) Color.WHITE else "#212121".toColorInt()
            }
            else -> Color.WHITE
        }

        val secondaryTextColor = when (theme) {
            "light" -> "#757575".toColorInt()
            "dark" -> "#E0E0E0".toColorInt()
            "traditional" -> "#FFF9C4".toColorInt()
            "gradientBlue" -> "#FFF9C4".toColorInt()
            "gradientPurple" -> "#FFF9C4".toColorInt()
            "gradientTeal" -> "#FFF9C4".toColorInt()
            "auto" -> {
                val isDarkMode = context.resources.configuration.uiMode and
                        android.content.res.Configuration.UI_MODE_NIGHT_MASK ==
                        android.content.res.Configuration.UI_MODE_NIGHT_YES
                if (isDarkMode) "#E0E0E0".toColorInt() else "#757575".toColorInt()
            }
            else -> "#E0E0E0".toColorInt()
        }

        views.setTextColor(R.id.last_updated_label, textColor)
        views.setTextColor(R.id.last_updated, textColor)
        views.setTextColor(R.id.myanmar_date, textColor)
        views.setTextColor(R.id.moon_day, secondaryTextColor)

        if (layoutId != R.layout.widget_layout_small) {
            views.setTextColor(R.id.western_date, secondaryTextColor)
            views.setTextColor(R.id.widget_title, secondaryTextColor)
        }

        if (layoutId == R.layout.widget_layout_large) {
            views.setTextColor(R.id.astrology_info, secondaryTextColor)
        }
    }

    private fun buildAstrologyText(
        sabbath: String?,
        yatyaza: String?,
        pyathada: String?,
        astrologicalDays: String?
    ): String {
        val items = mutableListOf<String>()

        if (!sabbath.isNullOrEmpty() && sabbath != "null" && sabbath != "") {
            items.add(sabbath)
        }
        if (!yatyaza.isNullOrEmpty() && yatyaza != "null" && yatyaza != "") {
            items.add(yatyaza)
        }
        if (!pyathada.isNullOrEmpty() && pyathada != "null" && pyathada != "") {
            items.add(pyathada)
        }

        if (!astrologicalDays.isNullOrEmpty() && astrologicalDays != "null" && astrologicalDays != "") {
            val astroDays = astrologicalDays.split(',')
            items.addAll(astroDays)
        }

        return items.joinToString(" • ")
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