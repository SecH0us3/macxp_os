import AppKit
import CoreGraphics

func createIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }
    
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    
    // Background squircle (macOS rounded rect style)
    let margin = size * 0.08
    let iconRect = rect.insetBy(dx: margin, dy: margin)
    let cornerRadius = size * 0.2237 // Standard macOS icon squircle radius ratio
    
    let path = CGPath(roundedRect: iconRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    
    // Shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -size * 0.04), blur: size * 0.08, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.35))
    ctx.setFillColor(CGColor(red: 0.12, green: 0.35, blue: 0.78, alpha: 1.0)) // Luna Royal Blue
    ctx.addPath(path)
    ctx.fillPath()
    ctx.restoreGState()
    
    // Luna background gradient
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        CGColor(red: 0.18, green: 0.45, blue: 0.90, alpha: 1.0),
        CGColor(red: 0.10, green: 0.30, blue: 0.72, alpha: 1.0),
        CGColor(red: 0.06, green: 0.22, blue: 0.60, alpha: 1.0)
    ] as CFArray
    let bgLocations: [CGFloat] = [0.0, 0.6, 1.0]
    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
        ctx.drawLinearGradient(bgGradient, start: CGPoint(x: iconRect.midX, y: iconRect.maxY), end: CGPoint(x: iconRect.midX, y: iconRect.minY), options: [])
    }
    
    // Top highlight gloss
    let glossPath = CGMutablePath()
    glossPath.move(to: CGPoint(x: iconRect.minX, y: iconRect.maxY))
    glossPath.addArc(tangent1End: CGPoint(x: iconRect.maxX, y: iconRect.maxY),
                     tangent2End: CGPoint(x: iconRect.maxX, y: iconRect.midY),
                     radius: cornerRadius)
    glossPath.addLine(to: CGPoint(x: iconRect.maxX, y: iconRect.midY + size * 0.05))
    glossPath.addCurve(to: CGPoint(x: iconRect.minX, y: iconRect.midY + size * 0.15),
                       control1: CGPoint(x: iconRect.midX + size * 0.1, y: iconRect.midY + size * 0.05),
                       control2: CGPoint(x: iconRect.midX - size * 0.1, y: iconRect.midY + size * 0.2))
    glossPath.closeSubpath()
    
    ctx.saveGState()
    ctx.addPath(glossPath)
    ctx.clip()
    let glossColors = [
        CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.35),
        CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
    ] as CFArray
    if let glossGradient = CGGradient(colorsSpace: colorSpace, colors: glossColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(glossGradient, start: CGPoint(x: iconRect.midX, y: iconRect.maxY), end: CGPoint(x: iconRect.midX, y: iconRect.midY), options: [])
    }
    ctx.restoreGState()
    
    // Border stroke
    ctx.setLineWidth(max(1.0, size * 0.015))
    ctx.setStrokeColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.4))
    ctx.addPath(path)
    ctx.strokePath()
    
    ctx.restoreGState() // Done with clipped background
    
    // Draw 4-quadrant Windows XP waving flag in center
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let flagSize = size * 0.52
    let half = flagSize * 0.5
    let gap = size * 0.03
    
    func drawTile(color1: CGColor, color2: CGColor, p1: CGPoint, p2: CGPoint, p3: CGPoint, p4: CGPoint) {
        ctx.saveGState()
        let tilePath = CGMutablePath()
        tilePath.move(to: p1)
        tilePath.addLine(to: p2)
        tilePath.addLine(to: p3)
        tilePath.addLine(to: p4)
        tilePath.closeSubpath()
        
        ctx.setShadow(offset: CGSize(width: size * 0.01, height: -size * 0.02), blur: size * 0.03, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.3))
        
        ctx.addPath(tilePath)
        ctx.clip()
        
        let gradColors = [color1, color2] as CFArray
        if let grad = CGGradient(colorsSpace: colorSpace, colors: gradColors, locations: [0.0, 1.0]) {
            ctx.drawLinearGradient(grad, start: CGPoint(x: p1.x, y: p1.y), end: CGPoint(x: p3.x, y: p3.y), options: [])
        }
        
        ctx.restoreGState()
    }
    
    // Coordinates for tiles (with subtle XP wave tilt)
    let left = center.x - half
    let right = center.x + half
    let top = center.y + half
    let bottom = center.y - half
    let midX = center.x
    let midY = center.y
    let tilt: CGFloat = flagSize * 0.07
    
    // Red (Top Left)
    let red1 = CGColor(red: 0.96, green: 0.35, blue: 0.22, alpha: 1.0)
    let red2 = CGColor(red: 0.85, green: 0.15, blue: 0.10, alpha: 1.0)
    drawTile(color1: red1, color2: red2,
             p1: CGPoint(x: left, y: midY + gap + tilt),
             p2: CGPoint(x: midX - gap, y: midY + gap + tilt * 1.5),
             p3: CGPoint(x: midX - gap, y: top + tilt * 0.5),
             p4: CGPoint(x: left, y: top))
    
    // Green (Top Right)
    let green1 = CGColor(red: 0.58, green: 0.82, blue: 0.25, alpha: 1.0)
    let green2 = CGColor(red: 0.42, green: 0.70, blue: 0.12, alpha: 1.0)
    drawTile(color1: green1, color2: green2,
             p1: CGPoint(x: midX + gap, y: midY + gap + tilt * 1.5),
             p2: CGPoint(x: right, y: midY + gap + tilt * 0.8),
             p3: CGPoint(x: right, y: top - tilt * 0.2),
             p4: CGPoint(x: midX + gap, y: top + tilt * 0.5))
    
    // Blue (Bottom Left)
    let blue1 = CGColor(red: 0.15, green: 0.68, blue: 0.95, alpha: 1.0)
    let blue2 = CGColor(red: 0.02, green: 0.48, blue: 0.85, alpha: 1.0)
    drawTile(color1: blue1, color2: blue2,
             p1: CGPoint(x: left, y: bottom),
             p2: CGPoint(x: midX - gap, y: bottom + tilt * 0.5),
             p3: CGPoint(x: midX - gap, y: midY - gap + tilt * 1.5),
             p4: CGPoint(x: left, y: midY - gap + tilt))
    
    // Yellow (Bottom Right)
    let yellow1 = CGColor(red: 1.00, green: 0.80, blue: 0.15, alpha: 1.0)
    let yellow2 = CGColor(red: 0.95, green: 0.62, blue: 0.05, alpha: 1.0)
    drawTile(color1: yellow1, color2: yellow2,
             p1: CGPoint(x: midX + gap, y: bottom + tilt * 0.5),
             p2: CGPoint(x: right, y: bottom - tilt * 0.2),
             p3: CGPoint(x: right, y: midY - gap + tilt * 0.8),
             p4: CGPoint(x: midX + gap, y: midY - gap + tilt * 1.5))
    
    image.unlockFocus()
    return image
}

let fm = FileManager.default
let iconsetDir = "Resources/AppIcon.iconset"
try? fm.removeItem(atPath: iconsetDir)
try? fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let sizes: [(String, CGFloat, Int)] = [
    ("icon_16x16.png", 16, 1),
    ("icon_16x16@2x.png", 16, 2),
    ("icon_32x32.png", 32, 1),
    ("icon_32x32@2x.png", 32, 2),
    ("icon_128x128.png", 128, 1),
    ("icon_128x128@2x.png", 128, 2),
    ("icon_256x256.png", 256, 1),
    ("icon_256x256@2x.png", 256, 2),
    ("icon_512x512.png", 512, 1),
    ("icon_512x512@2x.png", 512, 2),
]

for (name, ptSize, scale) in sizes {
    let pxSize = ptSize * CGFloat(scale)
    let img = createIcon(size: pxSize)
    if let tiff = img.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiff),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        let filePath = "\(iconsetDir)/\(name)"
        try? pngData.write(to: URL(fileURLWithPath: filePath))
    }
}

// Run iconutil
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetDir, "-o", "Resources/AppIcon.icns"]
try? task.run()
task.waitUntilExit()

print("AppIcon.icns generated with exit code \(task.terminationStatus)")
