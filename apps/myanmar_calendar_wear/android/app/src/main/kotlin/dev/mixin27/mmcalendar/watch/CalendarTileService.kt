package dev.mixin27.mmcalendar.watch

import android.content.Context
import androidx.wear.protolayout.ActionBuilders
import androidx.wear.protolayout.ColorBuilders.argb
import androidx.wear.protolayout.DimensionBuilders.dp
import androidx.wear.protolayout.DimensionBuilders.expand
import androidx.wear.protolayout.DimensionBuilders.sp
import androidx.wear.protolayout.LayoutElementBuilders
import androidx.wear.protolayout.LayoutElementBuilders.Box
import androidx.wear.protolayout.LayoutElementBuilders.Column
import androidx.wear.protolayout.LayoutElementBuilders.FontStyle
import androidx.wear.protolayout.LayoutElementBuilders.Image
import androidx.wear.protolayout.LayoutElementBuilders.LayoutElement
import androidx.wear.protolayout.LayoutElementBuilders.Row
import androidx.wear.protolayout.LayoutElementBuilders.Spacer
import androidx.wear.protolayout.LayoutElementBuilders.Text
import androidx.wear.protolayout.ModifiersBuilders
import androidx.wear.protolayout.ResourceBuilders
import androidx.wear.protolayout.TimelineBuilders
import androidx.wear.tiles.RequestBuilders
import androidx.wear.tiles.TileBuilders
import androidx.wear.tiles.TileService
import com.google.common.util.concurrent.Futures
import com.google.common.util.concurrent.ListenableFuture
import dev.mixin27.mmcalendar.MainActivity
import dev.mixin27.mmcalendar.R
import java.time.LocalDate
import java.time.ZoneId

/**
 * Today's Myanmar date, the moon and the next holiday or Sabbath. The
 * timeline holds today and tomorrow, so the Tile turns over at midnight by
 * itself; it also asks to be fetched again then.
 */
class CalendarTileService : TileService() {
    override fun onTileRequest(
        requestParams: RequestBuilders.TileRequest,
    ): ListenableFuture<TileBuilders.Tile> {
        val payload = WatchPayload.read(this)
        val today = LocalDate.now()
        val zone = ZoneId.systemDefault()
        val timeline = TimelineBuilders.Timeline.Builder()
        for (offset in 0L..1L) {
            val date = today.plusDays(offset)
            val start = date.atStartOfDay(zone).toInstant().toEpochMilli()
            val end = date.plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli()
            timeline.addTimelineEntry(
                TimelineBuilders.TimelineEntry.Builder()
                    .setValidity(
                        TimelineBuilders.TimeInterval.Builder()
                            .setStartMillis(if (offset == 0L) 0 else start)
                            .setEndMillis(end)
                            .build(),
                    )
                    .setLayout(
                        LayoutElementBuilders.Layout.Builder()
                            .setRoot(TileLayout.root(this, payload, date))
                            .build(),
                    )
                    .build(),
            )
        }
        return Futures.immediateFuture(
            TileBuilders.Tile.Builder()
                .setResourcesVersion(RESOURCES_VERSION)
                .setFreshnessIntervalMillis(
                    (MidnightRefresh.nextMidnight() - System.currentTimeMillis()).coerceAtLeast(60_000),
                )
                .setTileTimeline(timeline.build())
                .build(),
        )
    }

    override fun onTileResourcesRequest(
        requestParams: RequestBuilders.ResourcesRequest,
    ): ListenableFuture<ResourceBuilders.Resources> {
        val resources = ResourceBuilders.Resources.Builder().setVersion(RESOURCES_VERSION)
        MoonIcons.drawables.forEachIndexed { phase, drawable ->
            resources.addIdToImageMapping(
                TileLayout.moonId(phase),
                ResourceBuilders.ImageResource.Builder()
                    .setAndroidResourceByResId(
                        ResourceBuilders.AndroidImageResourceByResId.Builder()
                            .setResourceId(drawable)
                            .build(),
                    )
                    .build(),
            )
        }
        return Futures.immediateFuture(resources.build())
    }

    companion object {
        const val RESOURCES_VERSION = "1"
    }
}

/** The Tile's layout, kept apart from the service for previews and tests. */
object TileLayout {
    private const val GOLD = 0xFFF5C451.toInt()
    private const val WHITE = 0xFFFFFFFF.toInt()
    private const val GREY = 0xFFB0B7C3.toInt()
    private const val ORANGE = 0xFFFFB06B.toInt()
    private const val RED = 0xFFFF8A80.toInt()

