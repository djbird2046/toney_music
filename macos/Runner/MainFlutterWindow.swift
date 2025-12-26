import Cocoa
import FlutterMacOS

class SecurityScopedAccessPlugin: NSObject, FlutterPlugin {
  private var activeUrls: [String: URL] = [:]

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "security_scoped_access",
      binaryMessenger: registrar.messenger
    )
    let instance = SecurityScopedAccessPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "createBookmark":
      guard
        let args = call.arguments as? [String: Any],
        let path = args["path"] as? String
      else {
        return result(FlutterError(code: "INVALID", message: nil, details: nil))
      }
      do {
        let url = URL(fileURLWithPath: path)
        let bookmark = try url.bookmarkData(options: [.withSecurityScope],
                                            includingResourceValuesForKeys: nil,
                                            relativeTo: nil)
        result(bookmark.base64EncodedString())
      } catch {
        result(FlutterError(code: "BOOKMARK_FAILED", message: error.localizedDescription, details: nil))
      }

    case "startAccess":
      guard
        let args = call.arguments as? [String: Any],
        let bookmarkBase64 = args["bookmark"] as? String,
        let data = Data(base64Encoded: bookmarkBase64)
      else {
        return result(FlutterError(code: "INVALID", message: nil, details: nil))
      }
      do {
        var stale = false
        var url = try URL(
          resolvingBookmarkData: data,
          options: [.withSecurityScope, .withoutUI],
          relativeTo: nil,
          bookmarkDataIsStale: &stale
        )
        var returnedBookmark: String? = nil
        if stale {
          let refreshed = try url.bookmarkData(options: [.withSecurityScope],
                                               includingResourceValuesForKeys: nil,
                                               relativeTo: nil)
          returnedBookmark = refreshed.base64EncodedString()
          url = try URL(resolvingBookmarkData: refreshed,
                        options: [.withSecurityScope, .withoutUI],
                        relativeTo: nil,
                        bookmarkDataIsStale: &stale)
        }
        let started = url.startAccessingSecurityScopedResource()
        if !started {
          return result(FlutterError(code: "ACCESS_DENIED", message: "Failed to start security scope", details: nil))
        }
        let token = UUID().uuidString
        activeUrls[token] = url
        var payload: [String: Any] = ["token": token, "path": url.path]
        if let returnedBookmark {
          payload["bookmark"] = returnedBookmark
        }
        result(payload)
      } catch {
        result(FlutterError(code: "RESOLVE_FAILED", message: error.localizedDescription, details: nil))
      }

    case "stopAccess":
      guard
        let args = call.arguments as? [String: Any],
        let token = args["token"] as? String
      else {
        return result(FlutterError(code: "INVALID", message: nil, details: nil))
      }
      if let url = activeUrls.removeValue(forKey: token) {
        url.stopAccessingSecurityScopedResource()
      }
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    self.delegate = self

    let desiredSize = NSSize(width: 1200, height: 800)
    if let screen = NSScreen.main {
      let origin = NSPoint(
        x: screen.frame.midX - desiredSize.width / 2,
        y: screen.frame.midY - desiredSize.height / 2
      )
      let rect = NSRect(origin: origin, size: desiredSize)
      self.setFrame(rect, display: true)
    } else {
      self.setContentSize(desiredSize)
      self.center()
    }
    self.title = "Toney Music"
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.styleMask.insert(.fullSizeContentView)
    self.isMovableByWindowBackground = true
    if #available(macOS 11.0, *) {
      self.standardWindowButton(.closeButton)?.contentTintColor = NSColor.systemRed
      self.standardWindowButton(.miniaturizeButton)?.contentTintColor = NSColor.systemYellow
      self.standardWindowButton(.zoomButton)?.contentTintColor = NSColor.systemGreen
    }

    RegisterGeneratedPlugins(registry: flutterViewController)
    let registrar = flutterViewController.registrar(forPlugin: "AudioEnginePlugin")
    AudioEnginePlugin.register(with: registrar)
    if #available(macOS 10.15, *) {
      let moodRegistrar = flutterViewController.registrar(forPlugin: "MoodEnginePlugin")
      MoodEnginePlugin.register(with: moodRegistrar)
    }
    SecurityScopedAccessPlugin.register(
      with: flutterViewController.registrar(forPlugin: "SecurityScopedAccessPlugin")
    )

    let windowChannel = FlutterMethodChannel(
      name: "window_control",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    windowChannel.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "minimize" {
        self?.miniaturize(nil)
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    sender.miniaturize(nil)
    return false
  }
}
