import Foundation
import SwiftUI
#if os(macOS)
import AppKit
#endif

public struct FileItem: Identifiable, Equatable, Hashable {
    public let id: UUID
    public var name: String
    public var url: URL
    public var path: String
    public var isDirectory: Bool
    public var isVolume: Bool
    public var size: Int64
    public var dateModified: Date
    public var fileExtension: String
    public var iconName: String
    public var formattedSize: String
    public var typeDescription: String

    public init(
        id: UUID = UUID(),
        name: String,
        url: URL,
        path: String,
        isDirectory: Bool,
        isVolume: Bool = false,
        size: Int64 = 0,
        dateModified: Date = Date(),
        fileExtension: String = "",
        iconName: String = "doc.fill",
        formattedSize: String = "",
        typeDescription: String = "File"
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.path = path
        self.isDirectory = isDirectory
        self.isVolume = isVolume
        self.size = size
        self.dateModified = dateModified
        self.fileExtension = fileExtension
        self.iconName = iconName
        self.formattedSize = formattedSize
        self.typeDescription = typeDescription
    }
}

public struct FileItemProperties: Equatable {
    public var name: String
    public var path: String
    public var isDirectory: Bool
    public var size: Int64
    public var formattedSize: String
    public var dateCreated: Date?
    public var dateModified: Date
    public var typeDescription: String
    public var isReadOnly: Bool
    public var isHidden: Bool

    public init(
        name: String,
        path: String,
        isDirectory: Bool,
        size: Int64,
        formattedSize: String,
        dateCreated: Date? = nil,
        dateModified: Date = Date(),
        typeDescription: String = "File",
        isReadOnly: Bool = false,
        isHidden: Bool = false
    ) {
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.size = size
        self.formattedSize = formattedSize
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.typeDescription = typeDescription
        self.isReadOnly = isReadOnly
        self.isHidden = isHidden
    }
}

public struct ExplorerState: Equatable {
    public var currentPath: String
    public var history: [String]
    public var historyIndex: Int

    public init(initialPath: String = "computer://") {
        let service = FileSystemService.shared
        let resolved = service.resolvePath(initialPath)
        self.currentPath = resolved
        self.history = [resolved]
        self.historyIndex = 0
    }

    public var canGoBack: Bool {
        historyIndex > 0
    }

    public var canGoForward: Bool {
        historyIndex < history.count - 1
    }

    public var canGoUp: Bool {
        let service = FileSystemService.shared
        let parent = service.parentDirectory(of: currentPath)
        return parent != currentPath || currentPath != "computer://"
    }

    public mutating func navigateTo(path: String) {
        let service = FileSystemService.shared
        let resolved = service.resolvePath(path)
        guard resolved != currentPath else { return }

        if historyIndex < history.count - 1 {
            history.removeSubrange((historyIndex + 1)..<history.count)
        }
        history.append(resolved)
        historyIndex = history.count - 1
        currentPath = resolved
    }

    public mutating func goBack() {
        guard canGoBack else { return }
        historyIndex -= 1
        currentPath = history[historyIndex]
    }

    public mutating func goForward() {
        guard canGoForward else { return }
        historyIndex += 1
        currentPath = history[historyIndex]
    }

    public mutating func goUp() {
        let service = FileSystemService.shared
        let parent = service.parentDirectory(of: currentPath)
        if parent != currentPath {
            navigateTo(path: parent)
        }
    }
}

public class FileSystemService: ObservableObject {
    public static let shared = FileSystemService()

    public init() {}

    // MARK: - Path Resolution & Display

    public func resolvePath(_ rawPath: String) -> String {
        let trimmed = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.caseInsensitiveCompare("My Computer") == .orderedSame || trimmed == "computer://" {
            return "computer://"
        }

        // Windows drive mapping (e.g. C:\ or C:/ or C:\Users\...)
        if trimmed.hasPrefix("C:\\") || trimmed.hasPrefix("c:\\") || trimmed == "C:" || trimmed == "c:" {
            let sub = trimmed.dropFirst(2)
            let unixSub = sub.replacingOccurrences(of: "\\", with: "/")
            let normalized = unixSub.isEmpty ? "/" : unixSub
            return (normalized.hasPrefix("/") ? normalized : "/" + normalized)
        }
        if trimmed.hasPrefix("C:/") || trimmed.hasPrefix("c:/") {
            let sub = trimmed.dropFirst(2)
            let unixSub = String(sub)
            return unixSub.isEmpty ? "/" : unixSub
        }

        // Tilde expansion
        if trimmed == "~" {
            return FileManager.default.homeDirectoryForCurrentUser.path
        }
        if trimmed.hasPrefix("~/") {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            let sub = trimmed.dropFirst(2)
            return (home as NSString).appendingPathComponent(String(sub))
        }

        // File URL parsing
        if trimmed.hasPrefix("file://") {
            if let url = URL(string: trimmed) {
                return url.path
            }
        }

        return trimmed
    }

