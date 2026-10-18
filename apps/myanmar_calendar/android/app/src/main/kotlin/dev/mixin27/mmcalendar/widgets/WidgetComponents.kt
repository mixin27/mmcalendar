package dev.mixin27.mmcalendar.widgets

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.clickable
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontFamily
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextDecoration
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import java.time.LocalDate

@Composable
fun WText(
    text: String,
    size: Float,
    color: ColorProvider,
    modifier: GlanceModifier = GlanceModifier,
    bold: Boolean = false,
    medium: Boolean = false,
    maxLines: Int = 1,
    font: FontFamily? = null,
    align: TextAlign? = null,
    strike: Boolean = false,
) {
    Text(
        text = text,
        modifier = modifier,
        maxLines = maxLines,
        style = TextStyle(
            color = color,
            fontSize = size.sp,
            fontWeight = if (bold) FontWeight.Bold else if (medium) FontWeight.Medium else FontWeight.Normal,
            fontFamily = font,
            textAlign = align,
            textDecoration = if (strike) TextDecoration.LineThrough else null,
        ),
    )
}

/** A number in the style's number font. */
@Composable
fun NumText(w: WidgetScope, text: String, size: Float, color: ColorProvider = w.p.ink, modifier: GlanceModifier = GlanceModifier) {
    WText(text, size, color, modifier, bold = true, font = w.look.numberFont)
}

/** An uppercase section label. */
@Composable
fun Caps(text: String, color: ColorProvider, size: Float = 11f) {
    WText(text.uppercase(), size, color, bold = true)
}

@Composable
fun MoonImage(w: WidgetScope, illumination: Double, waxing: Boolean, size: Dp) {
    val px = WidgetShapes.px(size.value, w.density)
    Box(modifier = GlanceModifier.size(size)) {
        Image(
            provider = ImageProvider(WidgetShapes.disc(px)),
            contentDescription = null,
            colorFilter = ColorFilter.tint(w.p.shade),
            modifier = GlanceModifier.size(size),
        )
        Image(
            provider = ImageProvider(WidgetShapes.moonLit(px, illumination, waxing)),
            contentDescription = null,
            colorFilter = ColorFilter.tint(w.p.moon),
            modifier = GlanceModifier.size(size),
        )
    }
}

@Composable
fun Moon(w: WidgetScope, day: WidgetPayload.Day, size: Dp) = MoonImage(w, day.il, day.wx, size)

@Composable
fun Chip(text: String, foreground: ColorProvider, background: ColorProvider) {
    Box(
        modifier = GlanceModifier
            .background(background)
            .cornerRadius(10.dp)
            .padding(horizontal = 7.dp, vertical = 2.dp),
    ) {
        WText(text, 10.5f, foreground, bold = true)
    }
}

@Composable
fun Dot(color: ColorProvider, size: Dp) {
    Box(modifier = GlanceModifier.size(size).cornerRadius(size / 2).background(color)) {}
}

@Composable
fun Divider(w: WidgetScope) {
    Box(modifier = GlanceModifier.fillMaxWidth().height(1.dp).background(w.p.line)) {}
}

/** Sabbath, a holiday and an astrological day for [day], as chips. */
@Composable
fun TodayChips(w: WidgetScope, day: WidgetPayload.Day, max: Int = 3) {
    val p = w.p
    val prefs = w.payload.prefs
    val list = mutableListOf<Triple<String, ColorProvider, ColorProvider>>()
    if (prefs.sab) {
        if (day.isSabbath) list += Triple(w.s.sabbath, p.sabbath, p.soft)
        else if (w.payload.day(LocalDate.parse(day.d).plusDays(1))?.isSabbath == true) {
            list += Triple("${w.s.tomorrow} · ${w.s.sabbath}", p.accent, p.soft)
        }
    }
    if (prefs.hol) day.hol.firstOrNull()?.let { list += Triple(it, p.holiday, p.holidaySoft) }
    if (prefs.ast) {
        val avoid = day.avoid.firstOrNull()
        val good = day.good.firstOrNull()
        if (avoid != null) list += Triple(avoid, p.holiday, p.holidaySoft)
        else if (good != null) list += Triple(good, p.accent, p.soft)
    }
    if (list.isEmpty()) return
    Row(verticalAlignment = Alignment.CenterVertically) {
        list.take(max).forEachIndexed { i, (text, fg, bg) ->
            if (i > 0) Spacer(GlanceModifier.width(5.dp))
            Chip(text, fg, bg)
        }
    }
}

