package dev.mixin27.mmcalendar.watch

import android.content.ComponentName
import android.content.Context
import androidx.wear.tiles.TileService
import androidx.wear.watchface.complications.datasource.ComplicationDataSourceUpdateRequester

/** Asks the system to redraw the Tile and every complication slot using ours. */
object WatchRefresh {
    fun requestAll(context: Context) {
        TileService.getUpdater(context).requestUpdate(CalendarTileService::class.java)
        ComplicationDataSourceUpdateRequester
            .create(context, ComponentName(context, MoonComplicationService::class.java))
            .requestUpdateAll()
    }
}
