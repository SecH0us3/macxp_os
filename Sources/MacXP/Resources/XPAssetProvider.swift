import AppKit
import Foundation

public final class XPAssetProvider {
    public static let shared = XPAssetProvider()

    private var cachedBliss: NSImage?
    private var cachedFlag: NSImage?
    private var cachedStartButton: NSImage?

    private init() {}

    /// Loads the authentic Windows XP Bliss wallpaper image
    public static func loadBlissImage() -> NSImage? {
        if let cached = shared.cachedBliss {
            return cached
        }

        // Search locations in priority order:
        let searchPaths: [URL?] = [
            Bundle.main.url(forResource: "bliss", withExtension: "jpg"),
            Bundle.main.url(forResource: "bliss", withExtension: "png"),
            Bundle.main.resourceURL?.appendingPathComponent("bliss.jpg"),
            Bundle.main.resourceURL?.appendingPathComponent("bliss.png"),
            URL(fileURLWithPath: "Resources/bliss.jpg"),
            URL(fileURLWithPath: "Resources/bliss.png"),
            URL(fileURLWithPath: "Sources/MacXP/Resources/bliss.jpg"),
            URL(fileURLWithPath: "Sources/MacXP/Resources/bliss.png"),
            URL(fileURLWithPath: "../Resources/bliss.jpg"),
            URL(fileURLWithPath: "../Resources/bliss.png"),
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/bliss.jpg"),
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/bliss.png")
        ]

        for case let url? in searchPaths {
            if FileManager.default.fileExists(atPath: url.path),
               let image = NSImage(contentsOf: url) {
                shared.cachedBliss = image
                return image
            }
        }

        return nil
    }

    /// Loads the authentic Windows XP Start Button image
    public static func loadStartButtonImage() -> NSImage? {
        if let cached = shared.cachedStartButton {
            return cached
        }

        let searchPaths: [URL?] = [
            Bundle.main.url(forResource: "start_button", withExtension: "png"),
            Bundle.main.url(forResource: "start", withExtension: "png"),
            Bundle.main.resourceURL?.appendingPathComponent("start_button.png"),
            Bundle.main.resourceURL?.appendingPathComponent("start.png"),
            URL(fileURLWithPath: "Resources/start_button.png"),
            URL(fileURLWithPath: "Resources/start.png"),
            URL(fileURLWithPath: "Sources/MacXP/Resources/start_button.png"),
            URL(fileURLWithPath: "../Resources/start_button.png"),
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/start_button.png")
        ]

        for case let url? in searchPaths {
            if FileManager.default.fileExists(atPath: url.path),
               let image = NSImage(contentsOf: url) {
                shared.cachedStartButton = image
                return image
            }
        }

        return nil
    }

    /// Loads the authentic 4-color Windows XP flag logo
    public static func loadFlagImage() -> NSImage? {
        if let cached = shared.cachedFlag {
            return cached
        }

        let searchPaths: [URL?] = [
            Bundle.main.url(forResource: "windows_flag_64", withExtension: "png"),
            Bundle.main.url(forResource: "windows_flag_32", withExtension: "png"),
            Bundle.main.url(forResource: "windows_flag", withExtension: "svg"),
            Bundle.main.resourceURL?.appendingPathComponent("windows_flag_64.png"),
            URL(fileURLWithPath: "Resources/windows_flag_64.png"),
            URL(fileURLWithPath: "Resources/windows_flag_32.png"),
            URL(fileURLWithPath: "Sources/MacXP/Resources/windows_flag_64.png"),
            URL(fileURLWithPath: "Resources/windows_flag.svg"),
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/windows_flag_64.png")
        ]

        for case let url? in searchPaths {
            if FileManager.default.fileExists(atPath: url.path),
               let image = NSImage(contentsOf: url) {
                shared.cachedFlag = image
                return image
            }
        }

        return nil
    }

    private var cachedIEIcon: NSImage?
    private var iconCache: [String: NSImage] = [:]

    /// Loads an authentic Windows XP icon from Resources/Icons/<name>.png
    public static func loadIcon(named name: String) -> NSImage? {
        if let cached = shared.iconCache[name] {
            return cached
        }

        let baseName = (name as NSString).deletingPathExtension
        let searchPaths: [URL?] = [
            Bundle.main.url(forResource: baseName, withExtension: "png", subdirectory: "Icons"),
            Bundle.main.url(forResource: baseName, withExtension: "png"),
            Bundle.main.resourceURL?.appendingPathComponent("Icons/\(baseName).png"),
            Bundle.main.resourceURL?.appendingPathComponent("\(baseName).png"),
            URL(fileURLWithPath: "Resources/Icons/\(baseName).png"),
            URL(fileURLWithPath: "Resources/\(baseName).png"),
            URL(fileURLWithPath: "../Resources/Icons/\(baseName).png"),
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/Icons/\(baseName).png"),
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/\(baseName).png")
        ]

        for case let url? in searchPaths {
            if FileManager.default.fileExists(atPath: url.path),
               let image = NSImage(contentsOf: url) {
                shared.iconCache[name] = image
                return image
            }
        }

        return nil
    }