    public func formatPathForDisplay(_ path: String) -> String {
        let resolved = resolvePath(path)
        if resolved == "computer://" {
            return "My Computer"
        }
        if resolved == "/" {
            return "C:\\"
        }
        if resolved.hasPrefix("/") {
            let winPath = resolved.replacingOccurrences(of: "/", with: "\\")
            return "C:\(winPath)"
        }
        return resolved
    }

    public func parentDirectory(of path: String) -> String {
        let resolved = resolvePath(path)
        if resolved == "computer://" {
            return "computer://"
        }
        if resolved == "/" {
            return "computer://"
        }
        let nsPath = resolved as NSString
        let parent = nsPath.deletingLastPathComponent
        if parent.isEmpty || parent == resolved {
            return "computer://"
        }
        return parent
    }

    // MARK: - Directory Listings

    public func myComputerDrives() -> [FileItem] {
        var items: [FileItem] = []

        // 1. Local Disk (C:) - Mac Root /
        let rootURL = URL(fileURLWithPath: "/")
        let rootSpace = diskSpace(for: "/")
        items.append(
            FileItem(
                name: "Local Disk (C:)",
                url: rootURL,
                path: "/",
                isDirectory: true,
                isVolume: true,
                size: rootSpace.total,
                dateModified: Date(),
                fileExtension: "",
                iconName: "internaldrive.fill",
                formattedSize: formatXPSize(bytes: rootSpace.total),
                typeDescription: "Local Disk (C:)"
            )
        )

        // 2. User Home / Personal Documents
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let homePath = homeURL.path
        items.append(
            FileItem(
                name: "User Documents",
                url: homeURL,
                path: homePath,
                isDirectory: true,
                isVolume: true,
                size: 0,
                dateModified: Date(),
                fileExtension: "",
                iconName: "folder.fill",
                formattedSize: "",
                typeDescription: "System Folder"
            )
        )

        // 3. Desktop
        if let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            items.append(
                FileItem(
                    name: "Desktop",
                    url: desktopURL,
                    path: desktopURL.path,
                    isDirectory: true,
                    isVolume: false,
                    size: 0,
                    dateModified: Date(),
                    fileExtension: "",
                    iconName: "display",
                    formattedSize: "",
                    typeDescription: "System Folder"
                )
            )
        }

        // 4. Mounted Volumes
        let volumesURL = URL(fileURLWithPath: "/Volumes")
        if let volContents = try? FileManager.default.contentsOfDirectory(
            at: volumesURL,
            includingPropertiesForKeys: [.isDirectoryKey, .isVolumeKey, .volumeTotalCapacityKey],
            options: [.skipsHiddenFiles]
        ) {
            for vol in volContents {
                if vol.lastPathComponent != "Macintosh HD" && vol.lastPathComponent != "/" {
                    let space = diskSpace(for: vol.path)
                    items.append(
                        FileItem(
                            name: vol.lastPathComponent,
                            url: vol,
                            path: vol.path,
                            isDirectory: true,
                            isVolume: true,
                            size: space.total,
                            dateModified: Date(),
                            fileExtension: "",
                            iconName: "externaldrive.fill",
                            formattedSize: formatXPSize(bytes: space.total),
                            typeDescription: "Removable Disk"
                        )
                    )
                }
            }
        }

