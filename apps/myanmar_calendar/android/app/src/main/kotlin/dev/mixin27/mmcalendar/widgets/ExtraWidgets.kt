package dev.mixin27.mmcalendar.widgets

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.glance.ColorFilter
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.height
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.TextAlign
import androidx.glance.color.ColorProvider as DayNightColor
import java.time.LocalDate
import java.time.temporal.ChronoUnit

// MARK: Countdown

class CountdownWidget : CalendarWidget() {
    override val sizes = setOf(WidgetSizes.small)

    private fun target(w: WidgetScope): WidgetPayload.Upcoming? =
        when (WidgetSettings.countdown(w.prefs, w.appWidgetId, w.payload)) {
            "thingyan" -> w.payload.thingyan
            "sabbath" -> w.payload.upcoming(w.today).firstOrNull { it.k == "sabbath" }
            "newMoon" -> w.payload.upcoming(w.today).firstOrNull { it.k == "newMoon" }
            else -> w.payload.upcoming(w.today).firstOrNull { it.k == "fullMoon" }
        }

    override fun link(w: WidgetScope) = target(w)?.let { "day/${it.d}" } ?: "today"

    @Composable
    override fun Content(w: WidgetScope) {
        val target = target(w)
        Column(modifier = GlanceModifier.fillMaxSize()) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                if (target != null && (target.k == "fullMoon" || target.k == "newMoon")) {
                    w.payload.day(LocalDate.parse(target.d))?.let { Moon(w, it, 28.dp) }
                    Spacer(GlanceModifier.width(6.dp))
                }
                if (target != null) {
                    val thingyan = target.k == "thingyan"
                    Chip(target.n, if (thingyan) w.p.holiday else w.p.accent, if (thingyan) w.p.holidaySoft else w.p.soft)
                }
            }
            Spacer(GlanceModifier.defaultWeight())
            val days = target?.let { w.payload.daysUntil(it.d, w.today) }
            if (target != null && days != null) {
                NumText(w, w.payload.num(days.toInt()), 44f)
                val date = LocalDate.parse(target.d)
                WText("${w.s.daysUnit} · ${w.payload.num(date.dayOfMonth)} ${w.s.monthsShort[date.monthValue - 1]}", 12f, w.p.muted)
            }
        }
    }
}

class CountdownWidgetReceiver : CalendarWidgetReceiver<CountdownWidget>() {
    override val glanceAppWidget = CountdownWidget()
}

// MARK: Astrology

class AstrologyWidget : CalendarWidget() {
    override val sizes = setOf(WidgetSizes.small, WidgetSizes.medium)

    private val good = DayNightColor(day = Color(0xFF1F9E63), night = Color(0xFF4CC38A))

    override fun link(w: WidgetScope) = "day/${w.today}"

    @Composable
    override fun Content(w: WidgetScope) {
        if (w.size == WidgetSizes.small) {
            Today(w)
        } else {
            Row(modifier = GlanceModifier.fillMaxSize()) {
                Box(modifier = GlanceModifier.defaultWeight().fillMaxHeight()) { Today(w) }
                Spacer(GlanceModifier.width(10.dp))
                Box(modifier = GlanceModifier.width(1.dp).fillMaxHeight().background(w.p.line)) {}
                Spacer(GlanceModifier.width(10.dp))
                Column(modifier = GlanceModifier.defaultWeight().fillMaxHeight()) {
                    Caps(w.s.nextGoodDay, w.p.muted)
                    Spacer(GlanceModifier.height(3.dp))
                    nextGood(w)?.let { (day, inDays) ->
                        WText(day.good.firstOrNull() ?: "", 15f, good, bold = true)
                        WText("${w.s.weekdays[day.wd]} · ${w.payload.countdown(inDays)}", 11.5f, w.p.muted)
                    }
                }
            }
        }
    }

    @Composable
    private fun Today(w: WidgetScope) {
        val day = w.day
        val headline = day.avoid.firstOrNull() ?: day.good.firstOrNull()
        val bad = day.avoid.isNotEmpty()
        Column(modifier = GlanceModifier.fillMaxSize()) {
            Caps(w.s.today, w.p.muted)
            Spacer(GlanceModifier.height(3.dp))
            WText(headline ?: day.lu, 18f, if (headline == null) w.p.ink else if (bad) w.p.holiday else good, bold = true, maxLines = 2)
            WText(
                if (headline == null) w.s.plainDay else if (bad) w.s.avoidDay else w.s.goodDay,
                11.5f, w.p.muted, maxLines = 2,
            )
            Spacer(GlanceModifier.defaultWeight())
            if (day.isSabbath || day.isSabbathEve) {
                Chip(if (day.isSabbath) w.s.sabbath else w.s.sabbathEve, w.p.sabbath, w.p.soft)
            }
        }
    }

    private fun nextGood(w: WidgetScope): Pair<WidgetPayload.Day, Long>? {
        val key = w.today.toString()
        val day = w.payload.days.firstOrNull { it.d > key && it.good.isNotEmpty() && it.avoid.isEmpty() } ?: return null
        return day to (w.payload.daysUntil(day.d, w.today) ?: return null)
    }
}

class AstrologyWidgetReceiver : CalendarWidgetReceiver<AstrologyWidget>() {
    override val glanceAppWidget = AstrologyWidget()
}

// MARK: Myanmar year

class YearWidget : CalendarWidget() {
    override val sizes = setOf(WidgetSizes.small)

    @Composable
    override fun Content(w: WidgetScope) {
        val ring = 96.dp
        val px = WidgetShapes.px(ring.value, w.density)
        Box(modifier = GlanceModifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Image(
                provider = ImageProvider(WidgetShapes.track(px)),
                contentDescription = null,
                colorFilter = ColorFilter.tint(w.p.soft),
                modifier = GlanceModifier.size(ring),
            )
            Image(
                provider = ImageProvider(WidgetShapes.ring(px, progress(w))),
                contentDescription = null,
                colorFilter = ColorFilter.tint(w.p.accent),
                modifier = GlanceModifier.size(ring),
            )
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                NumText(w, w.payload.year.n, 19f)
                Spacer(GlanceModifier.height(4.dp))
                WText(w.payload.year.month, 10.5f, w.p.muted, align = TextAlign.Center)
            }
        }
    }

    private fun progress(w: WidgetScope): Float = runCatching {
        val start = LocalDate.parse(w.payload.year.start)
        val end = LocalDate.parse(w.payload.year.end)
        val total = ChronoUnit.DAYS.between(start, end).toFloat()
        if (total <= 0) 0f else (ChronoUnit.DAYS.between(start, w.today) / total).coerceIn(0f, 1f)
    }.getOrDefault(0f)
}

class YearWidgetReceiver : CalendarWidgetReceiver<YearWidget>() {
    override val glanceAppWidget = YearWidget()
}
