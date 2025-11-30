import Cocoa
import FlutterMacOS

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