        return items
    }

    public func contentsOfDirectory(at path: String, showHidden: Bool = false) throws -> [FileItem] {
        let resolved = resolvePath(path)
        if resolved == "computer://" {
            return myComputerDrives()
        }

        let directoryURL = URL(fileURLWithPath: resolved)
        let resourceKeys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .fileSizeKey,
            .contentModificationDateKey,
            .creationDateKey,
            .isPackageKey
        ]

        var options: FileManager.DirectoryEnumerationOptions = []
        if !showHidden {
            options.insert(.skipsHiddenFiles)
        }

        let urls = try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: Array(resourceKeys),
            options: options
        )

        var items: [FileItem] = []

        for url in urls {
            let values = try? url.resourceValues(forKeys: resourceKeys)
            let isDir = values?.isDirectory ?? false
            let isPackage = values?.isPackage ?? false
            let size = Int64(values?.fileSize ?? 0)
            let dateMod = values?.contentModificationDate ?? Date()
            let ext = url.pathExtension.lowercased()
            let name = url.lastPathComponent

            let itemIsDir = isDir && !isPackage
            let icon = iconName(forExtension: ext, isDirectory: itemIsDir, isVolume: false)
            let typeDesc = typeDescription(forExtension: ext, isDirectory: itemIsDir)
            let formatted = itemIsDir ? "" : formatXPSize(bytes: size)

            let item = FileItem(
                name: name,
                url: url,
                path: url.path,
                isDirectory: itemIsDir,
                isVolume: false,
                size: size,
                dateModified: dateMod,
                fileExtension: ext,
                iconName: icon,
                formattedSize: formatted,
                typeDescription: typeDesc
            )
            items.append(item)
        }

        // Sort folders first, then alphabetically
        items.sort { a, b in
            if a.isDirectory != b.isDirectory {
                return a.isDirectory && !b.isDirectory
            }
            return a.name.localizedStandardCompare(b.name) == .orderedAscending
        }

        return items
    }

    // MARK: - File Operations

    @discardableResult
    public func createFolder(at parentPath: String, name: String? = nil) throws -> FileItem {
        let resolved = resolvePath(parentPath)
        let parentURL = URL(fileURLWithPath: resolved)
        let baseName = name ?? "New Folder"
        let folderName = uniqueName(in: parentURL, baseName: baseName, ext: "")
        let folderURL = parentURL.appendingPathComponent(folderName)

        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

        return FileItem(
            name: folderName,
            url: folderURL,
            path: folderURL.path,
            isDirectory: true,
            isVolume: false,
            size: 0,
            dateModified: Date(),
            fileExtension: "",
            iconName: "folder.fill",
            formattedSize: "",
            typeDescription: "File Folder"
        )
    }

    @discardableResult
    public func createTextDocument(at parentPath: String, name: String? = nil) throws -> FileItem {
        let resolved = resolvePath(parentPath)
        let parentURL = URL(fileURLWithPath: resolved)
        let fullBase = name ?? "New Text Document.txt"
        let base = (fullBase as NSString).deletingPathExtension
        let ext = (fullBase as NSString).pathExtension.isEmpty ? "txt" : (fullBase as NSString).pathExtension

        let fileName = uniqueName(in: parentURL, baseName: base, ext: ".\(ext)")
        let fileURL = parentURL.appendingPathComponent(fileName)

        try "".write(to: fileURL, atomically: true, encoding: .utf8)

        return FileItem(
            name: fileName,
            url: fileURL,
            path: fileURL.path,
            isDirectory: false,
            isVolume: false,
            size: 0,
            dateModified: Date(),
            fileExtension: ext,
            iconName: "doc.text.fill",
            formattedSize: "0 KB",
            typeDescription: "Text Document"
        )
    }

    @discardableResult
    public func renameItem(at path: String, newName: String) throws -> FileItem {
        let resolved = resolvePath(path)
        let oldURL = URL(fileURLWithPath: resolved)
        let parentURL = oldURL.deletingLastPathComponent()
        let cleanName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            throw NSError(domain: "FileSystemService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid file name"])
        }

        let newURL = parentURL.appendingPathComponent(cleanName)
        try FileManager.default.moveItem(at: oldURL, to: newURL)

        let isDir = (try? newURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
        let ext = newURL.pathExtension.lowercased()

        return FileItem(
            name: cleanName,
            url: newURL,
            path: newURL.path,
            isDirectory: isDir,
            isVolume: false,
            size: 0,
            dateModified: Date(),
            fileExtension: ext,
            iconName: iconName(forExtension: ext, isDirectory: isDir, isVolume: false),
            formattedSize: isDir ? "" : "0 KB",
            typeDescription: typeDescription(forExtension: ext, isDirectory: isDir)
        )
    }

    public func deleteItem(at path: String) throws {
        let resolved = resolvePath(path)
        let fileURL = URL(fileURLWithPath: resolved)

        #if os(macOS)
        var trashURL: NSURL?
        do {
            try FileManager.default.trashItem(at: fileURL, resultingItemURL: &trashURL)
        } catch {
            // If trash item fails, try hard remove
            try FileManager.default.removeItem(at: fileURL)
        }
        #else
        try FileManager.default.removeItem(at: fileURL)
        #endif
    }

    public func itemProperties(for path: String) -> FileItemProperties {
        let resolved = resolvePath(path)
        let url = URL(fileURLWithPath: resolved)
        let name = url.lastPathComponent
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey, .creationDateKey])

        let isDir = values?.isDirectory ?? false
        let size = Int64(values?.fileSize ?? 0)
        let dateMod = values?.contentModificationDate ?? Date()
        let dateCreated = values?.creationDate
        let ext = url.pathExtension.lowercased()

        return FileItemProperties(
            name: name.isEmpty ? resolved : name,
            path: resolved,
            isDirectory: isDir,
            size: size,
            formattedSize: isDir ? "" : formatXPSize(bytes: size),
            dateCreated: dateCreated,
            dateModified: dateMod,
            typeDescription: typeDescription(forExtension: ext, isDirectory: isDir),
            isReadOnly: !FileManager.default.isWritableFile(atPath: resolved),
            isHidden: name.hasPrefix(".")
        )
    }

    // MARK: - Open Dispatch

    public func openItem(_ item: FileItem, windowManager: WindowManager?) {
        if item.isDirectory {
            windowManager?.openWindow(appType: .explorer(path: item.path), title: item.name)
            return
        }

        let ext = item.fileExtension.lowercased()
        let textExtensions: Set<String> = ["txt", "md", "json", "swift", "c", "h", "cpp", "py", "sh", "zsh", "js", "ts", "html", "css", "xml", "log", "ini", "yaml", "yml", "csv"]

        if textExtensions.contains(ext) {
            windowManager?.openWindow(appType: .notepad(fileURL: item.url), title: "\(item.name) - Notepad")
        } else {
            #if os(macOS)
            NSWorkspace.shared.open(item.url)
            #endif
        }
    }

    // MARK: - Formatters & Helpers

    public func formatXPSize(bytes: Int64) -> String {
        if bytes == 0 {
            return "0 KB"
        }
        if bytes < 1024 {
            return "1 KB"
        }
        let kb = Double(bytes) / 1024.0
        if kb < 1024.0 {
            return "\(Int(ceil(kb))) KB"
        }
        let mb = kb / 1024.0
        if mb < 1024.0 {
            return String(format: "%.2f MB", mb)
        }
        let gb = mb / 1024.0
        return String(format: "%.2f GB", gb)
    }

    public func typeDescription(forExtension ext: String, isDirectory: Bool) -> String {
        if isDirectory {
            return "File Folder"
        }
        switch ext.lowercased() {
        case "txt": return "Text Document"
        case "swift": return "Swift Source File"
        case "json": return "JSON Document"
        case "md": return "Markdown Document"
        case "png": return "PNG Image"
        case "jpg", "jpeg": return "JPEG Image"
        case "gif": return "GIF Image"
        case "bmp": return "Bitmap Image"
        case "pdf": return "PDF Document"
        case "app": return "Application"
        case "zip": return "Compressed (zipped) Folder"
        case "mp3", "m4a", "wav": return "Audio Track"
        case "mp4", "mov", "avi": return "Video Clip"
        case "sh", "zsh", "bash": return "Shell Script"
        case "html", "htm": return "HTML Document"
        case "css": return "Cascading Style Sheet"
        case "js", "ts": return "JavaScript Source File"
        case "py": return "Python Script"
        default:
            return ext.isEmpty ? "File" : "\(ext.uppercased()) File"
        }
    }

    public func iconName(forExtension ext: String, isDirectory: Bool, isVolume: Bool) -> String {
        if isVolume {
            return "internaldrive.fill"
        }
        if isDirectory {
            return "folder.fill"
        }
        switch ext.lowercased() {
        case "txt", "md", "log", "ini": return "doc.text.fill"
        case "swift", "c", "h", "cpp", "py", "js", "ts", "sh", "zsh": return "chevron.left.forwardslash.chevron.right"
        case "png", "jpg", "jpeg", "gif", "bmp", "tiff", "heic": return "photo.fill"
        case "mp3", "m4a", "wav", "aac", "flac": return "music.note"
        case "mp4", "mov", "avi", "mkv": return "film.fill"
        case "pdf": return "doc.richtext.fill"
        case "zip", "tar", "gz", "rar", "7z": return "archivebox.fill"
        case "app": return "app.dashed"
        case "dmg", "iso": return "opticaldisc.fill"
        default: return "doc.fill"
        }
    }

    public func diskSpace(for path: String) -> (free: Int64, total: Int64) {
        let resolved = resolvePath(path)
        let checkPath = resolved == "computer://" ? "/" : resolved

        #if os(macOS)
        do {
            let values = try URL(fileURLWithPath: checkPath).resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey])
            let free = values.volumeAvailableCapacityForImportantUsage ?? 0
            let total = Int64(values.volumeTotalCapacity ?? 0)
            return (free: free, total: total)
        } catch {
            return (free: 100 * 1024 * 1024 * 1024, total: 500 * 1024 * 1024 * 1024)
        }
        #else
        return (free: 100 * 1024 * 1024 * 1024, total: 500 * 1024 * 1024 * 1024)
        #endif
    }

    private func uniqueName(in directory: URL, baseName: String, ext: String) -> String {
        var candidate = "\(baseName)\(ext)"
        var counter = 2
        var targetURL = directory.appendingPathComponent(candidate)

        while FileManager.default.fileExists(atPath: targetURL.path) {
            candidate = "\(baseName) (\(counter))\(ext)"
            targetURL = directory.appendingPathComponent(candidate)
            counter += 1
        }
        return candidate
    }
}
