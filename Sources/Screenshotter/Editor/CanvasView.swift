import AppKit
import SwiftUI

class CanvasNSView: NSView {
    var baseImage: NSImage
    var elements: [DrawingElement] = []
    var currentTool: EditorTool = .pen
    var currentColor: NSColor = .red
    var currentLineWidth: CGFloat = 3.0

    // In-progress drawing state
    private var currentStrokePoints: [CGPoint] = []
    private var dragStartPoint: CGPoint?
    private var dragCurrentPoint: CGPoint?
    private var isDrawing = false

    var onElementAdded: (() -> Void)?

    init(image: NSImage) {
        self.baseImage = image
        super.init(frame: NSRect(origin: .zero, size: image.size))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        baseImage.draw(in: bounds)
        for element in elements {
            drawElement(element)
        }
        drawInProgressElement()
    }

    private func drawElement(_ element: DrawingElement) {
        switch element {
        case .stroke(let stroke):
            drawStroke(stroke)
        case .rectangle(let annotation):
            drawRectAnnotation(annotation)
        case .mosaic(let mosaic):
            drawMosaic(mosaic)
        }
    }

    private func drawStroke(_ stroke: PenStroke) {
        guard stroke.points.count > 1 else { return }
        let path = NSBezierPath()
        path.lineWidth = stroke.lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        stroke.color.setStroke()
        path.move(to: stroke.points[0])
        for i in 1..<stroke.points.count {
            path.line(to: stroke.points[i])
        }
        path.stroke()
    }

    private func drawRectAnnotation(_ annotation: RectAnnotation) {
        let path = NSBezierPath(rect: annotation.rect)
        path.lineWidth = annotation.lineWidth
        annotation.color.setStroke()
        path.stroke()
    }

    private func drawMosaic(_ mosaic: MosaicRegion) {
        if let cached = mosaic.cachedImage {
            cached.draw(in: mosaic.rect)
        }
    }

