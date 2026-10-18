package dev.mixin27.mmcalendar.widgets

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.TextAlign
import java.time.LocalDate

// MARK: Month

class MonthWidget : CalendarWidget() {
    override val sizes = setOf(WidgetSizes.medium, WidgetSizes.large)

    private fun monthDate(w: WidgetScope): LocalDate =
        w.today.withDayOfMonth(1).plusMonths(WidgetSettings.monthOffset(w.prefs, w.appWidgetId, w.today.toString()).toLong())

    override fun link(w: WidgetScope): String {
        val date = monthDate(w)
        return "month/%04d-%02d".format(date.year, date.monthValue)
    }

    @Composable
    override fun Content(w: WidgetScope) {
        val date = monthDate(w)
        val month = w.payload.months["%04d-%02d".format(date.year, date.monthValue)]
        if (month == null) {
            WText(w.payload.monthTitle(date), 15f, w.p.ink, bold = true)
            return
        }
        if (w.size == WidgetSizes.medium) {
            Row(modifier = GlanceModifier.fillMaxSize()) {
                Column(modifier = GlanceModifier.width(88.dp)) {
                    Caps(w.s.monthsShort[date.monthValue - 1], w.p.accent, 12f)
                    WText(month.sub, 11.5f, w.p.ink, medium = true, maxLines = 3)
                    Spacer(GlanceModifier.defaultWeight())
                    Arrows(w)
                }
                Spacer(GlanceModifier.width(8.dp))
                MonthGrid(w, month, date, dense = true, modifier = GlanceModifier.defaultWeight().fillMaxHeight())
            }
        } else {
            Column(modifier = GlanceModifier.fillMaxSize()) {
                Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Column(modifier = GlanceModifier.defaultWeight()) {
                        WText(month.title, 16f, w.p.ink, bold = true)
                        WText(month.sub, 11.5f, w.p.muted)
                    }
                    Arrows(w)
                }
                Spacer(GlanceModifier.height(4.dp))
                MonthGrid(w, month, date, dense = false, modifier = GlanceModifier.defaultWeight().fillMaxWidth())
            }
        }
    }

    @Composable
    private fun Arrows(w: WidgetScope) {
        Row {
            for (delta in listOf(-1, 1)) {
                if (delta > 0) Spacer(GlanceModifier.width(6.dp))
                Box(
                    modifier = GlanceModifier
                        .size(28.dp)
                        .cornerRadius(14.dp)
                        .background(w.p.soft)
                        .clickable(actionRunCallback<ChangeMonthAction>(actionParametersOf(ChangeMonthAction.delta to delta))),
                    contentAlignment = Alignment.Center,
                ) {
                    WText(if (delta < 0) "‹" else "›", 17f, w.p.accent, bold = true, align = TextAlign.Center)
                }
            }
        }
    }
}

/** The ‹ › buttons: moves this Month widget a month and redraws it. */
class ChangeMonthAction : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        val id = GlanceAppWidgetManager(context).getAppWidgetId(glanceId)
        val prefs = context.getSharedPreferences(WidgetSettings.PREFERENCES, Context.MODE_PRIVATE)
        WidgetSettings.moveMonth(prefs, id, LocalDate.now().toString(), parameters[delta] ?: 0)
        MonthWidget().update(context, glanceId)
    }

    companion object {
        val delta = ActionParameters.Key<Int>("delta")
    }
}

class MonthWidgetReceiver : CalendarWidgetReceiver<MonthWidget>() {
    override val glanceAppWidget = MonthWidget()
}

// MARK: Coming up

class ComingUpWidget : CalendarWidget() {
    override val sizes = setOf(WidgetSizes.medium, WidgetSizes.large)

    @Composable
    override fun Content(w: WidgetScope) {
        val large = w.size == WidgetSizes.large
        Column(modifier = GlanceModifier.fillMaxSize()) {
            Caps(w.s.comingUp, w.p.accent, 12f)
            comingUp(w, w.today).take(if (large) 6 else 3).forEach { item ->
                Row(item, w, GlanceModifier.padding(top = if (large) 7.dp else 5.dp))
            }
        }
    }

    @Composable
    private fun Row(item: WidgetPayload.Upcoming, w: WidgetScope, modifier: GlanceModifier) {
        val holiday = item.k == "holiday"
        val date = LocalDate.parse(item.d)
        Row(
            modifier = modifier.fillMaxWidth().clickable(widgetAction(w.context, "day/${item.d}")),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(
                modifier = GlanceModifier.size(30.dp).cornerRadius(9.dp).background(if (holiday) w.p.holidaySoft else w.p.soft),
                contentAlignment = Alignment.Center,
            ) {
                NumText(w, w.payload.num(date.dayOfMonth), 13f, if (holiday) w.p.holiday else w.p.accent)
            }
            Spacer(GlanceModifier.width(10.dp))
            Column(modifier = GlanceModifier.defaultWeight()) {
                WText(item.n, 13f, w.p.ink, medium = true)
                WText(w.payload.countdown(w.payload.daysUntil(item.d, w.today) ?: 0), 11f, w.p.muted)
            }
            if (item.k == "fullMoon" || item.k == "newMoon") {
                w.payload.day(date)?.let { Moon(w, it, 18.dp) }
            }
        }
    }
}

class ComingUpWidgetReceiver : CalendarWidgetReceiver<ComingUpWidget>() {
    override val glanceAppWidget = ComingUpWidget()
}

// MARK: Agenda

class AgendaWidget : CalendarWidget() {
    override val sizes = setOf(WidgetSizes.medium, WidgetSizes.large)

    override fun link(w: WidgetScope) = "events"

    @Composable
    override fun Content(w: WidgetScope) {
        val large = w.size == WidgetSizes.large
        val today = w.payload.events(w.today)
        val next = w.payload.events(w.today.plusDays(1))
        Column(modifier = GlanceModifier.fillMaxSize()) {
            Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                NumText(w, w.payload.num(w.today.dayOfMonth), 26f)
                Spacer(GlanceModifier.width(8.dp))
                Column(modifier = GlanceModifier.defaultWeight()) {
                    Caps(w.s.weekdays[w.day.wd], w.p.holiday)
                    WText(w.day.my, 11f, w.p.muted)
                }
                Box(
                    modifier = GlanceModifier
                        .size(28.dp)
                        .cornerRadius(14.dp)
                        .background(w.p.soft)
                        .clickable(widgetAction(w.context, "events/new")),
                    contentAlignment = Alignment.Center,
                ) {
                    WText("+", 17f, w.p.accent, bold = true, align = TextAlign.Center)
                }
            }
            Spacer(GlanceModifier.height(4.dp))
            Divider(w)
            Column(modifier = GlanceModifier.fillMaxWidth().padding(top = 6.dp)) {
                if (today.isEmpty()) {
                    WText(w.s.noEvents, 13f, w.p.muted)
                } else {
                    today.take(if (large) 4 else 2).forEach {
                        EventRow(w, it, modifier = GlanceModifier.padding(bottom = 5.dp))
                    }
                }
            }
            if (large && next.isNotEmpty()) {
                Column(modifier = GlanceModifier.fillMaxWidth().padding(top = 6.dp)) {
                    Caps(w.s.tomorrow, w.p.muted)
                    next.take(3).forEach {
                        EventRow(w, it, modifier = GlanceModifier.padding(top = 5.dp))
                    }
                }
            }
        }
    }
}

class AgendaWidgetReceiver : CalendarWidgetReceiver<AgendaWidget>() {
    override val glanceAppWidget = AgendaWidget()
}
