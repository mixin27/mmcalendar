import Flutter
import UIKit
import flutter_local_notifications
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let appIconChannelName = "dev.mixin27.mmcalendar/app_icon"
  private let widgetPeriodicTaskIdentifier = "dev.mixin27.mmcalendar.periodic_task"
  private var appIconChannel: FlutterMethodChannel?
  @available(iOS 10.3, *)
  private var isSettingAppIcon = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: widgetPeriodicTaskIdentifier,
      earliestBeginInSeconds: NSNumber(value: 24 * 60 * 60)
    )
    WorkmanagerPlugin.registerLaunchHandlers()
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // This is required to make any communication available in the action isolate.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
        GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    configureAppIconChannel(
      messenger: engineBridge.applicationRegistrar.messenger()
    )
  }

  /// Called when user taps "Configure in App" button in notification's context menu
  /// This delegate method is only called if the app has requested and been granted
  /// providesAppNotificationSettings permission.
  /// @see https://developer.apple.com/documentation/usernotifications/unnotificationsettings/providesappnotificationsettings
  @available(iOS 12.0, *)
  override func userNotificationCenter(
      _ center: UNUserNotificationCenter,
      openSettingsFor notification: UNNotification?
  ) {
      let controller = window?.rootViewController as! FlutterViewController
      let channel = FlutterMethodChannel(
          name: "dev.mixin27.mmcalendar/settings",
          binaryMessenger: controller.binaryMessenger)

      channel.invokeMethod("showNotificationSettings", arguments: nil)
  }

  private func configureAppIconChannel(
    messenger: FlutterBinaryMessenger
  ) {
    let channel = FlutterMethodChannel(
      name: appIconChannelName,
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(
          code: "channel_unavailable",
          message: "The app icon channel is no longer available.",
          details: nil
        ))
        return
      }

      switch call.method {
      case "isSupported":
        if #available(iOS 10.3, *) {
          result(UIApplication.shared.supportsAlternateIcons)
        } else {
          result(false)
        }

      case "getCurrentIcon":
        if #available(iOS 10.3, *) {
          result(self.currentIconId())
        } else {
          result("default")
        }

      case "setAppIcon":
        guard #available(iOS 10.3, *) else {
          result(FlutterError(
            code: "unsupported",
            message: "Alternate app icons require iOS 10.3 or later.",
            details: nil
          ))
          return
        }
        guard
          let arguments = call.arguments as? [String: Any],
          let iconId = arguments["iconId"] as? String
        else {
          result(FlutterError(
            code: "invalid_argument",
            message: "A valid iconId is required.",
            details: nil
          ))
          return
        }
        self.setAppIcon(iconId: iconId, result: result)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
    appIconChannel = channel
  }

  @available(iOS 10.3, *)
  private func setAppIcon(iconId: String, result: @escaping FlutterResult) {
    guard UIApplication.shared.supportsAlternateIcons else {
      result(FlutterError(
        code: "unsupported",
        message: "This device does not support alternate app icons.",
        details: nil
      ))
      return
    }

    let alternateIconName: String?
    switch iconId {
    case "default":
      alternateIconName = nil
    case "moon":
      alternateIconName = "AppIconMoon"
    case "forest":
      alternateIconName = "AppIconForest"
    case "minimal_flat":
      alternateIconName = "AppIconMinimalFlat"
    case "premium_dark":
      alternateIconName = "AppIconPremiumDark"
    case "traditional_myanmar":
      alternateIconName = "AppIconTraditionalMyanmar"
    default:
      result(FlutterError(
        code: "invalid_icon",
        message: "The requested app icon is not configured.",
        details: iconId
      ))
      return
    }

    if UIApplication.shared.alternateIconName == alternateIconName {
      result(true)
      return
    }

    if isSettingAppIcon {
      result(FlutterError(
        code: "change_in_progress",
        message: "Another app icon change is already in progress.",
        details: nil
      ))
      return
    }

    DispatchQueue.main.async {
      guard UIApplication.shared.applicationState == .active else {
        result(FlutterError(
          code: "app_inactive",
          message: "Keep the app in the foreground while changing its icon.",
          details: nil
        ))
        return
      }

      self.isSettingAppIcon = true
      UIApplication.shared.setAlternateIconName(alternateIconName) { [weak self] error in
        // UIKit doesn't guarantee which queue invokes this completion handler.
        DispatchQueue.main.async {
          guard let self = self else {
            result(FlutterError(
              code: "channel_unavailable",
              message: "The app icon channel is no longer available.",
              details: nil
            ))
            return
          }

          self.isSettingAppIcon = false
          if let nsError = error as NSError? {
            NSLog(
              "Failed to switch app icon [domain=%@ code=%ld]: %@ userInfo=%@",
              nsError.domain,
              nsError.code,
              nsError.localizedDescription,
              nsError.userInfo.description
            )
            result(FlutterError(
              code: "native_change_failed",
              message: nsError.localizedDescription,
              details: ["domain": nsError.domain, "code": nsError.code]
            ))
            return
          }

          guard UIApplication.shared.alternateIconName == alternateIconName else {
            result(FlutterError(
              code: "change_not_applied",
              message: "iOS did not apply the selected app icon.",
              details: nil
            ))
            return
          }
          result(true)
        }
      }
    }
  }

  @available(iOS 10.3, *)
  private func currentIconId() -> String {
    switch UIApplication.shared.alternateIconName {
    case "AppIconMoon":
      return "moon"
    case "AppIconForest":
      return "forest"
    case "AppIconMinimalFlat":
      return "minimal_flat"
    case "AppIconPremiumDark":
      return "premium_dark"
    case "AppIconTraditionalMyanmar":
      return "traditional_myanmar"
    default:
      return "default"
    }
  }
}
