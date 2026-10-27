package dev.mixin27.mmcalendar.widgets

import android.content.SharedPreferences
import java.time.LocalDate
import java.time.temporal.ChronoUnit
import org.json.JSONArray
import org.json.JSONObject

/**
 * `widget_data_v2`, written by the app (WidgetPayloadBuilder in
 * packages/features/home_widgets). Everything a widget draws comes from here,
 * including every word, so nothing is hard-coded on this side.
 */
class WidgetPayload private constructor(json: JSONObject) {
    val lang: String = json.optString("lang")
    val s = Strings(json.getJSONObject("s"))
    val days: List<Day> = json.getJSONArray("days").map { Day(it) }
    val months: Map<String, Month> = json.getJSONObject("months").let { o ->
        o.keys().asSequence().associateWith { Month(o.getJSONObject(it)) }
    }
    val upcoming: List<Upcoming> = json.getJSONArray("upcoming").map { Upcoming(it) }
    val thingyan: Upcoming? = json.optJSONObject("thingyan")?.let {
        Upcoming(it.getString("d"), "thingyan", it.getString("n"))
    }
    val events: List<Event> = json.getJSONArray("events").map { Event(it) }
    val year = Year(json.getJSONObject("year"))
    val styles: Map<String, Pair<Map<String, Int>, Map<String, Int>>> =
        json.getJSONObject("styles").let { o ->
            o.keys().asSequence().associateWith { key ->
                val pair = o.getJSONObject(key)
                colours(pair.getJSONObject("light")) to colours(pair.getJSONObject("dark"))
            }
        }
    val prefs = Prefs(json.getJSONObject("prefs"))

    private val dayIndex = days.associateBy { it.d }

    class Strings(o: JSONObject) {
        val today = o.getString("today")
        val tomorrow = o.getString("tomorrow")
        val inDays = o.getString("inDays")
        val daysUnit = o.getString("daysUnit")
        val comingUp = o.getString("comingUp")
        val noEvents = o.getString("noEvents")
        val allDay = o.getString("allDay")
        val nextGoodDay = o.getString("nextGoodDay")
        val goodDay = o.getString("goodDay")
        val avoidDay = o.getString("avoidDay")
        val plainDay = o.getString("plainDay")
        val myanmarYear = o.getString("myanmarYear")
        val fullMoonIn = o.getString("fullMoonIn")
        val newMoonIn = o.getString("newMoonIn")
        val digits = o.getString("digits")

        /** Digits for Western dates: English with Settings › English numbers for Western dates. */
        val westernDigits = o.optString("westernDigits", digits)
        val sabbath = o.getString("sabbath")
        val sabbathEve = o.getString("sabbathEve")
        val weekdays = o.getJSONArray("weekdays").strings()
        val weekdaysShort = o.getJSONArray("weekdaysShort").strings()
        val months = o.getJSONArray("months").strings()
        val monthsShort = o.getJSONArray("monthsShort").strings()
    }

    class Day(o: JSONObject) {
        val d: String = o.getString("d")
        val wd: Int = o.getInt("wd")
        val my: String = o.getString("my")
        val lu: String = o.getString("lu")
        val ln: String = o.getString("ln")
        val ph: Int = o.getInt("ph")
        val il: Double = o.getDouble("il")
        val wx: Boolean = o.getBoolean("wx")
        val hol: List<String> = o.getJSONArray("hol").strings()
        val sab: Int = o.getInt("sab")
        val good: List<String> = o.getJSONArray("good").strings()
        val avoid: List<String> = o.getJSONArray("avoid").strings()

        val isSabbath get() = sab == 1
        val isSabbathEve get() = sab == 2
    }

    class Month(o: JSONObject) {
        val title: String = o.getString("title")
        val sub: String = o.getString("sub")
        val cells: List<Cell> = o.getJSONArray("cells").map { Cell(it) }

        class Cell(o: JSONObject) {
            val d: Int = o.getInt("d")
            val inMonth: Boolean = o.getBoolean("in")
            val ln: String = o.getString("ln")
            val ph: Int = o.getInt("ph")
            val hol: Boolean = o.getBoolean("hol")
            val sab: Boolean = o.getBoolean("sab")
        }
    }

    class Upcoming(val d: String, val k: String?, val n: String) {
        constructor(o: JSONObject) : this(o.getString("d"), o.optString("k").ifEmpty { null }, o.getString("n"))
    }

    class Event(o: JSONObject) {
        val d: String = o.getString("d")
        val t: String? = if (o.isNull("t")) null else o.getString("t")
        val ti: String = o.getString("ti")
        val c: Int = o.getLong("c").toInt()
        val id: Int? = if (o.isNull("id")) null else o.getInt("id")
        val done: Boolean = o.optBoolean("done")
    }

    class Year(o: JSONObject) {
        val n: String = o.getString("n")
        val start: String = o.getString("start")
        val end: String = o.getString("end")
        val month: String = o.getString("month")
    }

    class Prefs(o: JSONObject) {
        val style: String = o.optString("style", "app")
        val hol: Boolean = o.optBoolean("hol", true)
        val sab: Boolean = o.optBoolean("sab", true)
        val ast: Boolean = o.optBoolean("ast", true)
        val ev: Boolean = o.optBoolean("ev", true)
        val cd: String = o.optString("cd", "fullMoon")
    }

    fun day(date: LocalDate): Day? = dayIndex[date.toString()]

    /** [value] in the calendar language's digits. */
    fun num(value: Int): String = spell(value, s.digits)

    /** A Western day or year: [value] in the Western-date digits. */
    fun westernNum(value: Int): String = spell(value, s.westernDigits)

    private fun spell(value: Int, digits: String): String {
        if (digits.length != 10) return value.toString()
        return value.toString().map { ch ->
            if (ch in '0'..'9') digits[ch - '0'] else ch
        }.joinToString("")
    }

    /** "in 8 days", "Tomorrow" or "Today". */
    fun countdown(days: Long): String = when (days) {
        0L -> s.today
        1L -> s.tomorrow
        else -> s.inDays.replace("{n}", num(days.toInt()))
    }

    fun daysUntil(key: String, from: LocalDate): Long? =
        runCatching { ChronoUnit.DAYS.between(from, LocalDate.parse(key)) }.getOrNull()

    fun upcoming(from: LocalDate): List<Upcoming> {
        val key = from.toString()
        return upcoming.filter { it.d >= key }
    }

    fun events(on: LocalDate): List<Event> {
        val key = on.toString()
        return events.filter { it.d == key }
    }

    fun monthTitle(date: LocalDate) = "${s.months[date.monthValue - 1]} ${westernNum(date.year)}"

    companion object {
        const val KEY = "widget_data_v2"

        private var cached: Pair<String, WidgetPayload>? = null

        /** The latest payload the app wrote, parsed once per change. */
        @Synchronized
        fun load(prefs: SharedPreferences): WidgetPayload? {
            val raw = prefs.getString(KEY, null) ?: return null
            cached?.let { (r, p) -> if (r == raw) return p }
            return runCatching { WidgetPayload(JSONObject(raw)) }.getOrNull()?.also {
                cached = raw to it
            }
        }

        private fun colours(o: JSONObject): Map<String, Int> =
            o.keys().asSequence().associateWith { o.getLong(it).toInt() }
    }
}

private fun <T> JSONArray.map(transform: (JSONObject) -> T): List<T> =
    (0 until length()).map { transform(getJSONObject(it)) }

private fun JSONArray.strings(): List<String> = (0 until length()).map { getString(it) }