    /// Loads the authentic Windows XP "My Computer" icon
    public static func loadMyComputerIcon() -> NSImage? {
        loadIcon(named: "my_computer")
    }

    /// Loads the authentic Windows XP "Local Disk (C:)" Hard Drive icon
    public static func loadHardDriveIcon() -> NSImage? {
        loadIcon(named: "drive_harddisk")
    }

    /// Loads the authentic Windows XP yellow Folder icon
    public static func loadFolderIcon() -> NSImage? {
        loadIcon(named: "folder")
    }

    /// Loads the authentic Windows XP "My Documents" icon
    public static func loadMyDocumentsIcon() -> NSImage? {
        loadIcon(named: "my_documents")
    }

    /// Loads the authentic Windows XP "Shared Documents" icon
    public static func loadSharedDocumentsIcon() -> NSImage? {
        loadIcon(named: "shared_documents")
    }

    /// Loads the authentic Windows XP Recycle Bin icon (empty or full)
    public static func loadRecycleIcon(isEmpty: Bool = true) -> NSImage? {
        loadIcon(named: isEmpty ? "recycle_empty" : "recycle_full")
    }

    /// Loads the authentic Windows XP Optical CD/DVD Drive icon
    public static func loadOpticalDriveIcon() -> NSImage? {
        loadIcon(named: "drive_optical")
    }

    /// Loads the authentic Windows XP 3.5 Floppy Drive icon
    public static func loadFloppyDriveIcon() -> NSImage? {
        loadIcon(named: "drive_floppy")
    }

    /// Loads the authentic Windows XP USB / Removable Drive icon
    public static func loadRemovableDriveIcon() -> NSImage? {
        loadIcon(named: "drive_removable")
    }

    /// Loads the authentic Windows XP Control Panel icon
    public static func loadControlPanelIcon() -> NSImage? {
        loadIcon(named: "control_panel")
    }

    /// Loads the authentic Windows XP My Network Places icon
    public static func loadNetworkPlacesIcon() -> NSImage? {
        loadIcon(named: "network_places")
    }

    /// Loads the authentic Windows XP Internet Explorer 6 icon
    public static func loadIEIcon() -> NSImage? {
        if let cached = shared.cachedIEIcon {
            return cached
        }

        if let icon = loadIcon(named: "ie") {
            shared.cachedIEIcon = icon
            return icon
        }

        let searchPaths: [URL?] = [
            Bundle.main.url(forResource: "ie", withExtension: "png"),
            Bundle.main.resourceURL?.appendingPathComponent("ie.png"),
            URL(fileURLWithPath: "Resources/ie.png"),
            URL(fileURLWithPath: "../Resources/ie.png"),
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/ie.png")
        ]

        for case let url? in searchPaths {
            if FileManager.default.fileExists(atPath: url.path),
               let image = NSImage(contentsOf: url) {
                shared.cachedIEIcon = image
                return image
            }
        }

        return nil
    }

    /// Loads authentic Windows XP audio data (MP3 or WAV) for the specified sound type
    public static func loadSoundData(for sound: XPSound) -> Data? {
        let filename = sound.rawValue
        let exts = ["mp3", "wav"]

        for ext in exts {
            let searchPaths: [URL?] = [
                Bundle.main.url(forResource: filename, withExtension: ext, subdirectory: "Sounds"),
                Bundle.main.url(forResource: filename, withExtension: ext),
                Bundle.main.resourceURL?.appendingPathComponent("Sounds/\(filename).\(ext)"),
                Bundle.main.resourceURL?.appendingPathComponent("\(filename).\(ext)"),
                URL(fileURLWithPath: "Resources/Sounds/\(filename).\(ext)"),
                URL(fileURLWithPath: "Resources/\(filename).\(ext)"),
                URL(fileURLWithPath: "Sources/MacXP/Resources/Sounds/\(filename).\(ext)"),
                URL(fileURLWithPath: "../Resources/Sounds/\(filename).\(ext)"),
                Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/Sounds/\(filename).\(ext)"),
                Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/\(filename).\(ext)")
            ]

            for case let url? in searchPaths {
                if FileManager.default.fileExists(atPath: url.path),
                   let data = try? Data(contentsOf: url),
                   data.count > 100 {
                    return data
                }
            }
        }

        return nil
    }

