package dev.mixin27.mmcalendar.widgets

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.width

// MARK: Today

class TodayWidget : CalendarWidget() {
    override val sizes = setOf(WidgetSizes.line, WidgetSizes.small, WidgetSizes.medium, WidgetSizes.large)

    override fun link(w: WidgetScope) = "day/${w.today}"

    @Composable
    override fun Content(w: WidgetScope) {
        when (w.size) {
            WidgetSizes.line -> GlanceLine(w)
            WidgetSizes.small -> Small(w)
            WidgetSizes.medium -> Medium(w)
            else -> Large(w)
        }
    }

    /** The 4×1 line, in place of Pixel's At a Glance: date · Myanmar date · what's next. */
    @Composable
    private fun GlanceLine(w: WidgetScope) {
        val day = w.day
        val note = day.hol.firstOrNull()?.takeIf { w.payload.prefs.hol }
            ?: (if (day.isSabbath) w.s.sabbath else null)
            ?: comingUp(w, w.today.plusDays(1)).firstOrNull()?.let { item ->
                "${item.n} · ${w.payload.countdown(w.payload.daysUntil(item.d, w.today) ?: 0)}"
            }
        Row(modifier = GlanceModifier.fillMaxSize(), verticalAlignment = Alignment.CenterVertically) {
            Moon(w, day, 22.dp)
            Spacer(GlanceModifier.width(8.dp))
            Column(modifier = GlanceModifier.defaultWeight()) {
                WText("${w.s.weekdays[day.wd]} ${w.payload.westernNum(w.today.dayOfMonth)} · ${day.my}", 13f, w.p.ink, bold = true)
                if (note != null) WText(note, 11.5f, w.p.muted)
            }
        }
    }

    @Composable
    private fun Small(w: WidgetScope) {
        val day = w.day
        Column(modifier = GlanceModifier.fillMaxSize()) {
            Caps(w.s.weekdays[day.wd], w.p.holiday, 12f)
            NumText(w, w.payload.westernNum(w.today.dayOfMonth), 44f)
            WText(w.s.months[w.today.monthValue - 1], 12.5f, w.p.muted)
            Spacer(GlanceModifier.defaultWeight())
            Row(verticalAlignment = Alignment.CenterVertically) {
                Moon(w, day, 18.dp)
                Spacer(GlanceModifier.width(6.dp))
                WText(day.lu, 12.5f, w.p.ink, medium = true)
            }
        }
    }

    @Composable
    private fun Medium(w: WidgetScope) {
        val day = w.day
        Row(modifier = GlanceModifier.fillMaxSize()) {
            Column(modifier = GlanceModifier.width(104.dp)) {
                Caps(w.s.weekdays[day.wd], w.p.holiday, 12f)
                NumText(w, w.payload.westernNum(w.today.dayOfMonth), 44f)
                WText(w.payload.monthTitle(w.today), 12.5f, w.p.muted)
            }
            Column(modifier = GlanceModifier.defaultWeight()) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Moon(w, day, 30.dp)
                    Spacer(GlanceModifier.width(8.dp))
                    Column {
                        WText(day.my, 14f, w.p.ink, bold = true, maxLines = 2)
                        WText("${w.s.myanmarYear} ${w.payload.year.n}", 11.5f, w.p.muted)
                    }
                }
                Spacer(GlanceModifier.defaultWeight())
                TodayChips(w, day, max = 2)
            }
        }
    }

    @Composable
    private fun Large(w: WidgetScope) {
        val day = w.day
        val tomorrow = w.today.plusDays(1).toString()
        val next = comingUp(w, w.today.plusDays(1))
            .filterNot { it.k == "sabbath" && it.d == tomorrow }
            .take(2)
        Column(modifier = GlanceModifier.fillMaxSize()) {
            Row(modifier = GlanceModifier.fillMaxWidth()) {
                Column(modifier = GlanceModifier.defaultWeight()) {
                    Caps(w.s.weekdays[day.wd], w.p.holiday, 12f)
                    NumText(w, w.payload.westernNum(w.today.dayOfMonth), 48f)
                    WText(w.payload.monthTitle(w.today), 13f, w.p.muted)
                }
                Moon(w, day, 60.dp)
            }
            Column(modifier = GlanceModifier.fillMaxWidth()) {
                WText(day.my, 15f, w.p.ink, bold = true)
                WText("${w.s.myanmarYear} ${w.payload.year.n}", 12f, w.p.muted)
                Spacer(GlanceModifier.height(4.dp))
                TodayChips(w, day)
            }
            Spacer(GlanceModifier.defaultWeight())
            Column(modifier = GlanceModifier.fillMaxWidth()) {
                next.forEach { item ->
                    Row(
                        modifier = GlanceModifier.fillMaxWidth().padding(bottom = 3.dp).clickable(widgetAction(w.context, "day/${item.d}")),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Dot(
                            when (item.k) {
                                "holiday" -> w.p.holiday
                                "sabbath" -> w.p.sabbath
                                else -> w.p.moon
                            },
                            6.dp,
                        )
                        Spacer(GlanceModifier.width(8.dp))
                        WText(item.n, 13f, w.p.ink, GlanceModifier.defaultWeight(), medium = true)
                        WText(w.payload.countdown(w.payload.daysUntil(item.d, w.today) ?: 0), 11.5f, w.p.muted)
                    }
                }
                Spacer(GlanceModifier.height(4.dp))
                Divider(w)
                Spacer(GlanceModifier.height(4.dp))
                WeekStrip(w, w.today)
            }
        }
    }
}

