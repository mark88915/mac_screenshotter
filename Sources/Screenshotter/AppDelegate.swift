import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    private var hotkeyManager: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Permissions.checkAndRequestPermissions()
        statusBarController = StatusBarController()
        hotkeyManager = HotkeyManager {
            ScreenCaptureManager.shared.beginCapture()
        }
    }
}
