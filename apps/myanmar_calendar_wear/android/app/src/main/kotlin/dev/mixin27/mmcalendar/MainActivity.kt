package dev.mixin27.mmcalendar

import android.os.Bundle
import androidx.wear.ambient.AmbientLifecycleObserver
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var ambientChannel: MethodChannel? = null

    /** Tells Dart (AmbientModeListener) when the watch dims and wakes. */
    private val ambientObserver =
        AmbientLifecycleObserver(
            this,
            object : AmbientLifecycleObserver.AmbientLifecycleCallback {
                override fun onEnterAmbient(
                    ambientDetails: AmbientLifecycleObserver.AmbientDetails,
                ) {
                    ambientChannel?.invokeMethod("onEnterAmbient", null)
                }

                override fun onUpdateAmbient() {
                    ambientChannel?.invokeMethod("onUpdateAmbient", null)
                }

                override fun onExitAmbient() {
                    ambientChannel?.invokeMethod("onExitAmbient", null)
                }
            },
        )

    /** Makes the app assume the rounded canvas appearance on rounded screens. */
    override fun onCreate(savedInstanceState: Bundle?) {
        intent.putExtra("background_mode", "transparent")
        super.onCreate(savedInstanceState)
        lifecycle.addObserver(ambientObserver)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        ambientChannel = MethodChannel(messenger, "ambient_mode")
        // Round or square, for the layout's insets (Dart: WatchShape).
        MethodChannel(messenger, "watch_shape").setMethodCallHandler { call, result ->
            when (call.method) {
                "isRound" -> result.success(resources.configuration.isScreenRound)
                else -> result.notImplemented()
            }
        }
    }
}
