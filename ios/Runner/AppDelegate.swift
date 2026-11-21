import Flutter
import UIKit
import workmanager_apple
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var qiblaHeadingChannel: FlutterEventChannel?
  private var qiblaHeadingHandler: QiblaHeadingStreamHandler?
  private var audioStorageChannel: FlutterMethodChannel?
  private var offlineSearchAssetsChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    // iOS requires every permitted task to be registered before launch ends.
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "tech.coreinfinite.quran.prayer-alert-renewal",
      earliestBeginInSeconds: NSNumber(value: 12 * 60 * 60)
    )
    WorkmanagerPlugin.registerLaunchHandlers()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "QiblaHeadingStream") else {
      return
    }
    HomeWidgetBridge.register(with: registrar.messenger())
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

    let searchAssetsChannel = FlutterMethodChannel(
      name: "quran/offline_search_assets",
      binaryMessenger: registrar.messenger()
    )
    let filenames = [
      "manifest.json", "search.sqlite",
    ]
    let assetKeys = filenames.map { filename in
      (filename, registrar.lookupKey(forAsset: "assets/keyword_search/\(filename)"))
    }
    let appBundleURL = Bundle.main.bundleURL
    searchAssetsChannel.setMethodCallHandler { call, result in
      guard call.method == "prepare" else {
        result(FlutterMethodNotImplemented)
        return
      }
      DispatchQueue.global(qos: .userInitiated).async {
        let frameworkURL = appBundleURL.appendingPathComponent("Frameworks/App.framework")
        let assetBundleURL = Bundle(url: frameworkURL)?.bundleURL ?? frameworkURL
        var paths: [String: String] = [:]
        for (filename, key) in assetKeys {
          let candidates = [
            assetBundleURL.appendingPathComponent(key),
            assetBundleURL.appendingPathComponent("flutter_assets/\(key)"),
            assetBundleURL.appendingPathComponent("flutter_assets/assets/keyword_search/\(filename)"),
          ]
          guard let assetURL = candidates.first(where: { url in
            var isDirectory: ObjCBool = false
            return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
              && !isDirectory.boolValue && FileManager.default.isReadableFile(atPath: url.path)
          }) else {
            DispatchQueue.main.async {
              result(FlutterError(
                code: "offline_search_assets_unavailable",
                message: "Offline search assets could not be located.",
                details: nil
              ))
            }
            return
          }
          paths[filename] = assetURL.path
        }
        let preparedPaths = paths
        DispatchQueue.main.async { result(preparedPaths) }
      }
    }
    offlineSearchAssetsChannel = searchAssetsChannel
  }
}

enum HomeWidgetBridge {
  private static let group = "group.com.coreinfinite.quran.widgets"
  private static var channel: FlutterMethodChannel?
  private static var pendingPath: String?

  static func register(with messenger: FlutterBinaryMessenger) {
    let bridge = FlutterMethodChannel(name: "quran/home_screen_widgets", binaryMessenger: messenger)
    channel = bridge
    bridge.setMethodCallHandler { call, result in
      switch call.method {
      case "takeLink":
        let path = pendingPath
        pendingPath = nil
        result(path)
      case "canPin", "pin":
        result(false)
      case "publish", "clear":
        do {
          try save(call.method == "publish" ? call.arguments as? String : nil)
          result(nil)
        } catch {
          result(FlutterError(code: "widget_storage", message: error.localizedDescription, details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  static func accept(_ url: URL) {
    guard
      url.scheme == "quranwidget",
      url.host == "open",
      let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
      parts.percentEncodedPath.hasPrefix("/")
    else { return }
    pendingPath = parts.percentEncodedPath + (parts.percentEncodedQuery.map { "?\($0)" } ?? "")
    channel?.invokeMethod("linkAvailable", arguments: nil)
  }

  private static func save(_ value: String?) throws {
    guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else {
      if value == nil { return }
      throw CocoaError(.fileWriteNoPermission)
    }
    let url = container.appendingPathComponent("widgets.json")
    if let value {
      let data = Data(value.utf8)
      if (try? Data(contentsOf: url)) == data { return }
      try data.write(to: url, options: .atomic)
    } else if FileManager.default.fileExists(atPath: url.path) {
      try FileManager.default.removeItem(at: url)
    }
    WidgetCenter.shared.reloadAllTimelines()
  }
}
