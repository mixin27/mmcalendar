import Flutter
import UIKit
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let appIconChannelName = "dev.mixin27.mmcalendar/app_icon"
  private let iconChangeMaxRetryAttempts = 3
  private let iconChangeRetryDelay: TimeInterval = 2.0
  @available(iOS 10.3, *)
  private var isSettingAppIcon = false

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
          result(UIApplication.shared.supportsAlternateIcons && !isRunningOnSimulator())
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
    guard UIApplication.shared.supportsAlternateIcons && !isRunningOnSimulator() else {
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
    case "minimal_flat":
      alternateIconName = "AppIconMinimalFlat"
    case "premium_dark":
      alternateIconName = "AppIconPremiumDark"
    case "traditional_myanmar":
      alternateIconName = "AppIconTraditionalMyanmar"
    default:
      result(false)
      return
    }

    if UIApplication.shared.alternateIconName == alternateIconName {
      result(true)
      return
    }

    if isSettingAppIcon {
      // Avoid overlapping requests (LSIconAlertManager token contention).
      result(false)
      return
    }

    isSettingAppIcon = true
    performSetAppIcon(
      alternateIconName: alternateIconName,
      retryCount: 0,
      result: result
    )
  }

  @available(iOS 10.3, *)
  private func isReadyForIconChange() -> Bool {
    guard UIApplication.shared.applicationState == .active else {
      return false
    }

    let foregroundScene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
    guard let scene = foregroundScene else {
      return false
    }

    let keyWindow = scene.windows.first { $0.isKeyWindow } ?? scene.windows.first
    guard let window = keyWindow else {
      return false
    }

    // Any presented controller can interfere with LSIconAlertManager token.
    return window.rootViewController?.presentedViewController == nil
  }

  private func isRunningOnSimulator() -> Bool {
#if targetEnvironment(simulator)
    return true
#else
    return false
#endif
  }

  @available(iOS 10.3, *)
  private func performSetAppIcon(
    alternateIconName: String?,
    retryCount: Int,
    result: @escaping FlutterResult
  ) {
    if UIApplication.shared.alternateIconName == alternateIconName {
      isSettingAppIcon = false
      result(true)
      return
    }

    if !isReadyForIconChange() {
      if retryCount < iconChangeMaxRetryAttempts {
        DispatchQueue.main.asyncAfter(deadline: .now() + iconChangeRetryDelay) { [weak self] in
          self?.performSetAppIcon(
            alternateIconName: alternateIconName,
            retryCount: retryCount + 1,
            result: result
          )
        }
      } else {
        isSettingAppIcon = false
        result(false)
      }
      return
    }

    DispatchQueue.main.async {
      UIApplication.shared.setAlternateIconName(alternateIconName) { [weak self] error in
        guard let self = self else {
          result(false)
          return
        }

        if let nsError = error as NSError? {
          // Some iOS versions return transient code 35 even if icon eventually changed.
          if UIApplication.shared.alternateIconName == alternateIconName {
            self.isSettingAppIcon = false
            result(true)
            return
          }

          if
            nsError.domain == NSPOSIXErrorDomain,
            nsError.code == 35,
            retryCount < self.iconChangeMaxRetryAttempts
          {
            DispatchQueue.main.asyncAfter(deadline: .now() + self.iconChangeRetryDelay) { [weak self] in
              self?.performSetAppIcon(
                alternateIconName: alternateIconName,
                retryCount: retryCount + 1,
                result: result
              )
            }
            return
          }

          NSLog(
            "Failed to switch app icon [domain=%@ code=%ld]: %@ userInfo=%@",
            nsError.domain,
            nsError.code,
            nsError.localizedDescription,
            nsError.userInfo.description
          )
          self.isSettingAppIcon = false
          result(false)
          return
        }

        self.isSettingAppIcon = false
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
