import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
 override func applicationSupportsSecureRestorableState(_ sender: NSApplication) -> Bool {
        return true // Return true if your application supports secure restorable state
    }
}
