import AppKit
import ScreenCaptureKit

enum Permissions {
    static func checkAndRequestPermissions() {
        // Screen recording permission - try to fetch content to trigger system prompt
        Task {
            do {
                _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            } catch {
                // Permission denied or not yet granted - show guidance
                await MainActor.run {
                    showPermissionAlert()
                }
            }
        }

        // Accessibility permission (for global hotkey)
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    static var hasScreenRecordingPermission: Bool {
        CGPreflightScreenCaptureAccess()
    }

    private static func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "需要螢幕錄製權限"
        alert.informativeText = "請前往「系統設定 > 隱私權與安全性 > 螢幕錄製」中允許 Screenshotter，然後重新啟動程式。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "開啟系統設定")
        alert.addButton(withTitle: "稍後")

        if alert.runModal() == .alertFirstButtonReturn {
            // Open Screen Recording privacy settings
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
