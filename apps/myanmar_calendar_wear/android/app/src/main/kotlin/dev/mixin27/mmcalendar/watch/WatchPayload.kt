package dev.mixin27.mmcalendar.watch

import android.content.Context
import android.content.SharedPreferences
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import org.json.JSONArray
import org.json.JSONObject

/**
 * The slim payload Dart writes (WatchPayloadWriter, built by
 * WidgetPayloadBuilder.buildSlim in packages/shared/widget_payload): the
 * next 90 days, the words to print and what's coming up. Nothing here
 * converts dates or hard-codes text.
 */
class WatchPayload private constructor(json: JSONObject) {
    val lang: String = json.optString("lang")
    val s = Strings(json.getJSONObject("s"))
    private val days: Map<String, Day> =
        json.getJSONArray("days").objects().map { Day(it) }.associateBy { it.d }
    private val upcoming: List<Upcoming> = json.getJSONArray("upcoming").objects().map { Upcoming(it) }

    class Strings(o: JSONObject) {
        val today: String = o.getString("today")
        val tomorrow: String = o.getString("tomorrow")
        val inDays: String = o.getString("inDays")
        val digits: String = o.getString("digits")
        val westernDigits: String = o.optString("westernDigits", digits)
        val weekdays: List<String> = o.getJSONArray("weekdays").strings()
        val monthsShort: List<String> = o.getJSONArray("monthsShort").strings()
        val moonPhases: List<String> = o.getJSONArray("moonPhases").strings()
    }

    class Day(o: JSONObject) {
        val d: String = o.getString("d")
        val date: LocalDate = LocalDate.parse(d)

        /** Weekday, Sunday 0. */
        val wd: Int = o.getInt("wd")

        /** Myanmar month, moon phase and day ("Tazaungmon Waxing 5"). */
        val my: String = o.getString("my")

        /** Day of the fortnight in the language's digits. */
        val ln: String = o.getString("ln")

        /** 0 waxing, 1 full moon, 2 waning, 3 new moon. */
        val ph: Int = o.getInt("ph")

        /** Lit fraction of the evening moon, 0..1. */
        val il: Double = o.getDouble("il")
        val hol: List<String> = o.getJSONArray("hol").strings()

        /** 1 Sabbath, 2 Sabbath eve. */
        val sab: Int = o.getInt("sab")
    }

    class Upcoming(o: JSONObject) {
        val date: LocalDate = LocalDate.parse(o.getString("d"))

        /** holiday, sabbath, fullMoon or newMoon. */
        val kind: String = o.getString("k")
        val name: String = o.getString("n")
    }

    fun day(date: LocalDate): Day? = days[date.toString()]

    /** The next holiday or Sabbath on or after [date]. */
    fun nextHolidayOrSabbath(date: LocalDate): Upcoming? =
        upcoming.firstOrNull { !it.date.isBefore(date) && (it.kind == "holiday" || it.kind == "sabbath") }

    /** "Today", "Tomorrow" or "in 5 days" for [target] seen from [from]. */
    fun relative(from: LocalDate, target: LocalDate): String =
        when (val n = ChronoUnit.DAYS.between(from, target)) {
            0L -> s.today
            1L -> s.tomorrow
            else -> s.inDays.replace("{n}", digits(n.toString(), s.digits))
        }

    /** "Mon 6 Oct" in the payload's words and digits. */
    fun shortWestern(day: Day): String =
        "${s.weekdays[day.wd]} ${digits(day.date.dayOfMonth.toString(), s.westernDigits)} " +
            s.monthsShort[day.date.monthValue - 1]

    companion object {
        const val PREFS = "FlutterSharedPreferences"

        /** Dart's SharedPreferences key `watch_payload`, with its prefix. */
        const val PREF_KEY = "flutter.watch_payload"

        fun preferences(context: Context): SharedPreferences =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        fun read(context: Context): WatchPayload? =
            preferences(context).getString(PREF_KEY, null)?.let { parse(it) }

        fun parse(json: String): WatchPayload? =
            try {
                WatchPayload(JSONObject(json))
            } catch (e: Exception) {
                null
            }

        private fun digits(value: String, table: String): String =
            if (table.length != 10) value else value.map { c -> if (c in '0'..'9') table[c - '0'] else c }.joinToString("")
    }
}

private fun JSONArray.objects(): List<JSONObject> = (0 until length()).map { getJSONObject(it) }

private fun JSONArray.strings(): List<String> = (0 until length()).map { getString(it) }
