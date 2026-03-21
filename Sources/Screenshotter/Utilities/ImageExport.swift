import AppKit

enum ImageExport {
    static func copyToClipboard(_ image: NSImage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    static func saveToFile(_ image: NSImage, directory: String? = nil) {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return
        }

        if let directory = directory {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
            let timestamp = formatter.string(from: Date())
            let filename = "Screenshot \(timestamp).png"
            let url = URL(fileURLWithPath: directory).appendingPathComponent(filename)

            do {
                try pngData.write(to: url)
            } catch {
                showSavePanel(pngData: pngData)
            }
        } else {
            showSavePanel(pngData: pngData)
        }
    }

    private static func showSavePanel(pngData: Data) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "Screenshot.png"
        savePanel.canCreateDirectories = true

        if savePanel.runModal() == .OK, let url = savePanel.url {
            try? pngData.write(to: url)
        }
    }
}