    private func drawInProgressElement() {
        switch currentTool {
        case .pen:
            if currentStrokePoints.count > 1 {
                drawStroke(PenStroke(points: currentStrokePoints, color: currentColor, lineWidth: currentLineWidth))
            }
        case .rectangle:
            if let start = dragStartPoint, let current = dragCurrentPoint {
                let rect = rectFromPoints(start, current)
                drawRectAnnotation(RectAnnotation(rect: rect, color: currentColor, lineWidth: currentLineWidth))
            }
        case .mosaic:
            if let start = dragStartPoint, let current = dragCurrentPoint {
                let rect = rectFromPoints(start, current)
                let path = NSBezierPath(rect: rect)
                path.lineWidth = 2
                let pattern: [CGFloat] = [6, 3]
                path.setLineDash(pattern, count: 2, phase: 0)
                NSColor.white.setStroke()
                path.stroke()
            }
        }
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        let point = convert(event.locationInWindow, from: nil)
        isDrawing = true
        switch currentTool {
        case .pen:
            currentStrokePoints = [point]
        case .rectangle, .mosaic:
            dragStartPoint = point
            dragCurrentPoint = point
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDrawing else { return }
        let point = convert(event.locationInWindow, from: nil)
        switch currentTool {
        case .pen:
            currentStrokePoints.append(point)
        case .rectangle, .mosaic:
            dragCurrentPoint = point
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard isDrawing else { return }
        isDrawing = false

        switch currentTool {
        case .pen:
            if currentStrokePoints.count > 1 {
                elements.append(.stroke(PenStroke(points: currentStrokePoints, color: currentColor, lineWidth: currentLineWidth)))
            }
            currentStrokePoints = []

        case .rectangle:
            if let start = dragStartPoint, let end = dragCurrentPoint {
                let rect = rectFromPoints(start, end)
                if rect.width > 2, rect.height > 2 {
                    elements.append(.rectangle(RectAnnotation(rect: rect, color: currentColor, lineWidth: currentLineWidth)))
                }
            }
            dragStartPoint = nil
            dragCurrentPoint = nil

        case .mosaic:
            if let start = dragStartPoint, let end = dragCurrentPoint {
                let rect = rectFromPoints(start, end)
                if rect.width > 2, rect.height > 2 {
                    let cachedImage = generateMosaicImage(for: rect)
                    elements.append(.mosaic(MosaicRegion(rect: rect, pixelSize: 12, cachedImage: cachedImage)))
                }
            }
            dragStartPoint = nil
            dragCurrentPoint = nil
        }

        needsDisplay = true
        onElementAdded?()
    }

    // MARK: - Mosaic Generation

    /// Render base image + all existing elements into a composite, then pixelate the given rect
    private func generateMosaicImage(for rect: CGRect) -> NSImage? {
        let compositeImage = currentCompositeImage()
        guard let cgImage = compositeImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }

        let imageSize = compositeImage.size
        let scaleX = CGFloat(cgImage.width) / imageSize.width
        let scaleY = CGFloat(cgImage.height) / imageSize.height

        let pixelRect = CGRect(
            x: rect.origin.x * scaleX,
            y: rect.origin.y * scaleY,
            width: rect.width * scaleX,
            height: rect.height * scaleY
        )

        guard let cropped = cgImage.cropping(to: pixelRect) else { return nil }

        let ciImage = CIImage(cgImage: cropped)
        guard let filter = CIFilter(name: "CIPixellate") else { return nil }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(NSNumber(value: 12), forKey: kCIInputScaleKey)
        filter.setValue(CIVector(x: ciImage.extent.midX, y: ciImage.extent.midY), forKey: kCIInputCenterKey)

        guard let output = filter.outputImage else { return nil }
        let context = CIContext()
        guard let resultCG = context.createCGImage(output, from: ciImage.extent) else { return nil }

        return NSImage(cgImage: resultCG, size: rect.size)
    }

    /// Renders base image + all current elements into an NSImage using flipped (top-left) coordinates
    private func currentCompositeImage() -> NSImage {
        let size = baseImage.size
        let image = NSImage(size: size)
        image.lockFocusFlipped(true)
        baseImage.draw(in: NSRect(origin: .zero, size: size))
        for element in elements {
            drawElement(element)
        }
        image.unlockFocus()
        return image
    }

    // MARK: - Export

    /// Renders the full canvas (base image + all annotations) into a final NSImage for export
    func renderedImage() -> NSImage {
        let size = baseImage.size
        let image = NSImage(size: size)
        image.lockFocusFlipped(true)
        baseImage.draw(in: NSRect(origin: .zero, size: size))
        for element in elements {
            drawElement(element)
        }
        image.unlockFocus()
        return image
    }

    // MARK: - Undo

    func undoLastElement() {
        if !elements.isEmpty {
            elements.removeLast()
            needsDisplay = true
        }
    }

    // MARK: - Helpers

    private func rectFromPoints(_ p1: CGPoint, _ p2: CGPoint) -> CGRect {
        CGRect(
            x: min(p1.x, p2.x),
            y: min(p1.y, p2.y),
            width: abs(p2.x - p1.x),
            height: abs(p2.y - p1.y)
        )
    }
}

// MARK: - SwiftUI Wrapper

struct CanvasView: NSViewRepresentable {
    let image: NSImage
    @Binding var tool: EditorTool
    @Binding var color: NSColor
    @Binding var lineWidth: CGFloat
    @Binding var canvasRef: CanvasNSView?

    func makeNSView(context: Context) -> NSScrollView {
        let canvasView = CanvasNSView(image: image)
        canvasView.frame = NSRect(origin: .zero, size: image.size)

        let scrollView = NSScrollView()
        scrollView.documentView = canvasView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.backgroundColor = .windowBackgroundColor
        scrollView.drawsBackground = true

        DispatchQueue.main.async {
            self.canvasRef = canvasView
            canvasView.window?.makeFirstResponder(canvasView)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        if let canvasView = scrollView.documentView as? CanvasNSView {
            canvasView.currentTool = tool
            canvasView.currentColor = color
            canvasView.currentLineWidth = lineWidth
        }
    }
}
