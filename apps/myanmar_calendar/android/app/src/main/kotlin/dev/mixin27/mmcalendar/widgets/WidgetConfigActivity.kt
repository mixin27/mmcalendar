package dev.mixin27.mmcalendar.widgets

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.TypedValue
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.ScrollView
import android.widget.TextView
import dev.mixin27.mmcalendar.R

/**
 * Edit widget: the style one widget wears and, for Countdown, what it
 * counts down to. Opens when a widget is added (where the launcher asks)
 * and from the widget's reconfigure action.
 */
class WidgetConfigActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    private val styles = listOf(
        WidgetSettings.STANDARD to R.string.widget_style_default,
        "app" to R.string.widget_style_app,
        "plain" to R.string.widget_style_plain,
        "pagoda" to R.string.widget_style_pagoda,
        "jade" to R.string.widget_style_jade,
        "deepField" to R.string.widget_style_deep_field,
    )

    private val targets = listOf(
        WidgetSettings.STANDARD to R.string.widget_style_default,
        "fullMoon" to R.string.widget_countdown_full_moon,
        "newMoon" to R.string.widget_countdown_new_moon,
        "sabbath" to R.string.widget_countdown_sabbath,
        "thingyan" to R.string.widget_countdown_thingyan,
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        appWidgetId = intent?.extras?.getInt(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
            ?: AppWidgetManager.INVALID_APPWIDGET_ID
        // Backing out of a first-time configure keeps the widget with defaults.
        setResult(RESULT_OK, resultIntent())
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val prefs = getSharedPreferences(WidgetSettings.PREFERENCES, Context.MODE_PRIVATE)
        val provider = AppWidgetManager.getInstance(this).getAppWidgetInfo(appWidgetId)?.provider
        val isCountdown = provider?.className == CountdownWidgetReceiver::class.java.name

        setTitle(R.string.widget_config_title)
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(20), dp(8), dp(20), dp(12))
        }
        val styleGroup = group(content, R.string.widget_config_style, styles, WidgetSettings.ownStyle(prefs, appWidgetId))
        val targetGroup = if (isCountdown) {
            group(content, R.string.widget_config_countdown, targets, WidgetSettings.ownCountdown(prefs, appWidgetId))
        } else null

        content.addView(
            Button(this, null, android.R.attr.buttonBarButtonStyle).apply {
                setText(android.R.string.ok)
                setOnClickListener {
                    WidgetSettings.save(
                        prefs, appWidgetId,
                        styles[styleGroup.checkedRadioButtonId - 1].first,
                        targetGroup?.let { targets[it.checkedRadioButtonId - 1].first },
                    )
                    provider?.let { redraw(it) }
                    finish()
                }
            },
            LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                gravity = android.view.Gravity.END
                topMargin = dp(8)
            },
        )
        setContentView(ScrollView(this).apply { addView(content) })
    }

    private fun group(parent: LinearLayout, title: Int, options: List<Pair<String, Int>>, selected: String): RadioGroup {
        parent.addView(TextView(this).apply {
            setText(title)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            setPadding(0, dp(12), 0, dp(4))
            alpha = 0.7f
        })
        val group = RadioGroup(this)
        options.forEachIndexed { index, (key, label) ->
            group.addView(RadioButton(this).apply {
                id = index + 1
                setText(label)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                minHeight = dp(44)
            })
            if (key == selected) group.check(index + 1)
        }
        if (group.checkedRadioButtonId == -1) group.check(1)
        parent.addView(group)
        return group
    }

    /** Asks the widget's receiver to redraw this one widget. */
    private fun redraw(provider: ComponentName) {
        sendBroadcast(Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
            component = provider
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
        })
    }

    private fun resultIntent() = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)

    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
}
