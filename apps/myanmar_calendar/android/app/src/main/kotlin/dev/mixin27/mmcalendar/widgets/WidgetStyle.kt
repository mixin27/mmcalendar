package dev.mixin27.mmcalendar.widgets

import android.content.SharedPreferences
import androidx.compose.ui.graphics.Color
import androidx.glance.text.FontFamily
import androidx.glance.unit.ColorProvider
import androidx.glance.color.ColorProvider as DayNightColor

/** The styles a widget can wear; `standard` uses the app's default. */
enum class WidgetStyleId(val key: String) {
    App("app"), Plain("plain"), Pagoda("pagoda"), Jade("jade"), DeepField("deepField");

    companion object {
        fun of(key: String) = entries.firstOrNull { it.key == key } ?: App
    }
}

/** A style's colours, each switching with the system's dark theme. */
class Palette(private val light: Map<String, Int>, private val dark: Map<String, Int>) {
    private fun c(key: String, fallback: Long): ColorProvider = DayNightColor(
        day = Color(light[key] ?: fallback.toInt()),
        night = Color(dark[key] ?: light[key] ?: fallback.toInt()),
    )

    val bg = c("bg", 0xFFFFFFFF)
    val ink = c("ink", 0xFF111216)
    val muted = c("muted", 0xFF6B6B73)
    val accent = c("accent", 0xFF2F5BEA)
    val onAccent = c("onAccent", 0xFFFFFFFF)
    val holiday = c("holiday", 0xFFE5383B)
    val moon = c("moon", 0xFFF2A900)
    val sabbath = c("sabbath", 0xFFB7700B)
    val soft = c("soft", 0x1F2F5BEA)
    val holidaySoft = c("holidaySoft", 0x17E5383B)
    val line = c("line", 0x243C3C43)
    val shade = c("shade", 0x33767680)

    /** For the motif, whose bitmap carries its own faintness. */
    val motif: ColorProvider get() = accent

    companion object {
        val fallback = Palette(emptyMap(), emptyMap())
    }
}

/** What a widget needs to draw: its style, palette and number font. */
class WidgetLook(val style: WidgetStyleId, val palette: Palette) {
    /** Numbers: serif for the heritage styles. */
    val numberFont: FontFamily? = when (style) {
        WidgetStyleId.Pagoda, WidgetStyleId.Jade -> FontFamily.Serif
        else -> null
    }

    companion object {
        fun resolve(payload: WidgetPayload?, styleKey: String): WidgetLook {
            val style = WidgetStyleId.of(styleKey)
            val pair = payload?.styles?.get(style.key)
            return WidgetLook(style, pair?.let { Palette(it.first, it.second) } ?: Palette.fallback)
        }
    }
}

/**
 * Per-widget settings chosen in [WidgetConfigActivity], kept in the
 * home_widget preferences next to the payload.
 */
object WidgetSettings {
    const val STANDARD = "standard"

    /** home_widget's preferences file (internal to the plugin). */
    const val PREFERENCES = "HomeWidgetPreferences"

    private fun styleKey(id: Int) = "widget_cfg_${id}_style"
    private fun countdownKey(id: Int) = "widget_cfg_${id}_cd"
    private fun monthOffsetKey(id: Int) = "widget_month_offset_$id"
    private fun monthDayKey(id: Int) = "widget_month_offset_day_$id"

    fun style(prefs: SharedPreferences, id: Int, payload: WidgetPayload?): String {
        val own = prefs.getString(styleKey(id), STANDARD) ?: STANDARD
        return if (own == STANDARD) payload?.prefs?.style ?: "app" else own
    }

    fun ownStyle(prefs: SharedPreferences, id: Int) = prefs.getString(styleKey(id), STANDARD) ?: STANDARD

    fun countdown(prefs: SharedPreferences, id: Int, payload: WidgetPayload?): String {
        val own = prefs.getString(countdownKey(id), STANDARD) ?: STANDARD
        return if (own == STANDARD) payload?.prefs?.cd ?: "fullMoon" else own
    }

    fun ownCountdown(prefs: SharedPreferences, id: Int) = prefs.getString(countdownKey(id), STANDARD) ?: STANDARD

    fun save(prefs: SharedPreferences, id: Int, style: String, countdown: String?) {
        prefs.edit().apply {
            putString(styleKey(id), style)
            if (countdown != null) putString(countdownKey(id), countdown)
        }.apply()
    }

    /** Months the Month widget is moved from today's month; resets each day. */
    fun monthOffset(prefs: SharedPreferences, id: Int, today: String): Int =
        if (prefs.getString(monthDayKey(id), null) == today) prefs.getInt(monthOffsetKey(id), 0) else 0

    fun moveMonth(prefs: SharedPreferences, id: Int, today: String, delta: Int) {
        // The payload holds last month to five months ahead.
        val next = (monthOffset(prefs, id, today) + delta).coerceIn(-1, 5)
        prefs.edit().putInt(monthOffsetKey(id), next).putString(monthDayKey(id), today).apply()
    }

    fun forget(prefs: SharedPreferences, ids: IntArray) {
        prefs.edit().apply {
            ids.forEach {
                remove(styleKey(it)); remove(countdownKey(it))
                remove(monthOffsetKey(it)); remove(monthDayKey(it))
            }
        }.apply()
    }
}
