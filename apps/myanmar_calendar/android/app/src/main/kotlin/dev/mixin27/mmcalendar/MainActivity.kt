package dev.mixin27.mmcalendar

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val INTENT_CHANNEL = "dev.mixin27.mmcalendar/intent"
    private val APP_ICON_CHANNEL = "dev.mixin27.mmcalendar/app_icon"
    private var intentExtras: Map<String, Any>? = null
    private val launcherAliases = mapOf(
        "default" to "dev.mixin27.mmcalendar.MainActivity",
        "moon" to "dev.mixin27.mmcalendar.MainActivityMoon",
        "forest" to "dev.mixin27.mmcalendar.MainActivityForest",
        "minimal_flat" to "dev.mixin27.mmcalendar.MainActivityMinimalFlat",
        "premium_dark" to "dev.mixin27.mmcalendar.MainActivityPremiumDark",
        "traditional_myanmar" to "dev.mixin27.mmcalendar.MainActivityTraditionalMyanmar",
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Capture intent extras when activity is created
        captureIntentExtras(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        // Capture intent extras when activity receives new intent
        captureIntentExtras(intent)

        // Notify Flutter about new intent
        flutterEngine?.let { engine ->
            MethodChannel(engine.dartExecutor.binaryMessenger, INTENT_CHANNEL)
                .invokeMethod("onNewIntent", intentExtras)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up method channel to communicate intent extras to Flutter
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            INTENT_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getIntentExtras" -> {
                    result.success(intentExtras)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            APP_ICON_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> result.success(true)
                "getCurrentIcon" -> result.success(getCurrentIconId())
                "setAppIcon" -> {
                    val iconId = call.argument<String>("iconId") ?: "default"
                    result.success(setLauncherIcon(iconId))
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Capture and parse intent extras
     */
    private fun captureIntentExtras(intent: Intent?) {
        if (intent == null) {
            intentExtras = null
            return
        }

        val extras = mutableMapOf<String, Any>()

        try {
            // Get all extras from intent
            intent.extras?.let { bundle ->
                // Widget-specific extras
                extras["opened_from_widget"] = bundle.getBoolean("opened_from_widget", false)

                if (bundle.containsKey("widget_id")) {
                    extras["widget_id"] = bundle.getInt("widget_id")
                }

                if (bundle.containsKey("timestamp")) {
                    extras["timestamp"] = bundle.getLong("timestamp")
                }

                if (bundle.containsKey("action")) {
                    extras["action"] = bundle.getString("action") ?: ""
                }

                // Add other extras if needed
                for (key in bundle.keySet()) {
                    if (!extras.containsKey(key)) {
                        bundle.get(key)?.let { value ->
                            when (value) {
                                is String -> extras[key] = value
                                is Int -> extras[key] = value
                                is Long -> extras[key] = value
                                is Boolean -> extras[key] = value
                                is Double -> extras[key] = value
                                is Float -> extras[key] = value.toDouble()
                                else -> extras[key] = value.toString()
                            }
                        }
                    }
                }
            }

            intentExtras = extras
            android.util.Log.d("MainActivity", "Captured intent extras: $intentExtras")

        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error capturing intent extras", e)
            intentExtras = null
        }
    }

    private fun setLauncherIcon(iconId: String): Boolean {
        return try {
            val packageManager = packageManager
            val targetAlias = launcherAliases[iconId] ?: launcherAliases.getValue("default")

            launcherAliases.forEach { (id, aliasClass) ->
                val componentName = ComponentName(this, aliasClass)
                val desiredState = if (aliasClass == targetAlias) {
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                } else {
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                }

                val currentState = packageManager.getComponentEnabledSetting(componentName)
                val normalizedCurrentState = when (currentState) {
                    PackageManager.COMPONENT_ENABLED_STATE_DEFAULT ->
                        if (id == "default") PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                        else PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                    else -> currentState
                }

                if (normalizedCurrentState != desiredState) {
                    packageManager.setComponentEnabledSetting(
                        componentName,
                        desiredState,
                        PackageManager.DONT_KILL_APP
                    )
                }
            }
            true
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to switch app icon", e)
            false
        }
    }

    private fun getCurrentIconId(): String {
        return try {
            val packageManager = packageManager
            launcherAliases.entries.firstOrNull { (id, aliasClass) ->
                val state = packageManager.getComponentEnabledSetting(
                    ComponentName(this, aliasClass)
                )
                when (state) {
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
                    PackageManager.COMPONENT_ENABLED_STATE_DEFAULT -> id == "default"
                    else -> false
                }
            }?.key ?: "default"
        } catch (_: Exception) {
            "default"
        }
    }
}
