import Flutter
import UIKit
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let appIconChannelName = "dev.mixin27.mmcalendar/app_icon"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    let didFinish = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    configureAppIconChannel()
    return didFinish
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    // This is required to make any communication available in the action isolate.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
        GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
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

  private func configureAppIconChannel() {
    guard let registrar = self.registrar(forPlugin: "AppIconMethodChannel") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: appIconChannelName,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(false)
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
          result(false)
          return
        }
        guard
          let arguments = call.arguments as? [String: Any],
          let iconId = arguments["iconId"] as? String
        else {
          result(false)
          return
        }
        self.setAppIcon(iconId: iconId, result: result)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  @available(iOS 10.3, *)
  private func setAppIcon(iconId: String, result: @escaping FlutterResult) {
    guard UIApplication.shared.supportsAlternateIcons else {
      result(false)
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
    default:
      result(false)
      return
    }

    UIApplication.shared.setAlternateIconName(alternateIconName) { error in
      if let error = error {
        NSLog("Failed to switch app icon: \(error.localizedDescription)")
        result(false)
      } else {
        result(true)
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
    default:
      return "default"
    }
  }
}
