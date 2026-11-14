package dev.mixin27.mmcalendar.widgets

import android.content.Context
import android.content.SharedPreferences
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.action.ActionCallback
import dev.mixin27.mmcalendar.WidgetUpdateBroadcaster
import org.json.JSONArray
import org.json.JSONObject

/**
 * Ticking an event done on a widget.
 *
 * The widgets can't reach the app's events database, so a tick does two
 * things in home_widget's preferences: it flips the event in the saved
 * payload, so the widget redraws at once, and it adds the tick to a queue
 * the app applies when it next starts or comes back (WidgetActions in
 * packages/features/home_widgets). iOS does the same in WidgetTicks.swift.
 */
object WidgetTicks {
    /** home_widget's preferences, where the payload lives. */
    const val PREFERENCES = "HomeWidgetPreferences"

    /** Matches `WidgetActions.key` on the Dart side. */
    const val QUEUE_KEY = "widget_actions_v1"

    /**
     * [raw] payload JSON with the occurrence of event [id] on [day] set to
     * [done]; null when the payload can't be read.
     */
    fun applying(raw: String, id: Int, day: String, done: Boolean): String? = runCatching {
        val payload = JSONObject(raw)
        val events = payload.getJSONArray("events")
        for (i in 0 until events.length()) {
            val e = events.getJSONObject(i)
            if (!e.isNull("id") && e.getInt("id") == id && e.optString("d") == day) {
                e.put("done", done)
            }
        }
        payload.toString()
    }.getOrNull()

    /** The queue [raw] with this tick added at the end. */
    fun enqueue(raw: String?, id: Int, day: String, recurring: Boolean, done: Boolean): String {
        val queue = raw?.let { runCatching { JSONArray(it) }.getOrNull() } ?: JSONArray()
        queue.put(JSONObject().put("id", id).put("d", day).put("rec", recurring).put("done", done))
        return queue.toString()
    }

    /** Records a tick in [prefs]' payload and queue. */
    @Synchronized
    fun toggle(prefs: SharedPreferences, id: Int, day: String, recurring: Boolean, done: Boolean) {
        val editor = prefs.edit()
        prefs.getString(WidgetPayload.KEY, null)
            ?.let { applying(it, id, day, done) }
            ?.let { editor.putString(WidgetPayload.KEY, it) }
        editor.putString(QUEUE_KEY, enqueue(prefs.getString(QUEUE_KEY, null), id, day, recurring, done))
        editor.commit()
    }
}

/** The tick circle on an event row: toggles that day's occurrence. */
class ToggleEventAction : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        val id = parameters[eventId] ?: return
        val day = parameters[day] ?: return
        WidgetTicks.toggle(
            context.getSharedPreferences(WidgetTicks.PREFERENCES, Context.MODE_PRIVATE),
            id = id,
            day = day,
            recurring = parameters[recurring] ?: false,
            done = parameters[done] ?: true,
        )
        // The Agenda and Today widgets can both show the event.
        WidgetUpdateBroadcaster.updateAllWidgets(context, "event ticked")
    }

    companion object {
        val eventId = ActionParameters.Key<Int>("eventId")
        val day = ActionParameters.Key<String>("day")
        val recurring = ActionParameters.Key<Boolean>("recurring")
        val done = ActionParameters.Key<Boolean>("done")
    }
}
