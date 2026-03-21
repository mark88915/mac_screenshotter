import AppKit

enum DrawingElement {
    case stroke(PenStroke)
    case rectangle(RectAnnotation)
    case mosaic(MosaicRegion)
}

struct PenStroke {
    var points: [CGPoint]
    var color: NSColor
    var lineWidth: CGFloat
}

struct RectAnnotation {
    var rect: CGRect
    var color: NSColor
    var lineWidth: CGFloat
}

struct MosaicRegion {
    var rect: CGRect
    var pixelSize: Int
    var cachedImage: NSImage?
}

enum EditorTool: String, CaseIterable {
    case pen = "畫筆"
    case rectangle = "框選"
    case mosaic = "馬賽克"

    var systemImage: String {
        switch self {
        case .pen: return "pencil.tip"
        case .rectangle: return "rectangle"
        case .mosaic: return "square.grid.3x3.topleft.filled"
        }
    }
}
