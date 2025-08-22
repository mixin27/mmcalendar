package dev.mixin27.calendar_home_widgets

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** CalendarHomeWidgetsPlugin */
class CalendarHomeWidgetsPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
//  private var appContext: Context? = null


  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "calendar_home_widgets")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when(call.method) {
      "updateMyanmarDateAndAstroInfo" -> {
//        val data = call.arguments as? Map<String, String>
//        if (data != null) {
//          updateMyanmarDateAndAstroInfo(data)
//          result.success(null)
//        } else {
//          result.error("INVALID_DATA", "Expected Map<String,String>", null)
//        }
        result.success(null)
      }
      "updateMoonPhase" -> {
//        val phase = call.argument<String>("phase") ?: "Unknown"
//        updateMoonPhaseWidget(phase)
//        result.success(null)
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
//    appContext = null
  }

//  private fun updateMyanmarDateAndAstroInfo(data: Map<String, String>) {
//    val context = appContext ?: return;
//    val views = RemoteViews(context.packageName, R.layout.plugin_date_info_widget)
//
//    val myanmarDate = data["date"];
//    views.setTextViewText(R.id.widget_title, "MyanmarCalendar")
//    views.setTextViewText(R.id.widget_myanmar_date, myanmarDate)
//
//    val sabbath = data["sabbath"] ?: "--";
//    val astrologicalDay = data["astrologicalDay"] ?: "--"
//    val nagapor = data["nagapor"] ?: "--"
//    val naga = data["naga"] ?: "--"
//    val mahabote = data["mahabote"] ?: "--"
//    val nakhat = data["nakhat"] ?: "--"
//    val yearname = data["yearname"] ?: "--"
//
//    if (sabbath == "--" || sabbath.isEmpty()) {
//      views.setViewVisibility(R.id.widget_sabbath, View.GONE)
//    }
//    views.setTextViewText(R.id.widget_sabbath, sabbath)
//
//    if (astrologicalDay == "--" || astrologicalDay.isEmpty()) {
//      views.setViewVisibility(R.id.widget_astrology_day, View.GONE)
//    }
//    views.setTextViewText(R.id.widget_astrology_day, astrologicalDay)
//
//    if (nagapor == "--" || nagapor.isEmpty()) {
//      views.setViewVisibility(R.id.widget_nagapor, View.GONE)
//    }
//    views.setTextViewText(R.id.widget_nagapor, nagapor)
//
//    if (naga == "--" || naga.isEmpty()) {
//      views.setViewVisibility(R.id.widget_naga, View.GONE)
//    }
//    views.setTextViewText(R.id.widget_naga, naga)
//
//    views.setTextViewText(R.id.widget_mahabote, mahabote)
//    views.setTextViewText(R.id.widget_nakhat, nakhat)
//    views.setTextViewText(R.id.widget_yearname, yearname)
//
//    val manager = AppWidgetManager.getInstance(context)
//    val widget = ComponentName(context, DateAndAstroInfoWidget::class.java)
//    manager.updateAppWidget(widget, views)
//  }
//
//  private fun updateMoonPhaseWidget(phase: String) {
//    val context = appContext ?: return;
//    val views = RemoteViews(context.packageName, R.layout.plugin_moon_phase_widget)
//    views.setTextViewText(R.id.moon_phase_text, phase)
//    val manager = AppWidgetManager.getInstance(context)
//    val widget = ComponentName(context, MoonPhaseWidget::class.java)
//    manager.updateAppWidget(widget, views)
//  }
}
