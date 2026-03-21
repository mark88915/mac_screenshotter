import SwiftUI
import AppKit

struct EditorView: View {
    let image: NSImage
    let onDismiss: () -> Void

    @State private var currentTool: EditorTool = .pen
    @State private var currentColor: NSColor = .red
    @State private var currentLineWidth: CGFloat = 3.0
    @State private var canvasRef: CanvasNSView?
    @State private var selectedColorIndex = 0

    private let colors: [(String, NSColor)] = [
        ("紅色", .systemRed),
        ("藍色", .systemBlue),
        ("綠色", .systemGreen),
        ("黃色", .systemYellow),
        ("白色", .white),
        ("黑色", .black),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                // Tool buttons
                ForEach(EditorTool.allCases, id: \.rawValue) { tool in
                    Button(action: { currentTool = tool }) {
                        VStack(spacing: 2) {
                            Image(systemName: tool.systemImage)
                                .font(.system(size: 16))
                            Text(tool.rawValue)
                                .font(.caption2)
                        }
                        .frame(width: 50, height: 40)
                        .contentShape(Rectangle())
                        .background(currentTool == tool ? Color.accentColor.opacity(0.3) : Color.clear)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.borderless)
                }

                Divider().frame(height: 30)

                // Color picker
                ForEach(0..<colors.count, id: \.self) { index in
                    Button(action: {
                        selectedColorIndex = index
                        currentColor = colors[index].1
                    }) {
                        Circle()
                            .fill(Color(nsColor: colors[index].1))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Circle()
                                    .stroke(selectedColorIndex == index ? Color.white : Color.gray.opacity(0.5), lineWidth: selectedColorIndex == index ? 2 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(colors[index].0)
                }

                Divider().frame(height: 30)

                // Line width
                HStack(spacing: 4) {
                    Text("線寬")
                        .font(.caption)
                    Slider(value: $currentLineWidth, in: 1...20, step: 1)
                        .frame(width: 80)
                    Text("\(Int(currentLineWidth))")
                        .font(.caption)
                        .frame(width: 20)
                }

                Divider().frame(height: 30)

                // Undo
                Button(action: {
                    canvasRef?.undoLastElement()
                }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16))
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .help("復原")

                Spacer()

                // Action buttons
                Button(action: copyToClipboard) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.clipboard")
                        Text("複製")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .help("複製到剪貼簿")

                Button(action: saveToFile) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.down")
                        Text("儲存")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .help("儲存到檔案")

                Button(action: onDismiss) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                        Text("關閉")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .help("關閉編輯器")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Canvas area (NSScrollView is built into CanvasView)
            CanvasView(
                image: image,
                tool: $currentTool,
                color: $currentColor,
                lineWidth: $currentLineWidth,
                canvasRef: $canvasRef
            )
        }
    }

    private func exportImage() -> NSImage {
        guard let canvas = canvasRef else { return image }
        return canvas.renderedImage()
    }

    private func copyToClipboard() {
        let finalImage = exportImage()
        ImageExport.copyToClipboard(finalImage)
        onDismiss()
    }

    private func saveToFile() {
        let finalImage = exportImage()
        ImageExport.saveToFile(finalImage)
        onDismiss()
    }
}