    /// Loads sample music audio data (MP3 or WAV) by name
    public static func loadMusicData(for name: String) -> Data? {
        let exts = ["wav", "mp3", "m4a"]

        for ext in exts {
            let base = (name as NSString).deletingPathExtension
            let searchPaths: [URL?] = [
                Bundle.main.url(forResource: base, withExtension: ext, subdirectory: "Music"),
                Bundle.main.url(forResource: base, withExtension: ext),
                Bundle.main.resourceURL?.appendingPathComponent("Music/\(base).\(ext)"),
                Bundle.main.resourceURL?.appendingPathComponent("\(base).\(ext)"),
                URL(fileURLWithPath: "Resources/Music/\(base).\(ext)"),
                URL(fileURLWithPath: "Resources/\(base).\(ext)"),
                URL(fileURLWithPath: "../Resources/Music/\(base).\(ext)"),
                Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/Music/\(base).\(ext)")
            ]

            for case let url? in searchPaths {
                if FileManager.default.fileExists(atPath: url.path),
                   let data = try? Data(contentsOf: url),
                   data.count > 100 {
                    return data
                }
            }
        }

        return nil
    }

    /// Renders or returns an authentic Windows XP Start Button bitmap texture
    public static func renderStartButtonTexture(width: CGFloat, height: CGFloat, isPressed: Bool, isHovered: Bool) -> NSImage {
        let size = NSSize(width: width, height: height)
        let image = NSImage(size: size)
        image.lockFocus()

        let bounds = NSRect(origin: .zero, size: size)

        // Draw pill background
        let radius = bounds.height / 2
        let path = NSBezierPath()
        path.move(to: NSPoint(x: bounds.minX, y: bounds.minY))
        path.line(to: NSPoint(x: bounds.maxX - radius, y: bounds.minY))
        path.appendArc(withCenter: NSPoint(x: bounds.maxX - radius, y: bounds.minY + radius), radius: radius, startAngle: 270, endAngle: 90, clockwise: false)
        path.line(to: NSPoint(x: bounds.minX, y: bounds.maxY))
        path.close()

        // Authentic Luna Green Gradients
        let topColor: NSColor
        let midColor: NSColor
        let botColor: NSColor

        if isPressed {
            topColor = NSColor(calibratedRed: 0.12, green: 0.38, blue: 0.12, alpha: 1.0)
            midColor = NSColor(calibratedRed: 0.18, green: 0.50, blue: 0.18, alpha: 1.0)
            botColor = NSColor(calibratedRed: 0.15, green: 0.44, blue: 0.15, alpha: 1.0)
        } else if isHovered {
            topColor = NSColor(calibratedRed: 0.38, green: 0.82, blue: 0.38, alpha: 1.0)
            midColor = NSColor(calibratedRed: 0.30, green: 0.72, blue: 0.30, alpha: 1.0)
            botColor = NSColor(calibratedRed: 0.22, green: 0.60, blue: 0.22, alpha: 1.0)
        } else {
            topColor = NSColor(calibratedRed: 0.24, green: 0.65, blue: 0.24, alpha: 1.0)
            midColor = NSColor(calibratedRed: 0.22, green: 0.58, blue: 0.22, alpha: 1.0)
            botColor = NSColor(calibratedRed: 0.14, green: 0.45, blue: 0.14, alpha: 1.0)
        }

        if let gradient = NSGradient(colorsAndLocations: (topColor, 0.0), (midColor, 0.5), (botColor, 1.0)) {
            gradient.draw(in: path, angle: 270)
        }

        // Top Gloss highlight
        let highlightPath = NSBezierPath()
        highlightPath.move(to: NSPoint(x: bounds.minX, y: bounds.maxY))
        highlightPath.line(to: NSPoint(x: bounds.maxX - radius, y: bounds.maxY))
        highlightPath.appendArc(withCenter: NSPoint(x: bounds.maxX - radius, y: bounds.minY + radius), radius: radius, startAngle: 90, endAngle: 45, clockwise: true)
        highlightPath.line(to: NSPoint(x: bounds.minX, y: bounds.midY))
        highlightPath.close()

        if let highlightGradient = NSGradient(colors: [NSColor.white.withAlphaComponent(isPressed ? 0.05 : 0.45), NSColor.white.withAlphaComponent(0.0)]) {
            highlightGradient.draw(in: highlightPath, angle: 270)
        }

        // Stroke Border
        let strokeColor = isPressed ? NSColor(calibratedRed: 0.08, green: 0.25, blue: 0.08, alpha: 1.0) : NSColor(calibratedRed: 0.10, green: 0.35, blue: 0.10, alpha: 1.0)
        strokeColor.setStroke()
        path.lineWidth = 1.0
        path.stroke()

        image.unlockFocus()
        return image
    }
}
