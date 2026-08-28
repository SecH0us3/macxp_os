
import AppKit

let url = URL(fileURLWithPath: "Resources/windows_flag.svg")
if let image = NSImage(contentsOf: url) {
    for size: CGFloat in [16, 24, 32, 48, 64, 128] {
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
        NSGraphicsContext.restoreGraphicsState()
        if let pngData = rep.representation(using: .png, properties: [:]) {
            try? pngData.write(to: URL(fileURLWithPath: "Resources/windows_flag_\(Int(size)).png"))
            try? pngData.write(to: URL(fileURLWithPath: "Sources/MacXP/Resources/windows_flag_\(Int(size)).png"))
        }
    }
    print("Rendered flag PNGs successfully!")
} else {
    print("Could not load SVG with NSImage")
}
