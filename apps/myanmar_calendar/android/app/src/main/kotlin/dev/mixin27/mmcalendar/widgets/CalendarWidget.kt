package dev.mixin27.mmcalendar.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.ColorFilter
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.appWidgetBackground
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.layout.size
import dev.mixin27.mmcalendar.MainActivity
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import es.antonborri.home_widget.HomeWidgetScheduler
import es.antonborri.home_widget.actionStartActivity
import java.time.LocalDate
import java.time.ZoneId

/** Everything a widget's content needs for one draw. */
class WidgetScope(
    val context: Context,
    val appWidgetId: Int,
    val prefs: SharedPreferences,
    val payload: WidgetPayload,
    val day: WidgetPayload.Day,
    val today: LocalDate,
    val look: WidgetLook,
    val size: DpSize,
) {
    val p get() = look.palette
    val s get() = payload.s
    val density: Float get() = context.resources.displayMetrics.density
}

/** Widget sizes shared by the Android widgets, after the iOS families. */
object WidgetSizes {
    val line = DpSize(200.dp, 40.dp)
    val small = DpSize(110.dp, 110.dp)
    val wideSmall = DpSize(180.dp, 110.dp)
    val medium = DpSize(250.dp, 110.dp)
    val tall = DpSize(180.dp, 220.dp)
    val large = DpSize(250.dp, 250.dp)
}

/**
 * The frame every widget shares: its style's background with the motif in
 * the corner, the tap link, and an empty state before the app has written
 * data. Reads the home_widget preferences, so app writes redraw it.
 */
abstract class CalendarWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    abstract val sizes: Set<DpSize>
    override val sizeMode: SizeMode get() = SizeMode.Responsive(sizes)

    /** Where a tap on the widget goes (`mmcalendar://<path>`). */
    open fun link(w: WidgetScope): String = "today"

    @Composable
    abstract fun Content(w: WidgetScope)

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appWidgetId = runCatching { GlanceAppWidgetManager(context).getAppWidgetId(id) }
            .getOrDefault(AppWidgetManager.INVALID_APPWIDGET_ID)
        provideContent {
            val prefs = currentState<HomeWidgetGlanceState>().preferences
            val payload = WidgetPayload.load(prefs)
            val look = WidgetLook.resolve(payload, WidgetSettings.style(prefs, appWidgetId, payload))
            val today = LocalDate.now()
            val day = payload?.day(today)
            val scope = if (payload != null && day != null) {
                WidgetScope(LocalContext.current, appWidgetId, prefs, payload, day, today, look, LocalSize.current)
            } else null
            Shell(look, scope?.let { link(it) } ?: "today") {
                if (scope == null) OpenApp(look) else Content(scope)
            }
        }
    }
}

@Composable
private fun Shell(look: WidgetLook, link: String, content: @Composable () -> Unit) {
    val context = LocalContext.current
    val density = context.resources.displayMetrics.density
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .appWidgetBackground()
            .cornerRadius(20.dp)
            .background(look.palette.bg)
            .clickable(widgetAction(context, link)),
        contentAlignment = Alignment.TopEnd,
    ) {
        WidgetShapes.motif(look.style, WidgetShapes.px(56f, density))?.let {
            Image(
                provider = ImageProvider(it),
                contentDescription = null,
                colorFilter = ColorFilter.tint(look.palette.motif),
                modifier = GlanceModifier.size(56.dp),
            )
        }
        Column(modifier = GlanceModifier.fillMaxSize().padding(14.dp)) {
            content()
        }
    }
}

/** `mmcalendar://<path>?homeWidget`; the app opens the matching screen. */
fun widgetAction(context: Context, path: String) =
    actionStartActivity<MainActivity>(context, Uri.parse("mmcalendar://$path?homeWidget"))

@Composable
private fun OpenApp(look: WidgetLook) {
    Box(modifier = GlanceModifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        WText("Myanmar Calendar", 12f, look.palette.muted, bold = true)
    }
}

/**
 * The receiver every widget uses. Each update keeps the next week of
 * midnights scheduled, so the date rolls over without the app running, and
 * a removed widget's own settings are forgotten.
 */
abstract class CalendarWidgetReceiver<T : GlanceAppWidget> : HomeWidgetGlanceWidgetReceiver<T>() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        val zone = ZoneId.systemDefault()
        val midnights = (1L..7L).map {
            LocalDate.now(zone).plusDays(it).atStartOfDay(zone).toInstant().toEpochMilli() + 5_000
        }
        runCatching { HomeWidgetScheduler.schedule(context, javaClass.name, midnights) }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        WidgetSettings.forget(context.getSharedPreferences(WidgetSettings.PREFERENCES, Context.MODE_PRIVATE), appWidgetIds)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        HomeWidgetScheduler.cancel(context, javaClass.name)
    }
}
