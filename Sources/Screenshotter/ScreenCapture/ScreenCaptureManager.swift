import AppKit
import ScreenCaptureKit

class ScreenCaptureManager {
    static let shared = ScreenCaptureManager()
    private var overlayWindows: [RegionSelectionWindow] = []

    private init() {}

    func beginCapture() {
        // Remove any existing overlays
        dismissOverlays()

        // Create an overlay window for each screen
        for screen in NSScreen.screens {
            let window = RegionSelectionWindow(screen: screen)
            window.onRegionSelected = { [weak self] rect, screen in
                self?.captureRegion(rect, on: screen)
            }
            window.onCancelled = { [weak self] in
                self?.dismissOverlays()
            }
            overlayWindows.append(window)
            window.makeKeyAndOrderFront(nil)
        }

        NSApp.activate(ignoringOtherApps: true)
    }

    private func captureRegion(_ viewRect: NSRect, on screen: NSScreen) {
        // Collect overlay window IDs before dismissing
        let overlayIDs = Set(overlayWindows.map { UInt32($0.windowNumber) })

        // Dismiss overlays
        dismissOverlays()

        Task {
            do {
                // Brief delay so overlays finish disappearing
                try await Task.sleep(nanoseconds: 150_000_000)

                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

                // Match the display by CGDirectDisplayID
                let screenDisplayID = screenToCGDisplayID(screen)
                guard let display = content.displays.first(where: { $0.displayID == screenDisplayID })
                    ?? content.displays.first else { return }

                // Exclude our overlay windows
                let excludeWindows = content.windows.filter { overlayIDs.contains($0.windowID) }

                let filter = SCContentFilter(display: display, excludingWindows: excludeWindows)

                let config = SCStreamConfiguration()

                // Convert view rect (bottom-left origin, local to screen) to display coords (top-left origin)
                let screenHeight = screen.frame.height
                let flippedY = screenHeight - viewRect.origin.y - viewRect.height
                config.sourceRect = CGRect(
                    x: viewRect.origin.x,
                    y: flippedY,
                    width: viewRect.width,
                    height: viewRect.height
                )

                let scale = screen.backingScaleFactor
                config.width = Int(viewRect.width * scale)
                config.height = Int(viewRect.height * scale)
                config.showsCursor = false
                config.captureResolution = .best

                let cgImage = try await SCScreenshotManager.captureImage(
                    contentFilter: filter,
                    configuration: config
                )

                await MainActor.run {
                    let nsImage = NSImage(cgImage: cgImage, size: viewRect.size)
                    EditorWindowController.shared.showEditor(with: nsImage)
                }
            } catch {
                print("Screenshot capture failed: \(error)")
                await MainActor.run {
                    let alert = NSAlert()
                    alert.messageText = "截圖失敗"
                    alert.informativeText = "無法擷取螢幕內容。請確認已在「系統設定 > 隱私權與安全性 > 螢幕錄製」中允許 Screenshotter，然後重新啟動程式。\n\n錯誤：\(error.localizedDescription)"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "開啟系統設定")
                    alert.addButton(withTitle: "確定")
                    if alert.runModal() == .alertFirstButtonReturn {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
        }
    }

    private func screenToCGDisplayID(_ screen: NSScreen) -> CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return screen.deviceDescription[key] as? CGDirectDisplayID ?? CGMainDisplayID()
    }

    private func dismissOverlays() {
        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
    }
}
