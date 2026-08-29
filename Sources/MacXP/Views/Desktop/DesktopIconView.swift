import SwiftUI

public enum ArrangeOption: Equatable {
    case name
    case size
    case type
    case modified
}

public struct DesktopIconItem: Identifiable, Equatable {
    public let id: UUID
    public var title: String
    public var iconName: String
    public var isSystem: Bool
    public var appType: XPAppType?
    public var fileURL: URL?
    public var position: CGPoint
    public var isSelected: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        iconName: String,
        isSystem: Bool = false,
        appType: XPAppType? = nil,
        fileURL: URL? = nil,
        position: CGPoint = .zero,
        isSelected: Bool = false
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.isSystem = isSystem
        self.appType = appType
        self.fileURL = fileURL
        self.position = position
        self.isSelected = isSelected
    }
}

public class DesktopManager: ObservableObject {
    public static let shared = DesktopManager()
    @Published public var icons: [DesktopIconItem] = []
    @Published public var selectedIconIDs: Set<UUID> = []
    @Published public var selectedWallpaper: String = "Bliss (Windows XP Standard)"

    public init() {
        loadDefaultIcons()
        loadDesktopFiles()
    }

    public func loadDefaultIcons() {
        #if os(macOS)
        let homeDir = NSHomeDirectory()
        let docsPath = (homeDir as NSString).appendingPathComponent("Documents")
        let trashPath = (homeDir as NSString).appendingPathComponent(".Trash")
        #else
        let docsPath = "/Documents"
        let trashPath = "/.Trash"
        #endif

        icons = [
            DesktopIconItem(
                title: "My Computer",
                iconName: "desktopcomputer",
                isSystem: true,
                appType: .explorer(path: "/"),
                position: CGPoint(x: 20, y: 20)
            ),
            DesktopIconItem(
                title: "My Documents",
                iconName: "folder.fill",
                isSystem: true,
                appType: .explorer(path: docsPath),
                position: CGPoint(x: 20, y: 110)
            ),
            DesktopIconItem(
                title: "Recycle Bin",
                iconName: "trash.fill",
                isSystem: true,
                appType: .explorer(path: trashPath),
                position: CGPoint(x: 20, y: 200)
            ),
            DesktopIconItem(
                title: "Internet Explorer",
                iconName: "globe",
                isSystem: true,
                appType: .explorer(path: "https://www.google.com"),
                position: CGPoint(x: 20, y: 290)
            )
        ]
    }

    public func loadDesktopFiles() {
        #if os(macOS)
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
        guard let desktopURL = desktopURL else { return }

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: desktopURL,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )

            var currentY: CGFloat = 380
            var currentX: CGFloat = 20

