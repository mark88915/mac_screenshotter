import AppKit

class RegionSelectionWindow: NSWindow {
    var onRegionSelected: ((NSRect, NSScreen) -> Void)?
    var onCancelled: (() -> Void)?

    let targetScreen: NSScreen

    init(screen: NSScreen) {
        self.targetScreen = screen
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true

        let selectionView = RegionSelectionView(frame: screen.frame)
        selectionView.onRegionSelected = { [weak self] rect in
            guard let self = self else { return }
            self.onRegionSelected?(rect, self.targetScreen)
        }
        selectionView.onCancelled = { [weak self] in
            self?.onCancelled?()
        }

        self.contentView = selectionView
    }
}
