import AppKit

class RegionSelectionView: NSView {
    var onRegionSelected: ((NSRect) -> Void)?
    var onCancelled: (() -> Void)?

    private var startPoint: NSPoint?
    private var currentRect: NSRect?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
        NSCursor.crosshair.push()
    }

    override func removeFromSuperview() {
        NSCursor.pop()
        super.removeFromSuperview()
    }

    override func draw(_ dirtyRect: NSRect) {
        // Semi-transparent overlay
        NSColor.black.withAlphaComponent(0.3).setFill()
        bounds.fill()

        // Draw selection rect
        if let rect = currentRect, rect.width > 0, rect.height > 0 {
            // Clear the selected area (punch through)
            NSGraphicsContext.current?.compositingOperation = .clear
            rect.fill()

            // Reset compositing
            NSGraphicsContext.current?.compositingOperation = .sourceOver

            // White border around selection
            NSColor.white.setStroke()
            let borderPath = NSBezierPath(rect: rect)
            borderPath.lineWidth = 1.5
            borderPath.stroke()

            // Dimension label
            drawDimensionLabel(for: rect)
        }
    }

    private func drawDimensionLabel(for rect: NSRect) {
        let text = "\(Int(rect.width)) × \(Int(rect.height))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let size = (text as NSString).size(withAttributes: attributes)
        let padding: CGFloat = 6

        // Position label below the selection rect
        var labelOrigin = NSPoint(
            x: rect.midX - size.width / 2 - padding,
            y: rect.minY - size.height - padding * 2 - 4
        )

        // Keep label within bounds
        if labelOrigin.y < bounds.minY + 4 {
            labelOrigin.y = rect.maxY + 4
        }

        let bgRect = NSRect(
            x: labelOrigin.x,
            y: labelOrigin.y,
            width: size.width + padding * 2,
            height: size.height + padding * 2
        )

        // Background
        NSColor.black.withAlphaComponent(0.7).setFill()
        let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: 4, yRadius: 4)
        bgPath.fill()

        // Text
        let textPoint = NSPoint(
            x: bgRect.origin.x + padding,
            y: bgRect.origin.y + padding
        )
        (text as NSString).draw(at: textPoint, withAttributes: attributes)
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        currentRect = nil
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let current = convert(event.locationInWindow, from: nil)

        let x = min(start.x, current.x)
        let y = min(start.y, current.y)
        let w = abs(current.x - start.x)
        let h = abs(current.y - start.y)

        currentRect = NSRect(x: x, y: y, width: w, height: h)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let rect = currentRect, rect.width > 2, rect.height > 2 else {
            // Too small, treat as cancel
            startPoint = nil
            currentRect = nil
            needsDisplay = true
            return
        }

        NSCursor.pop()
        onRegionSelected?(rect)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            NSCursor.pop()
            onCancelled?()
        }
    }
}
