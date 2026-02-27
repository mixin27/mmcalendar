package dev.mixin27.mmcalendar

import android.content.SharedPreferences
import android.util.Log
import org.json.JSONObject
import java.util.Calendar
import java.util.Locale

internal object WidgetTimelineResolver {
    private const val TAG = "WidgetTimelineResolver"
    private const val TIMELINE_KEY = "widget_timeline_v1"

    fun resolveTodayEntry(widgetData: SharedPreferences): JSONObject? {
        val timelineJson = widgetData.getString(TIMELINE_KEY, null) ?: return null

        return try {
            val root = JSONObject(timelineJson)
            val entries = root.optJSONObject("entries") ?: return null
            entries.optJSONObject(todayKey())
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse widget timeline payload", e)
            null
        }
    }

    private fun todayKey(): String {
        val now = Calendar.getInstance()
        val year = now.get(Calendar.YEAR)
        val month = now.get(Calendar.MONTH) + 1
        val day = now.get(Calendar.DAY_OF_MONTH)
        return String.format(Locale.US, "%04d-%02d-%02d", year, month, day)
    }
}

internal class WidgetDataReader(
    private val widgetData: SharedPreferences,
) {
    private val timelineEntry: JSONObject? by lazy {
        WidgetTimelineResolver.resolveTodayEntry(widgetData)
    }

    fun getString(key: String, default: String = ""): String {
        if (timelineEntry?.has(key) == true) {
            val timelineValue = timelineEntry?.optString(key, default) ?: default
            return if (timelineValue == "null") default else timelineValue
        }
        return widgetData.getString(key, default) ?: default
    }

    fun hasTimelineData(): Boolean = timelineEntry != null
}