            for url in fileURLs {
                let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                let icon = isDir ? "folder.fill" : "doc.text.fill"
                let title = url.lastPathComponent

                let item = DesktopIconItem(
                    title: title,
                    iconName: icon,
                    isSystem: false,
                    appType: isDir ? .explorer(path: url.path) : .notepad(fileURL: url),
                    fileURL: url,
                    position: CGPoint(x: currentX, y: currentY)
                )
                icons.append(item)

                currentY += 90
                if currentY > 600 {
                    currentY = 20
                    currentX += 90
                }
            }
        } catch {
            // Silently fallback if desktop access is restricted
        }
        #endif
    }

    public func selectIcon(id: UUID, exclusive: Bool = true) {
        if exclusive {
            selectedIconIDs = [id]
        } else {
            if selectedIconIDs.contains(id) {
                selectedIconIDs.remove(id)
            } else {
                selectedIconIDs.insert(id)
            }
        }
    }

    public func isIconSelected(id: UUID) -> Bool {
        selectedIconIDs.contains(id)
    }

    public func clearSelection() {
        selectedIconIDs.removeAll()
    }

    public func selectIconsInMarquee(marqueeRect: CGRect, itemSize: CGSize = CGSize(width: 75, height: 75)) {
        selectedIconIDs.removeAll()

        for icon in icons {
            let iconRect = CGRect(
                x: icon.position.x,
                y: icon.position.y,
                width: itemSize.width,
                height: itemSize.height
            )

            if marqueeRect.intersects(iconRect) {
                selectedIconIDs.insert(icon.id)
            }
        }
    }

    public func arrangeIcons(by option: ArrangeOption, desktopHeight: CGFloat = 700) {
        switch option {
        case .name:
            icons.sort { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case .size, .type, .modified:
            // Sort system icons first, then by title
            icons.sort {
                if $0.isSystem != $1.isSystem {
                    return $0.isSystem && !$1.isSystem
                }
                return $0.title.localizedStandardCompare($1.title) == .orderedAscending
            }
        }

        // Layout in vertical grid columns
        var startX: CGFloat = 20
        var startY: CGFloat = 20
        let itemHeight: CGFloat = 90
        let itemWidth: CGFloat = 90

        for i in 0..<icons.count {
            icons[i].position = CGPoint(x: startX, y: startY)
            startY += itemHeight
            if startY + itemHeight > desktopHeight - 40 {
                startY = 20
                startX += itemWidth
            }
        }
    }

    @discardableResult
    public func createNewFolder() -> DesktopIconItem {
        let title = generateUniqueTitle(base: "New Folder")
        let item = DesktopIconItem(
            title: title,
            iconName: "folder.fill",
            isSystem: false,
            appType: .explorer(path: ""),
            position: nextAvailablePosition()
        )
        icons.append(item)
        return item
    }

    @discardableResult
    public func createNewTextDocument() -> DesktopIconItem {
        let title = generateUniqueTitle(base: "New Text Document", ext: ".txt")
        let item = DesktopIconItem(
            title: title,
            iconName: "doc.text.fill",
            isSystem: false,
            appType: .notepad(fileURL: nil),
            position: nextAvailablePosition()
        )
        icons.append(item)
        return item
    }

    public func refresh() {
        loadDefaultIcons()
        loadDesktopFiles()
    }

    private func generateUniqueTitle(base: String, ext: String = "") -> String {
        var name = "\(base)\(ext)"
        var counter = 2
        while icons.contains(where: { $0.title == name }) {
            name = "\(base) (\(counter))\(ext)"
            counter += 1
        }
        return name
    }

    private func nextAvailablePosition() -> CGPoint {
        let lastY = icons.map(\.position.y).max() ?? 20
        let lastX = icons.map(\.position.x).max() ?? 20
        if lastY + 90 > 600 {
            return CGPoint(x: lastX + 90, y: 20)
        } else {
            return CGPoint(x: 20, y: lastY + 90)
        }
    }
}

public struct DesktopIconView: View {
    public let item: DesktopIconItem
    public let isSelected: Bool
    public let onSelect: (Bool) -> Void
    public let onOpen: () -> Void
    public var onDragPosition: ((CGPoint) -> Void)?

    @State private var dragOffset: CGSize = .zero

    public init(
        item: DesktopIconItem,
        isSelected: Bool,
        onSelect: @escaping (Bool) -> Void,
        onOpen: @escaping () -> Void,
        onDragPosition: ((CGPoint) -> Void)? = nil
    ) {
        self.item = item
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.onOpen = onOpen
        self.onDragPosition = onDragPosition
    }

    public var body: some View {
        VStack(spacing: 4) {
            // Icon
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.19, green: 0.42, blue: 0.77).opacity(0.4))
                        .frame(width: 44, height: 44)
                }

                Image(systemName: item.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(iconColor)
                    .shadow(color: Color.black.opacity(0.6), radius: 1.5, x: 1, y: 1)
            }
            .frame(width: 48, height: 44)

            // Label
            Text(item.title)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(
                    isSelected ?
                        Color(red: 0.19, green: 0.42, blue: 0.77) : // #316ac5
                        Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .shadow(
                    color: isSelected ? Color.clear : Color.black.opacity(0.85),
                    radius: 1.5,
                    x: 1,
                    y: 1
                )
        }
        .frame(width: 75, height: 75)
        .contentShape(Rectangle())
        .offset(dragOffset)
        .position(
            x: item.position.x + 37.5 + dragOffset.width,
            y: item.position.y + 37.5 + dragOffset.height
        )
        .onTapGesture(count: 2) {
            onOpen()
        }
        .onTapGesture(count: 1) {
            onSelect(false)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    let finalPos = CGPoint(
                        x: max(10, item.position.x + value.translation.width),
                        y: max(10, item.position.y + value.translation.height)
                    )
                    dragOffset = .zero
                    onDragPosition?(finalPos)
                }
        )
    }

    private var iconColor: Color {
        if item.iconName.contains("folder") {
            return Color(red: 0.98, green: 0.80, blue: 0.20) // Classic yellow folder
        } else if item.iconName.contains("trash") {
            return Color(red: 0.85, green: 0.85, blue: 0.90)
        } else if item.iconName.contains("globe") {
            return Color(red: 0.20, green: 0.60, blue: 0.95)
        } else if item.iconName.contains("desktopcomputer") {
            return Color(red: 0.80, green: 0.85, blue: 0.95)
        } else {
            return Color.white
        }
    }
}
