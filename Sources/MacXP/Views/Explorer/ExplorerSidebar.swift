import SwiftUI

public struct ExplorerSidebar: View {
    public var currentPath: String
    public var selectedItems: [FileItem]
    public var onNavigate: (String) -> Void
    public var onNewFolder: () -> Void
    public var onRenameSelected: () -> Void
    public var onDeleteSelected: () -> Void

    @State private var isTasksExpanded: Bool = true
    @State private var isPlacesExpanded: Bool = true
    @State private var isDetailsExpanded: Bool = true

    public init(
        currentPath: String,
        selectedItems: [FileItem],
        onNavigate: @escaping (String) -> Void,
        onNewFolder: @escaping () -> Void,
        onRenameSelected: @escaping () -> Void,
        onDeleteSelected: @escaping () -> Void
    ) {
        self.currentPath = currentPath
        self.selectedItems = selectedItems
        self.onNavigate = onNavigate
        self.onNewFolder = onNewFolder
        self.onRenameSelected = onRenameSelected
        self.onDeleteSelected = onDeleteSelected
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 12) {
                // 1. File and Folder Tasks
                taskSection(
                    title: tasksHeaderTitle,
                    isExpanded: $isTasksExpanded
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        if selectedItems.count == 1 {
                            taskActionLink(title: "Rename this \(selectedItems[0].isDirectory ? "folder" : "file")", icon: "pencil") {
                                onRenameSelected()
                            }
                            taskActionLink(title: "Copy this \(selectedItems[0].isDirectory ? "folder" : "file")", icon: "doc.on.doc") {
                                // Copy
                            }
                            taskActionLink(title: "Delete this \(selectedItems[0].isDirectory ? "folder" : "file")", icon: "trash.fill", color: Color(red: 0.85, green: 0.25, blue: 0.20)) {
                                onDeleteSelected()
                            }
                        } else if selectedItems.count > 1 {
                            taskActionLink(title: "Copy selected items", icon: "doc.on.doc") {
                                // Copy
                            }
                            taskActionLink(title: "Delete selected items", icon: "trash.fill", color: Color(red: 0.85, green: 0.25, blue: 0.20)) {
                                onDeleteSelected()
                            }
                        } else {
                            taskActionLink(title: "Make a new folder", icon: "folder.badge.plus") {
                                onNewFolder()
                            }
                            taskActionLink(title: "Publish this folder to the Web", icon: "globe") {
                                // Web publish placeholder
                            }
                            taskActionLink(title: "Share this folder", icon: "person.2.fill") {
                                // Share placeholder
                            }
                        }
                    }
                    .padding(8)
                }

                // 2. Other Places
                taskSection(
                    title: "Other Places",
                    isExpanded: $isPlacesExpanded
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        taskActionLink(title: "My Computer", icon: "desktopcomputer") {
                            onNavigate("computer://")
                        }
                        taskActionLink(title: "My Documents", icon: "folder.fill") {
                            let docs = (FileManager.default.homeDirectoryForCurrentUser.path as NSString).appendingPathComponent("Documents")
                            onNavigate(docs)
                        }
                        taskActionLink(title: "Shared Documents", icon: "externaldrive.fill") {
                            onNavigate("/Users/Shared")
                        }
                        taskActionLink(title: "Desktop", icon: "display") {
                            let dt = (FileManager.default.homeDirectoryForCurrentUser.path as NSString).appendingPathComponent("Desktop")
                            onNavigate(dt)
                        }
                    }
                    .padding(8)
                }

                // 3. Details Pane
                taskSection(
                    title: "Details",
                    isExpanded: $isDetailsExpanded
                ) {
                    detailsContent
                        .padding(8)
                }
            }
            .padding(10)
        }
        .frame(width: 200)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.45, green: 0.60, blue: 0.85),
                    Color(red: 0.38, green: 0.52, blue: 0.78)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var tasksHeaderTitle: String {
        if currentPath == "computer://" {
            return "System Tasks"
        }
        return "File and Folder Tasks"
    }

    private func taskSection<Content: View>(
        title: String,
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isExpanded.wrappedValue.toggle()
                }
            }) {
                HStack {
                    Text(title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.10, green: 0.25, blue: 0.60))

                    Spacer()

                    // XP Collapse Chevron Circle
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 16, height: 16)
                        Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Color(red: 0.20, green: 0.40, blue: 0.80))
                    }
                }
                .padding(.horizontal, 8)
                .frame(height: 24)
                .background(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.85, green: 0.90, blue: 0.98)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(TopRoundedRectangle(radius: 4))
            }
            .buttonStyle(PlainButtonStyle())

            // Body
            if isExpanded.wrappedValue {
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.85, green: 0.90, blue: 0.98))
                    .overlay(
                        Rectangle()
                            .strokeBorder(Color(red: 0.75, green: 0.82, blue: 0.93), lineWidth: 1)
                    )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
    }

    private func taskActionLink(
        title: String,
        icon: String,
        color: Color = Color(red: 0.15, green: 0.35, blue: 0.75),
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(color)
                    .frame(width: 14)

                Text(title)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Color(red: 0.05, green: 0.20, blue: 0.55))
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var detailsContent: some View {
        if let first = selectedItems.first {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: first.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.20))

                    Text(first.name)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.black)
                        .lineLimit(2)
                }

                Divider()

                Text(first.typeDescription)
                    .font(.system(size: 10))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))

                if !first.isDirectory && !first.formattedSize.isEmpty {
                    Text("Size: \(first.formattedSize)")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                }

                Text("Modified: \(formattedDate(first.dateModified))")
                    .font(.system(size: 9))
                    .foregroundColor(Color.gray)
            }
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text(currentPath == "computer://" ? "My Computer" : (currentPath as NSString).lastPathComponent)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.black)

                Text(currentPath == "computer://" ? "System Folder" : "File Folder")
                    .font(.system(size: 10))
                    .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))

                let space = FileSystemService.shared.diskSpace(for: currentPath)
                Text("Free Space: \(FileSystemService.shared.formatXPSize(bytes: space.free))")
                    .font(.system(size: 9))
                    .foregroundColor(Color.gray)
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
