import Foundation
import SwiftUI

public class ExplorerClipboard: ObservableObject {
    public static let shared = ExplorerClipboard()

    @Published public var items: [FileItem] = []
    @Published public var isCut: Bool = false

    public init() {}

    public var hasContent: Bool {
        !items.isEmpty
    }

    public func copy(items: [FileItem]) {
        self.items = items
        self.isCut = false
    }

    public func cut(items: [FileItem]) {
        self.items = items
        self.isCut = true
    }

    public func paste(toDestinationPath destPath: String) {
        guard !items.isEmpty else { return }
        let fm = FileManager.default
        let targetDir = destPath.hasPrefix("computer://") ? NSHomeDirectory() : destPath

        for item in items {
            let destURL = URL(fileURLWithPath: targetDir).appendingPathComponent(item.name)
            do {
                if isCut {
                    try fm.moveItem(at: item.url, to: destURL)
                } else {
                    // Duplicate/Copy
                    if fm.fileExists(atPath: destURL.path) {
                        let baseName = item.url.deletingPathExtension().lastPathComponent
                        let ext = item.url.pathExtension
                        let extDot = ext.isEmpty ? "" : ".\(ext)"
                        let copyURL = URL(fileURLWithPath: targetDir).appendingPathComponent("Copy of \(baseName)\(extDot)")
                        try fm.copyItem(at: item.url, to: copyURL)
                    } else {
                        try fm.copyItem(at: item.url, to: destURL)
                    }
                }
            } catch {
                // error logged or ignored
            }
        }

        if isCut {
            items.removeAll()
            isCut = false
        }
    }
}