/** Seven days from [start] with moons and Sabbath dots; [start] highlighted. */
@Composable
fun WeekStrip(w: WidgetScope, start: LocalDate) {
    val p = w.p
    Row(modifier = GlanceModifier.fillMaxWidth()) {
        for (i in 0 until 7) {
            val date = start.plusDays(i.toLong())
            val day = w.payload.day(date)
            val highlight = i == 0
            Column(
                modifier = GlanceModifier
                    .defaultWeight()
                    .cornerRadius(10.dp)
                    .background(if (highlight) p.soft else ColorProvider(Color.Transparent))
                    .padding(vertical = 4.dp)
                    .clickable(widgetAction(w.context, "day/$date")),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                WText(day?.let { w.s.weekdaysShort[it.wd] } ?: "", 9.5f, if (day?.wd == 0) p.holiday else p.muted, medium = true)
                NumText(
                    w, w.payload.num(date.dayOfMonth), 15f,
                    when {
                        highlight -> p.accent
                        day?.hol?.isNotEmpty() == true -> p.holiday
                        else -> p.ink
                    },
                )
                if (day != null) Moon(w, day, 12.dp)
                Spacer(GlanceModifier.height(2.dp))
                Dot(if (day?.isSabbath == true) p.sabbath else ColorProvider(Color.Transparent), 4.dp)
            }
        }
    }
}

/**
 * The month as 7 columns, lunar days under the dates (unless [dense]),
 * today filled, holidays in red and Sabbath dots.
 */
@Composable
fun MonthGrid(w: WidgetScope, month: WidgetPayload.Month, monthDate: LocalDate, dense: Boolean, modifier: GlanceModifier = GlanceModifier) {
    val p = w.p
    val todayDay = if (monthDate.year == w.today.year && monthDate.month == w.today.month) w.today.dayOfMonth else null
    val rows = if (month.cells[35].inMonth) 6 else 5
    Column(modifier = modifier) {
        Row(modifier = GlanceModifier.fillMaxWidth()) {
            for (i in 0 until 7) {
                WText(
                    w.s.weekdaysShort[i], if (dense) 8.5f else 9.5f, if (i == 0) p.holiday else p.muted,
                    GlanceModifier.defaultWeight(), medium = true, align = TextAlign.Center,
                )
            }
        }
        for (row in 0 until rows) {
            Row(modifier = GlanceModifier.fillMaxWidth().defaultWeight()) {
                for (col in 0 until 7) {
                    val c = month.cells[row * 7 + col]
                    val isToday = c.inMonth && c.d == todayDay
                    val red = c.inMonth && (c.hol || col == 0)
                    val fade = !c.inMonth
                    val ink = when {
                        isToday -> p.onAccent
                        fade -> p.line
                        red -> p.holiday
                        else -> p.ink
                    }
                    var cell = GlanceModifier.defaultWeight().cornerRadius(if (dense) 6.dp else 8.dp)
                    if (isToday) cell = cell.background(p.accent)
                    else if (c.inMonth && c.hol) cell = cell.background(p.holidaySoft)
                    if (c.inMonth) {
                        cell = cell.clickable(widgetAction(w.context, "day/${monthDate.withDayOfMonth(c.d)}"))
                    }
                    Column(modifier = cell, horizontalAlignment = Alignment.CenterHorizontally, verticalAlignment = Alignment.CenterVertically) {
                        NumText(w, w.payload.num(c.d), if (dense) 10.5f else 13f, ink)
                        if (!dense) {
                            when {
                                c.ph == 1 -> Dot(if (fade) p.line else p.moon, 5.dp)
                                c.ph == 3 -> Dot(if (fade) p.line else p.shade, 5.dp)
                                else -> WText(c.ln, 7.5f, if (isToday) p.onAccent else if (fade) p.line else p.muted)
                            }
                            Spacer(GlanceModifier.height(1.dp))
                            Dot(if (c.sab && c.inMonth) p.sabbath else ColorProvider(Color.Transparent), 3.5.dp)
                        }
                    }
                }
            }
        }
    }
}

/** A coloured bar, the title and its time. */
@Composable
fun EventRow(w: WidgetScope, event: WidgetPayload.Event, subtitle: String? = null, modifier: GlanceModifier = GlanceModifier) {
    Row(
        modifier = modifier.fillMaxWidth().clickable(widgetAction(w.context, event.id?.let { "event/$it" } ?: "events")),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(modifier = GlanceModifier.width(3.dp).height(26.dp).cornerRadius(2.dp).background(ColorProvider(Color(event.c)))) {}
        Spacer(GlanceModifier.width(8.dp))
        Column {
            WText(event.ti, 13f, w.p.ink, medium = true, strike = event.done)
            WText(listOfNotNull(event.t ?: w.s.allDay, subtitle).joinToString(" · "), 11f, w.p.muted)
        }
    }
}

/** Coming-up items, honouring the holiday and Sabbath toggles. */
fun comingUp(w: WidgetScope, from: LocalDate): List<WidgetPayload.Upcoming> =
    w.payload.upcoming(from).filter {
        when (it.k) {
            "holiday" -> w.payload.prefs.hol
            "sabbath" -> w.payload.prefs.sab
            else -> true
        }
    }
