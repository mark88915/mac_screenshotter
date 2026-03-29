import AppKit
import SwiftUI

class EditorWindowController {
    static let shared = EditorWindowController()
    private var panels: [NSPanel] = []

    private init() {}

    func showEditor(with image: NSImage) {
        // Calculate window size (cap to 80% of screen)
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let maxWidth = screenFrame.width * 0.8
        let maxHeight = screenFrame.height * 0.8
        let toolbarHeight: CGFloat = 50

        let contentWidth = min(image.size.width, maxWidth)
        let contentHeight = min(image.size.height + toolbarHeight, maxHeight)

        // Offset each new window slightly so they don't stack exactly on top of each other
        let offset = CGFloat(panels.count % 10) * 25
        let windowRect = NSRect(
            x: screenFrame.midX - contentWidth / 2 + offset,
            y: screenFrame.midY - contentHeight / 2 - offset,
            width: contentWidth,
            height: contentHeight
        )

        let newPanel = NSPanel(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .resizable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        newPanel.title = "Screenshotter 編輯器"
        newPanel.level = .floating
        newPanel.isMovableByWindowBackground = false
        newPanel.isReleasedWhenClosed = false
        newPanel.becomesKeyOnlyIfNeeded = false

        let editorView = EditorView(image: image) { [weak self, weak newPanel] in
            newPanel?.orderOut(nil)
            if let panel = newPanel {
                self?.panels.removeAll { $0 === panel }
            }
        }

        newPanel.contentView = NSHostingView(rootView: editorView)
        newPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        panels.append(newPanel)
    }
}
