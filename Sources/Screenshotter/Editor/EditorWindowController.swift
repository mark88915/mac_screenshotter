import AppKit
import SwiftUI

class EditorWindowController {
    static let shared = EditorWindowController()
    private var panel: NSPanel?

    private init() {}

    func showEditor(with image: NSImage) {
        // Close existing editor
        panel?.orderOut(nil)
        panel = nil

        // Calculate window size (cap to 80% of screen)
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let maxWidth = screenFrame.width * 0.8
        let maxHeight = screenFrame.height * 0.8
        let toolbarHeight: CGFloat = 50

        let contentWidth = min(image.size.width, maxWidth)
        let contentHeight = min(image.size.height + toolbarHeight, maxHeight)

        let windowRect = NSRect(
            x: screenFrame.midX - contentWidth / 2,
            y: screenFrame.midY - contentHeight / 2,
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

        let editorView = EditorView(image: image) { [weak self] in
            self?.panel?.orderOut(nil)
            self?.panel = nil
        }

        newPanel.contentView = NSHostingView(rootView: editorView)
        newPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.panel = newPanel
    }
}
