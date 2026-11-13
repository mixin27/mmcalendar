package dev.mixin27.mmcalendar.watch

import android.app.PendingIntent
import android.content.Intent
import android.graphics.drawable.Icon
import androidx.wear.watchface.complications.data.ComplicationData
import androidx.wear.watchface.complications.data.ComplicationType
import androidx.wear.watchface.complications.data.LongTextComplicationData
import androidx.wear.watchface.complications.data.MonochromaticImage
import androidx.wear.watchface.complications.data.NoDataComplicationData
import androidx.wear.watchface.complications.data.PlainComplicationText
import androidx.wear.watchface.complications.data.RangedValueComplicationData
import androidx.wear.watchface.complications.data.ShortTextComplicationData
import androidx.wear.watchface.complications.datasource.ComplicationDataTimeline
import androidx.wear.watchface.complications.datasource.ComplicationRequest
import androidx.wear.watchface.complications.datasource.SuspendingTimelineComplicationDataSourceService
import androidx.wear.watchface.complications.datasource.TimeInterval
import androidx.wear.watchface.complications.datasource.TimelineEntry
import dev.mixin27.mmcalendar.MainActivity
import java.time.LocalDate
import java.time.ZoneId

/**
 * The day for watch faces:
 * - SHORT_TEXT: the moon and the day of the fortnight;
 * - LONG_TEXT: the Myanmar date, titled with the weekday or the holiday;
 * - RANGED_VALUE: how much of the moon is lit.
 *
 * Each answer is a timeline of the next week, one entry per day starting at
 * midnight, so the slot turns over by itself.
 */
class MoonComplicationService : SuspendingTimelineComplicationDataSourceService() {
    override suspend fun onComplicationRequest(request: ComplicationRequest): ComplicationDataTimeline? {
        val payload = WatchPayload.read(this)
        val today = LocalDate.now()
        val zone = ZoneId.systemDefault()
        val todayData =
            payload?.day(today)?.let { build(request.complicationType, payload, it) }
                ?: return ComplicationDataTimeline(NoDataComplicationData(), emptyList())
        val entries =
            (1L..6L).mapNotNull { offset ->
                val date = today.plusDays(offset)
                val day = payload.day(date) ?: return@mapNotNull null
                TimelineEntry(
                    TimeInterval(
                        date.atStartOfDay(zone).toInstant(),
                        date.plusDays(1).atStartOfDay(zone).toInstant(),
                    ),
                    build(request.complicationType, payload, day) ?: return@mapNotNull null,
                )
            }
        return ComplicationDataTimeline(todayData, entries)
    }

    override fun getPreviewData(type: ComplicationType): ComplicationData? {
        val payload = WatchPayload.read(this)
        val day = payload?.day(LocalDate.now())
        if (payload != null && day != null) return build(type, payload, day)
        // Before the app has run: a waxing moon on day 5, half lit.
        val sample = plain("5")
        val image = moonImage(0)
        return when (type) {
            ComplicationType.SHORT_TEXT ->
                ShortTextComplicationData.Builder(sample, sample).setMonochromaticImage(image).build()
            ComplicationType.LONG_TEXT ->
                LongTextComplicationData.Builder(plain("Tazaungmon Waxing 5"), sample)
                    .setMonochromaticImage(image)
                    .build()
            ComplicationType.RANGED_VALUE ->
                RangedValueComplicationData.Builder(0.3f, 0f, 1f, sample)
                    .setText(sample)
                    .setMonochromaticImage(image)
                    .build()
            else -> null
        }
    }

    private fun build(type: ComplicationType, payload: WatchPayload, day: WatchPayload.Day): ComplicationData? {
        val phase = payload.s.moonPhases[day.ph]
        val image = moonImage(day.ph)
        val description = plain("${payload.s.weekdays[day.wd]}, ${day.my}")
        val tap = openApp()
        return when (type) {
            ComplicationType.SHORT_TEXT ->
                ShortTextComplicationData.Builder(plain(day.ln), description)
                    .setMonochromaticImage(image)
                    .setTapAction(tap)
                    .build()
            ComplicationType.LONG_TEXT ->
                LongTextComplicationData.Builder(plain(day.my), description)
                    .setTitle(plain(day.hol.firstOrNull() ?: payload.s.weekdays[day.wd]))
                    .setMonochromaticImage(image)
                    .setTapAction(tap)
                    .build()
            ComplicationType.RANGED_VALUE ->
                RangedValueComplicationData.Builder(
                    day.il.toFloat().coerceIn(0f, 1f),
                    0f,
                    1f,
                    plain("$phase, ${(day.il * 100).toInt()}%"),
                )
                    .setText(plain(day.ln))
                    .setMonochromaticImage(image)
                    .setTapAction(tap)
                    .build()
            else -> null
        }
    }

    private fun moonImage(phase: Int) =
        MonochromaticImage.Builder(Icon.createWithResource(this, MoonIcons.forPhase(phase))).build()

    private fun openApp(): PendingIntent =
        PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_IMMUTABLE,
        )

    private fun plain(text: String) = PlainComplicationText.Builder(text).build()
}