    fun moonId(phase: Int) = "moon_$phase"

    fun root(context: Context, payload: WatchPayload?, date: LocalDate): LayoutElement {
        val day = payload?.day(date)
        val content =
            if (payload == null || day == null) {
                Column.Builder()
                    .setHorizontalAlignment(LayoutElementBuilders.HORIZONTAL_ALIGN_CENTER)
                    .addContent(text(context.getString(R.string.tile_title), 16f, GOLD, bold = true))
                    .addContent(spacer(6f))
                    .addContent(text(context.getString(R.string.tile_open_app), 12f, GREY, maxLines = 3))
                    .build()
            } else {
                dayColumn(payload, day, date)
            }
        return Box.Builder()
            .setWidth(expand())
            .setHeight(expand())
            .setHorizontalAlignment(LayoutElementBuilders.HORIZONTAL_ALIGN_CENTER)
            .setVerticalAlignment(LayoutElementBuilders.VERTICAL_ALIGN_CENTER)
            .setModifiers(
                ModifiersBuilders.Modifiers.Builder()
                    .setClickable(
                        ModifiersBuilders.Clickable.Builder()
                            .setId("open_app")
                            .setOnClick(
                                ActionBuilders.LaunchAction.Builder()
                                    .setAndroidActivity(
                                        ActionBuilders.AndroidActivity.Builder()
                                            .setPackageName(context.packageName)
                                            .setClassName(MainActivity::class.java.name)
                                            .build(),
                                    )
                                    .build(),
                            )
                            .build(),
                    )
                    .build(),
            )
            .addContent(content)
            .build()
    }

    private fun dayColumn(payload: WatchPayload, day: WatchPayload.Day, date: LocalDate): LayoutElement {
        val column =
            Column.Builder()
                .setWidth(dp(176f))
                .setHorizontalAlignment(LayoutElementBuilders.HORIZONTAL_ALIGN_CENTER)
                .addContent(text(payload.shortWestern(day), 12f, GREY))
                .addContent(spacer(4f))
                .addContent(text(day.my, 17f, WHITE, bold = true, maxLines = 2))
                .addContent(spacer(6f))
                .addContent(
                    Row.Builder()
                        .setVerticalAlignment(LayoutElementBuilders.VERTICAL_ALIGN_CENTER)
                        .addContent(
                            Image.Builder()
                                .setResourceId(moonId(day.ph))
                                .setWidth(dp(18f))
                                .setHeight(dp(18f))
                                .build(),
                        )
                        .addContent(Spacer.Builder().setWidth(dp(6f)).build())
                        .addContent(text("${payload.s.moonPhases[day.ph]} ${day.ln}", 13f, GOLD))
                        .build(),
                )
        // A holiday today comes first; otherwise the next holiday or Sabbath.
        val holiday = day.hol.firstOrNull()
        val next = payload.nextHolidayOrSabbath(date)
        val line =
            when {
                holiday != null -> holiday to RED
                next != null -> "${payload.relative(date, next.date)} · ${next.name}" to
                    (if (next.kind == "holiday") RED else ORANGE)
                else -> null
            }
        if (line != null) {
            column.addContent(spacer(8f)).addContent(text(line.first, 12f, line.second, maxLines = 2))
        }
        return column.build()
    }

    private fun spacer(height: Float): LayoutElement = Spacer.Builder().setHeight(dp(height)).build()

    private fun text(
        value: String,
        size: Float,
        color: Int,
        bold: Boolean = false,
        maxLines: Int = 1,
    ): LayoutElement =
        Text.Builder()
            .setText(value)
            .setMaxLines(maxLines)
            .setMultilineAlignment(LayoutElementBuilders.TEXT_ALIGN_CENTER)
            .setOverflow(LayoutElementBuilders.TEXT_OVERFLOW_ELLIPSIZE)
            .setFontStyle(
                FontStyle.Builder()
                    .setSize(sp(size))
                    .setColor(argb(color))
                    .setWeight(
                        if (bold) LayoutElementBuilders.FONT_WEIGHT_BOLD else LayoutElementBuilders.FONT_WEIGHT_NORMAL,
                    )
                    .build(),
            )
            .build()
}

/** One monochrome moon per payload phase: waxing, full, waning, new. */
object MoonIcons {
    val drawables =
        listOf(
            R.drawable.moon_waxing,
            R.drawable.moon_full,
            R.drawable.moon_waning,
            R.drawable.moon_new,
        )

    fun forPhase(phase: Int) = drawables[phase.coerceIn(0, 3)]
}
