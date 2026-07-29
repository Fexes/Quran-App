import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var qiblaHeadingChannel: FlutterEventChannel?
  private var qiblaHeadingHandler: QiblaHeadingStreamHandler?
  private var audioStorageChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "QiblaHeadingStream") else {
      return
    }
    let channel = FlutterEventChannel(
      name: "quran/qibla_heading",
      binaryMessenger: registrar.messenger()
    )
    let handler = QiblaHeadingStreamHandler()
    channel.setStreamHandler(handler)
    qiblaHeadingChannel = channel
    qiblaHeadingHandler = handler

    let storageChannel = FlutterMethodChannel(
      name: "quran/audio_storage",
      binaryMessenger: registrar.messenger()
    )
    storageChannel.setMethodCallHandler { call, result in
      guard call.method == "excludeFromBackup" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let path = arguments["path"] as? String
      else {
        result(FlutterError(code: "bad_args", message: "Missing file path", details: nil))
        return
      }
      var url = URL(fileURLWithPath: path)
      do {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try url.setResourceValues(values)
        result(nil)
      } catch {
        result(FlutterError(code: "backup_exclusion_failed", message: error.localizedDescription, details: nil))
      }
    }
    audioStorageChannel = storageChannel
  }
}
