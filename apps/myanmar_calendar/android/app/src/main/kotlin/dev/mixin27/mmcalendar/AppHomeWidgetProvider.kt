package dev.mixin27.mmcalendar

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.graphics.Color
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import androidx.core.graphics.toColorInt
import java.io.File

class AppHomeWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val TAG = "AppHomeWidgetProvider"
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
                lastUpdated,
                layoutId
            )

            // Update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
            Log.d(TAG, "Widget $appWidgetId updated successfully")

        } catch (e: Exception) {
            Log.e(TAG, "Error updating widget $appWidgetId", e)
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

//            if (imagePath != null && imagePath.isNotEmpty()) {
//                val imageFile = File(imagePath)
//
//                if (imageFile.exists()) {
//                    val bitmap = BitmapFactory.decodeFile(imagePath)
//                    if (bitmap != null) {
//                        views.setImageViewBitmap(R.id.moon_phase_image, bitmap)
//                        views.setViewVisibility(R.id.moon_phase_image, View.VISIBLE)
//                        Log.d(TAG, "✅ Moon phase image loaded from: $imagePath")
//                        return
//                    } else {
//                        Log.w(TAG, "⚠️ Failed to decode bitmap from: $imagePath")
//                    }
//                } else {
//                    Log.w(TAG, "⚠️ Image file doesn't exist: $imagePath")
//                }
//            } else {
//                Log.d(TAG, "ℹ️ No moon phase image path found")
//            }

            // Fallback: Hide image view if no image available
//            views.setViewVisibility(R.id.moon_phase_image, View.GONE)

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
        lastUpdated: String?,
        layoutId: Int
    ) {

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
                val holidayText = if (layoutId == R.layout.widget_layout_large) {
                    "🎉 $holidays"
                } else {
                    "🎉 Holiday"
                }
                views.setTextViewText(R.id.holidays, holidayText)
                views.setViewVisibility(R.id.holidays, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.holidays, View.GONE)
            }
        }

        // Astrology Info (only large layout)
        if (layoutId == R.layout.widget_layout_large) {
            if (config.showAstrology) {
                val astrologyText = buildAstrologyText(sabbathInfo, yatyazaInfo, pyathadaInfo)
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
                        !prefs.getString("pyathada_info", "").isNullOrEmpty()
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

        views.setTextColor(R.id.myanmar_date, textColor)
        views.setTextColor(R.id.moon_day, textColor)

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
        pyathada: String?
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