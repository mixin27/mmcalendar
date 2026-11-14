package dev.mixin27.mmcalendar.widgets

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class WidgetTicksTest {
    private val payload = JSONObject()
        .put("v", 2)
        .put(
            "events",
            JSONArray()
                .put(event(1, "2026-11-13"))
                .put(event(1, "2026-11-20"))
                .put(event(2, "2026-11-13"))
                .put(JSONObject().put("id", JSONObject.NULL).put("d", "2026-11-13").put("done", false)),
        )
        .toString()

    private fun event(id: Int, d: String) =
        JSONObject().put("id", id).put("d", d).put("ti", "Event $id").put("c", 0xFF2F5BEAL).put("done", false)

    private fun done(raw: String) = JSONObject(raw).getJSONArray("events").let { events ->
        (0 until events.length()).map { events.getJSONObject(it).getBoolean("done") }
    }

    @Test
    fun ticksOnlyThatDaysOccurrence() {
        val updated = WidgetTicks.applying(payload, id = 1, day = "2026-11-13", done = true)!!
        assertEquals(listOf(true, false, false, false), done(updated))
        // The colour survives as the same number.
        assertEquals(0xFF2F5BEAL, JSONObject(updated).getJSONArray("events").getJSONObject(0).getLong("c"))
    }

    @Test
    fun untickingWorksToo() {
        val ticked = WidgetTicks.applying(payload, 2, "2026-11-13", true)!!
        assertEquals(listOf(false, false, false, false), done(WidgetTicks.applying(ticked, 2, "2026-11-13", false)!!))
    }

    @Test
    fun anUnreadablePayloadIsLeftAlone() {
        assertNull(WidgetTicks.applying("not json", 1, "2026-11-13", true))
        assertNull(WidgetTicks.applying("{}", 1, "2026-11-13", true))
    }

    @Test
    fun ticksQueueInOrderForTheApp() {
        val first = WidgetTicks.enqueue(null, 1, "2026-11-13", recurring = true, done = true)
        val both = JSONArray(WidgetTicks.enqueue(first, 2, "2026-11-14", recurring = false, done = false))
        assertEquals(2, both.length())
        val a = both.getJSONObject(0)
        assertEquals(listOf(1, "2026-11-13", true, true), listOf(a.getInt("id"), a.getString("d"), a.getBoolean("rec"), a.getBoolean("done")))
        assertEquals(2, both.getJSONObject(1).getInt("id"))
    }

    @Test
    fun aBrokenQueueStartsAgain() {
        assertEquals(1, JSONArray(WidgetTicks.enqueue("oops", 3, "2026-11-13", false, true)).length())
    }
}
