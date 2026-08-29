import SwiftUI
import Foundation

public struct FolderTreeNode: Identifiable, Equatable {
    public let id: String
    public var title: String
    public var path: String
    public var iconName: String
    public var isExpandable: Bool
    public var isExpanded: Bool
    public var children: [FolderTreeNode]

    public init(
        id: String,
        title: String,
        path: String,
        iconName: String,
        isExpandable: Bool = false,
        isExpanded: Bool = false,
        children: [FolderTreeNode] = []
    ) {
        self.id = id
        self.title = title
        self.path = path
        self.iconName = iconName
        self.isExpandable = isExpandable
        self.isExpanded = isExpanded
        self.children = children
    }
}

public class FolderTreeService {
    public static let shared = FolderTreeService()

    public func getRootNodes() -> [FolderTreeNode] {
        let home = NSHomeDirectory()
        let username = NSUserName()

        let userDirs: [FolderTreeNode] = [
            FolderTreeNode(id: "user-desktop", title: "Desktop", path: (home as NSString).appendingPathComponent("Desktop"), iconName: "display"),
            FolderTreeNode(id: "user-docs", title: "My Documents", path: (home as NSString).appendingPathComponent("Documents"), iconName: "folder.fill"),
            FolderTreeNode(id: "user-downloads", title: "Downloads", path: (home as NSString).appendingPathComponent("Downloads"), iconName: "arrow.down.circle.fill"),
            FolderTreeNode(id: "user-music", title: "My Music", path: (home as NSString).appendingPathComponent("Music"), iconName: "music.note.list"),
            FolderTreeNode(id: "user-pictures", title: "My Pictures", path: (home as NSString).appendingPathComponent("Pictures"), iconName: "photo.fill.on.rectangle.fill")
        ]

        let cDriveChildren: [FolderTreeNode] = [
            FolderTreeNode(id: "c-apps", title: "Applications", path: "/Applications", iconName: "folder.fill"),
            FolderTreeNode(id: "c-library", title: "Library", path: "/Library", iconName: "folder.fill"),
            FolderTreeNode(id: "c-system", title: "System", path: "/System", iconName: "folder.fill"),
            FolderTreeNode(id: "c-users", title: "Users", path: "/Users", iconName: "folder.fill", isExpandable: true, isExpanded: true, children: [
                FolderTreeNode(id: "user-\(username)", title: username, path: home, iconName: "person.crop.circle.fill", isExpandable: true, isExpanded: true, children: userDirs)
            ])
        ]

        let myComputerChildren: [FolderTreeNode] = [
            FolderTreeNode(id: "floppy-a", title: "3½ Floppy (A:)", path: "floppy://", iconName: "opticaldiscdrive"),
            FolderTreeNode(id: "disk-c", title: "Local Disk (C:)", path: "/", iconName: "internaldrive.fill", isExpandable: true, isExpanded: true, children: cDriveChildren),
            FolderTreeNode(id: "cd-d", title: "CD Drive (D:)", path: "cdrom://", iconName: "opticaldisc"),
            FolderTreeNode(id: "ctrl-panel", title: "Control Panel", path: "control://", iconName: "gearshape.fill")
        ]

        return [
            FolderTreeNode(
                id: "root-desktop",
                title: "Desktop",
                path: (home as NSString).appendingPathComponent("Desktop"),
                iconName: "display",
                isExpandable: true,
                isExpanded: true,
                children: [
                    FolderTreeNode(id: "root-mydocs", title: "My Documents", path: (home as NSString).appendingPathComponent("Documents"), iconName: "folder.fill"),
                    FolderTreeNode(id: "root-computer", title: "My Computer", path: "computer://", iconName: "desktopcomputer", isExpandable: true, isExpanded: true, children: myComputerChildren),
                    FolderTreeNode(id: "root-network", title: "My Network Places", path: "network://", iconName: "network"),
                    FolderTreeNode(id: "root-recycle", title: "Recycle Bin", path: "trash://", iconName: "trash.fill")
                ]
            )
        ]
    }
}

public struct FolderTreeView: View {
    public var currentPath: String
    public var onNavigate: (String) -> Void
    @State private var rootNodes: [FolderTreeNode] = []
    @State private var expandedIDs: Set<String> = ["root-desktop", "root-computer", "disk-c", "c-users", "user-" + NSUserName()]

    public init(currentPath: String, onNavigate: @escaping (String) -> Void) {
        self.currentPath = currentPath
        self.onNavigate = onNavigate
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Folders")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.12, green: 0.25, blue: 0.55))
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.85, green: 0.90, blue: 0.98), Color(red: 0.72, green: 0.80, blue: 0.94)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Tree Scrollable View
            ScrollView([.vertical, .horizontal], showsIndicators: true) {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(rootNodes) { node in
                        TreeNodeRowView(
                            node: node,
                            level: 0,
                            currentPath: currentPath,
                            expandedIDs: $expandedIDs,
                            onNavigate: onNavigate
                        )
                    }
                }
                .padding(6)
            }
            .background(Color.white)
        }
        .frame(width: 210)
        .onAppear {
            rootNodes = FolderTreeService.shared.getRootNodes()
        }
    }
}

public struct TreeNodeRowView: View {
    public var node: FolderTreeNode
    public var level: Int
    public var currentPath: String
    @Binding public var expandedIDs: Set<String>
    public var onNavigate: (String) -> Void

    public var body: some View {
        let isExpanded = expandedIDs.contains(node.id)
        let isSelected = currentPath == node.path

        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                // Indentation
                if level > 0 {
                    Spacer()
                        .frame(width: CGFloat(level * 14))
                }

                // Expand/Collapse Button
                if node.isExpandable || !node.children.isEmpty {
                    Button(action: {
                        if isExpanded {
                            expandedIDs.remove(node.id)
                        } else {
                            expandedIDs.insert(node.id)
                        }
                    }) {
                        Image(systemName: isExpanded ? "minus.square" : "plus.square")
                            .font(.system(size: 10))
                            .foregroundColor(Color.gray)
                            .frame(width: 12, height: 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Spacer()
                        .frame(width: 12)
                }

                // Node Icon
                Image(systemName: node.iconName)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .white : Color(red: 0.92, green: 0.70, blue: 0.20))
                    .frame(width: 14)

                // Node Label
                Text(node.title)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .white : .black)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 4)
            .background(isSelected ? Color(red: 0.19, green: 0.42, blue: 0.77) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                onNavigate(node.path)
            }

            // Children
            if isExpanded {
                ForEach(node.children) { child in
                    TreeNodeRowView(
                        node: child,
                        level: level + 1,
                        currentPath: currentPath,
                        expandedIDs: $expandedIDs,
                        onNavigate: onNavigate
                    )
                }
            }
        }
    }
}
