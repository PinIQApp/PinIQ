import Flutter
import HealthKit
import UIKit

final class PrivacyShieldStreamHandler: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private var captureObserver: NSObjectProtocol?
  private var screenshotObserver: NSObjectProtocol?

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events

    captureObserver = NotificationCenter.default.addObserver(
      forName: UIScreen.capturedDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.eventSink?([
        "type": "screen_capture_changed",
        "active": UIScreen.main.isCaptured,
      ])
    }

    screenshotObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.userDidTakeScreenshotNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.eventSink?([
        "type": "screenshot_detected",
      ])
    }

    events([
      "type": "screen_capture_changed",
      "active": UIScreen.main.isCaptured,
    ])
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    if let captureObserver {
      NotificationCenter.default.removeObserver(captureObserver)
    }
    if let screenshotObserver {
      NotificationCenter.default.removeObserver(screenshotObserver)
    }
    eventSink = nil
    captureObserver = nil
    screenshotObserver = nil
    return nil
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let privacyShieldHandler = PrivacyShieldStreamHandler()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "wrestletech/watch_companion",
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "requestHealthPermissions":
          HealthKitManager.shared.requestPermissions { success in
            DispatchQueue.main.async {
              result(success)
            }
          }
        case "fetchHealthSnapshot":
          HealthKitManager.shared.fetchSnapshot { payload in
            DispatchQueue.main.async {
              result(payload)
            }
          }
        case "syncWatchSnapshot":
          let payload = (call.arguments as? [String: Any]) ?? [:]
          let success = WatchConnectivityManager.shared.syncSnapshot(payload)
          result(success)
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      let privacyMethodChannel = FlutterMethodChannel(
        name: "wrestletech/privacy_shield",
        binaryMessenger: controller.binaryMessenger
      )
      privacyMethodChannel.setMethodCallHandler { call, result in
        switch call.method {
        case "isScreenCaptureActive":
          result(UIScreen.main.isCaptured)
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      let privacyEventChannel = FlutterEventChannel(
        name: "wrestletech/privacy_shield_events",
        binaryMessenger: controller.binaryMessenger
      )
      privacyEventChannel.setStreamHandler(privacyShieldHandler)
    }

    WatchConnectivityManager.shared.activateIfAvailable()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
