import SwiftUI
#if os(macOS)
import AppKit
#endif

public final class ItemIconCache {
    public static let shared = ItemIconCache()
    #if os(macOS)
    private var cache = NSCache<NSString, NSImage>()

    public func icon(forPath path: String) -> NSImage {
        let key = path as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        let icon = NSWorkspace.shared.icon(forFile: path)
        cache.setObject(icon, forKey: key)
        return icon
    }
    #endif
}

public struct FileItemIconView: View {
    public let path: String
    public let name: String
    public let isDirectory: Bool
    public let isVolume: Bool
    public let fileExtension: String
    public let fallbackIconName: String
    public let size: CGFloat

    public init(
        path: String,
        name: String = "",
        isDirectory: Bool = false,
        isVolume: Bool = false,
        fileExtension: String = "",
        fallbackIconName: String = "doc.fill",
        size: CGFloat = 32
    ) {
        self.path = path
        self.name = name
        self.isDirectory = isDirectory
        self.isVolume = isVolume
        self.fileExtension = fileExtension
        self.fallbackIconName = fallbackIconName
        self.size = size
    }

    public init(item: FileItem, size: CGFloat = 32) {
        self.init(
            path: item.path,
            name: item.name,
            isDirectory: item.isDirectory,
            isVolume: item.isVolume,
            fileExtension: item.fileExtension,
            fallbackIconName: item.iconName,
            size: size
        )
    }

    public var body: some View {
        #if os(macOS)
        let ext = fileExtension.lowercased()
        let isApp = (ext == "app" || path.hasSuffix(".app"))
        let exists = FileManager.default.fileExists(atPath: path)

        if (isApp || (!isDirectory && !isVolume)) && exists {
            let nsImage = ItemIconCache.shared.icon(forPath: path)
            Image(nsImage: nsImage)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            fallbackSymbol
        }
        #else
        fallbackSymbol
        #endif
    }

    private var fallbackSymbol: some View {
        Group {
            if isVolume || path == "/" {
                Image(systemName: "internaldrive.fill")
                    .font(.system(size: size * 0.75))
                    .foregroundColor(Color(red: 0.65, green: 0.65, blue: 0.70))
            } else if isDirectory {
                Image(systemName: "folder.fill")
                    .font(.system(size: size * 0.75))
                    .foregroundColor(Color(red: 0.98, green: 0.80, blue: 0.20))
            } else {
                Image(systemName: fallbackIconName)
                    .font(.system(size: size * 0.75))
                    .foregroundColor(fallbackColor)
            }
        }
        .frame(width: size, height: size)
    }

    private var fallbackColor: Color {
        let ext = fileExtension.lowercased()
        switch ext {
        case "txt", "doc", "rtf", "pdf":
            return Color(red: 0.20, green: 0.45, blue: 0.85)
        case "swift", "c", "h", "cpp", "py", "js", "ts", "sh", "zsh":
            return Color(red: 0.30, green: 0.60, blue: 0.30)
        case "png", "jpg", "jpeg", "gif", "bmp", "heic":
            return Color(red: 0.85, green: 0.40, blue: 0.20)
        case "mp3", "wav", "m4a", "flac":
            return Color(red: 0.85, green: 0.20, blue: 0.50)
        case "mp4", "mov", "avi", "mkv":
            return Color(red: 0.75, green: 0.25, blue: 0.20)
        case "zip", "tar", "gz", "rar", "7z":
            return Color(red: 0.90, green: 0.65, blue: 0.15)
        default:
            return Color(red: 0.20, green: 0.45, blue: 0.85)
        }
    }
}
