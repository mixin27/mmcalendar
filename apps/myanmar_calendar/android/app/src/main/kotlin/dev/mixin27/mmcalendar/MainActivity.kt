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
        "default" to "dev.mixin27.mmcalendar.MainActivityDefault",
        "moon" to "dev.mixin27.mmcalendar.MainActivityMoon",
        "forest" to "dev.mixin27.mmcalendar.MainActivityForest",
        "minimal_flat" to "dev.mixin27.mmcalendar.MainActivityMinimalFlat",
        "premium_dark" to "dev.mixin27.mmcalendar.MainActivityPremiumDark",
        "traditional_myanmar" to "dev.mixin27.mmcalendar.MainActivityTraditionalMyanmar",
    )
    private val manifestEnabledAliasDefaults = mapOf(
        "default" to true,
        "moon" to false,
        "forest" to false,
        "minimal_flat" to false,
        "premium_dark" to false,
        "traditional_myanmar" to false,
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Recover state if MainActivity was disabled by older builds.
        ensureMainActivityEnabled()

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
            ensureMainActivityEnabled()
            val targetId = if (launcherAliases.containsKey(iconId)) iconId else "default"
            val targetAlias = launcherAliases.getValue(targetId)

            launcherAliases.forEach { (id, aliasClass) ->
                val componentName = ComponentName(this, aliasClass)
                val shouldEnable = aliasClass == targetAlias
                if (isAliasEnabled(packageManager, componentName, id) != shouldEnable) {
                    packageManager.setComponentEnabledSetting(
                        componentName,
                        if (shouldEnable) {
                            PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                        } else {
                            PackageManager.COMPONENT_ENABLED_STATE_DISABLED
                        },
                        PackageManager.DONT_KILL_APP
                    )
                }
            }

            // Verify the icon switch result using effective alias state.
            getCurrentIconId() == targetId
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to switch app icon", e)
            false
        }
    }

    private fun ensureMainActivityEnabled() {
        val packageManager = packageManager
        val mainActivityComponent = ComponentName(this, MainActivity::class.java)
        val currentState = packageManager.getComponentEnabledSetting(mainActivityComponent)
        if (currentState == PackageManager.COMPONENT_ENABLED_STATE_DISABLED ||
            currentState == PackageManager.COMPONENT_ENABLED_STATE_DISABLED_USER ||
            currentState == PackageManager.COMPONENT_ENABLED_STATE_DISABLED_UNTIL_USED
        ) {
            packageManager.setComponentEnabledSetting(
                mainActivityComponent,
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP
            )
        }
    }

    private fun getCurrentIconId(): String {
        return try {
            val packageManager = packageManager
            launcherAliases.entries.firstOrNull { (id, aliasClass) ->
                isAliasEnabled(packageManager, ComponentName(this, aliasClass), id)
            }?.key ?: "default"
        } catch (_: Exception) {
            "default"
        }
    }

    private fun isAliasEnabled(
        packageManager: PackageManager,
        componentName: ComponentName,
        aliasId: String,
    ): Boolean {
        return when (packageManager.getComponentEnabledSetting(componentName)) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED_USER,
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED_UNTIL_USED -> false
            PackageManager.COMPONENT_ENABLED_STATE_DEFAULT ->
                manifestEnabledAliasDefaults[aliasId] ?: false
            else -> false
        }
    }
}