class TodayWidgetReceiver : CalendarWidgetReceiver<TodayWidget>() {
    override val glanceAppWidget = TodayWidget()
}

// MARK: Moon

class MoonWidget : CalendarWidget() {
    override val sizes = setOf(WidgetSizes.small, WidgetSizes.medium)

    override fun link(w: WidgetScope) = "day/${w.today}"

    @Composable
    override fun Content(w: WidgetScope) {
        val day = w.day
        val next = nextMoon(w)
        if (w.size == WidgetSizes.small) {
            Column(modifier = GlanceModifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally) {
                Moon(w, day, 60.dp)
                Spacer(GlanceModifier.height(4.dp))
                WText(day.lu, 14f, w.p.ink, bold = true)
                if (next != null) WText(next, 11.5f, w.p.muted)
            }
        } else {
            Row(modifier = GlanceModifier.fillMaxSize(), verticalAlignment = Alignment.CenterVertically) {
                Moon(w, day, 84.dp)
                Spacer(GlanceModifier.width(14.dp))
                Column(modifier = GlanceModifier.defaultWeight()) {
                    WText(day.my, 15f, w.p.ink, bold = true, maxLines = 2)
                    if (next != null) WText(next, 12.5f, w.p.accent, medium = true)
                    Spacer(GlanceModifier.height(6.dp))
                    Row(modifier = GlanceModifier.fillMaxWidth()) {
                        for (offset in listOf(0L, 2L, 4L, 6L, 8L)) {
                            val date = w.today.plusDays(offset)
                            Column(modifier = GlanceModifier.defaultWeight(), horizontalAlignment = Alignment.CenterHorizontally) {
                                w.payload.day(date)?.let { Moon(w, it, 20.dp) }
                                WText(w.payload.westernNum(date.dayOfMonth), 10.5f, w.p.muted)
                            }
                        }
                    }
                }
            }
        }
    }

    /** "Full moon in 8 days", from the next moon in coming up. */
    private fun nextMoon(w: WidgetScope): String? {
        val item = w.payload.upcoming(w.today).firstOrNull { it.k == "fullMoon" || it.k == "newMoon" } ?: return null
        val days = w.payload.daysUntil(item.d, w.today) ?: return null
        if (days == 0L) return item.n
        val template = if (item.k == "fullMoon") w.s.fullMoonIn else w.s.newMoonIn
        return template.replace("{n}", w.payload.num(days.toInt()))
    }
}

class MoonWidgetReceiver : CalendarWidgetReceiver<MoonWidget>() {
    override val glanceAppWidget = MoonWidget()
}

// MARK: Week

class WeekWidget : CalendarWidget() {
    override val sizes = setOf(WidgetSizes.medium)

    @Composable
    override fun Content(w: WidgetScope) {
        Column(modifier = GlanceModifier.fillMaxSize()) {
            WeekStrip(w, w.today)
            Spacer(GlanceModifier.height(4.dp))
            Divider(w)
            Spacer(GlanceModifier.height(4.dp))
            val event = if (w.payload.prefs.ev) w.payload.events(w.today).firstOrNull() else null
            if (event != null) EventRow(w, event, w.day.my)
            else WText(w.day.my, 13f, w.p.ink, medium = true)
        }
    }
}

class WeekWidgetReceiver : CalendarWidgetReceiver<WeekWidget>() {
    override val glanceAppWidget = WeekWidget()
}
