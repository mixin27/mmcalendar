package dev.mixin27.mmcalendar.widgets

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.util.LruCache
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sin

/**
 * White masks the widgets tint with their palette (`ColorFilter.tint`), so
 * one bitmap serves light and dark. Same drawings as the iOS widgets.
 */
object WidgetShapes {
    private val cache = object : LruCache<String, Bitmap>(4 * 1024 * 1024) {
        override fun sizeOf(key: String, value: Bitmap) = value.byteCount
    }

    private fun cached(key: String, px: Int, draw: (Canvas, Float) -> Unit): Bitmap {
        cache.get("$key@$px")?.let { return it }
        val bitmap = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
        draw(Canvas(bitmap), px.toFloat())
        cache.put("$key@$px", bitmap)
        return bitmap
    }

    private fun fill() = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = android.graphics.Color.WHITE }
    private fun stroke(width: Float) = fill().apply {
        style = Paint.Style.STROKE
        strokeWidth = width
        strokeCap = Paint.Cap.ROUND
        strokeJoin = Paint.Join.ROUND
    }

    private fun faint(paint: Paint) = paint.apply { alpha = 46 }

    fun disc(px: Int) = cached("disc", px) { c, s -> c.drawOval(RectF(0f, 0f, s, s), fill()) }

    /**
     * The lit part of the moon: a half disc plus a terminator ellipse of
     * half-width r·|1 − 2k|, tilted 40° the way the moon lies near 20°N.
     */
    fun moonLit(px: Int, illumination: Double, waxing: Boolean): Bitmap {
        val k = illumination.coerceIn(0.0, 1.0)
        val step = (k * 50).roundToInt()
        return cached("moon-$step-$waxing", px) { c, s ->
            val r = s / 2
            val kk = step / 50.0
            if (kk < 0.015) return@cached
            if (kk > 0.985) {
                c.drawOval(RectF(0f, 0f, s, s), fill()); return@cached
            }
            val terminator = r * abs(1 - 2 * kk)
            val bulge = if (kk < 0.5) 1.0 else -1.0
            val steps = 48
            val path = Path()
            val tilt = Math.toRadians(40.0)
            fun add(x: Double, y: Double, first: Boolean) {
                val fx = if (waxing) x else -x
                val rx = fx * cos(tilt) - y * sin(tilt) + r
                val ry = fx * sin(tilt) + y * cos(tilt) + r
                if (first) path.moveTo(rx.toFloat(), ry.toFloat()) else path.lineTo(rx.toFloat(), ry.toFloat())
            }
            for (i in 0..steps) {
                val a = -Math.PI / 2 + Math.PI * i / steps
                add(r * cos(a), r * sin(a), i == 0)
            }
            for (i in 1 until steps) {
                val a = Math.PI / 2 - Math.PI * i / steps
                add(bulge * terminator * cos(a), r * sin(a), false)
            }
            path.close()
            c.drawPath(path, fill())
        }
    }

    /** A ring and its progress arc, for the Myanmar year widget. */
    fun ring(px: Int, progress: Float, widthFraction: Float = 0.1f): Bitmap {
        val step = (progress * 100).roundToInt()
        return cached("ring-$step", px) { c, s ->
            val w = s * widthFraction
            val rect = RectF(w / 2, w / 2, s - w / 2, s - w / 2)
            if (step >= 100) c.drawOval(rect, stroke(w))
            else if (step > 0) c.drawArc(rect, -90f, 360f * step / 100f, false, stroke(w))
        }
    }

    fun track(px: Int, widthFraction: Float = 0.1f) = cached("track", px) { c, s ->
        val w = s * widthFraction
        c.drawOval(RectF(w / 2, w / 2, s - w / 2, s - w / 2), stroke(w).apply { strokeCap = Paint.Cap.BUTT })
    }

    /**
     * The style's motif, drawn faint (the tint's own alpha is dropped on
     * some launchers at night); null for Follow app and Plain.
     */
    fun motif(style: WidgetStyleId, px: Int): Bitmap? = when (style) {
        WidgetStyleId.Pagoda -> cached("stupa", px) { c, s -> c.drawPath(stupa(s), faint(stroke(s * 0.035f))) }
        WidgetStyleId.Jade -> cached("seal", px) { c, s -> c.drawPath(seal(s), faint(stroke(s * 0.035f))) }
        WidgetStyleId.DeepField -> cached("stars", px) { c, s ->
            val paint = faint(fill())
            for ((x, y, r) in stars) c.drawCircle(s * x / 100, s * y / 100, r * s / 100, paint)
        }
        else -> null
    }

    private val stars = listOf(
        Triple(20f, 22f, 3f), Triple(48f, 12f, 2f), Triple(78f, 24f, 3.5f), Triple(30f, 48f, 2f),
        Triple(62f, 44f, 2.5f), Triple(86f, 56f, 2f), Triple(16f, 74f, 2.5f), Triple(46f, 78f, 3.5f),
        Triple(74f, 84f, 2f),
    )

    private fun stupa(s: Float): Path {
        fun x(v: Float) = s * v / 100
        return Path().apply {
            moveTo(x(50f), x(6f)); lineTo(x(50f), x(16f))
            quadTo(x(45f), x(26f), x(44f), x(34f))
            lineTo(x(56f), x(34f))
            quadTo(x(55f), x(26f), x(50f), x(16f))
            moveTo(x(36f), x(42f)); quadTo(x(50f), x(28f), x(64f), x(42f))
            addRect(x(30f), x(42f), x(70f), x(48f), Path.Direction.CW)
            moveTo(x(34f), x(48f)); cubicTo(x(34f), x(70f), x(66f), x(70f), x(66f), x(48f))
            for ((y, inset) in listOf(70f to 24f, 78f to 20f, 86f to 16f)) {
                moveTo(x(inset), x(y)); lineTo(x(100 - inset), x(y))
            }
        }
    }

    private fun seal(s: Float): Path {
        val outer = RectF(s * 0.14f, s * 0.14f, s * 0.86f, s * 0.86f)
        val inner = RectF(outer.left + s * 0.08f, outer.top + s * 0.08f, outer.right - s * 0.08f, outer.bottom - s * 0.08f)
        return Path().apply {
            addRoundRect(outer, s * 0.06f, s * 0.06f, Path.Direction.CW)
            addRect(inner, Path.Direction.CW)
            for (f in listOf(0.28f, 0.5f, 0.72f)) {
                val y = inner.top + inner.height() * f
                moveTo(inner.left + inner.width() * 0.18f, y); lineTo(inner.right - inner.width() * 0.18f, y)
            }
            moveTo(inner.centerX(), inner.top + inner.height() * 0.18f)
            lineTo(inner.centerX(), inner.bottom - inner.height() * 0.18f)
        }
    }

    fun px(dp: Float, density: Float) = min(512, (dp * density).roundToInt().coerceAtLeast(8))
}
