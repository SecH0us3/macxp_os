import SwiftUI

public enum ExplorerSortColumn: String, CaseIterable {
    case name = "Name"
    case size = "Size"
    case type = "Type"
    case dateModified = "Date Modified"
}

public struct ExplorerItemGrid: View {
    public var items: [FileItem]
    public var viewMode: ExplorerViewMode
    public var selectedIDs: Set<UUID>
    public var sortColumn: ExplorerSortColumn
    public var sortAscending: Bool
    public var renamingItemID: UUID?
    public var renamingText: Binding<String>

    public var onSelect: (FileItem, Bool) -> Void
    public var onOpen: (FileItem) -> Void
    public var onSort: (ExplorerSortColumn) -> Void
    public var onCommitRename: (FileItem, String) -> Void
    public var onCancelRename: () -> Void

    // Context menu actions
    public var onExplore: (FileItem) -> Void
    public var onOpenWithNotepad: (FileItem) -> Void
    public var onOpenWithDefaultApp: (FileItem) -> Void
    public var onDelete: (FileItem) -> Void
    public var onStartRename: (FileItem) -> Void
    public var onProperties: (FileItem) -> Void

    public init(
        items: [FileItem],
        viewMode: ExplorerViewMode,
        selectedIDs: Set<UUID>,
        sortColumn: ExplorerSortColumn,
        sortAscending: Bool,
        renamingItemID: UUID?,
        renamingText: Binding<String>,
        onSelect: @escaping (FileItem, Bool) -> Void,
        onOpen: @escaping (FileItem) -> Void,
        onSort: @escaping (ExplorerSortColumn) -> Void,
        onCommitRename: @escaping (FileItem, String) -> Void,
        onCancelRename: @escaping () -> Void,
        onExplore: @escaping (FileItem) -> Void,
        onOpenWithNotepad: @escaping (FileItem) -> Void,
        onOpenWithDefaultApp: @escaping (FileItem) -> Void,
        onDelete: @escaping (FileItem) -> Void,
        onStartRename: @escaping (FileItem) -> Void,
        onProperties: @escaping (FileItem) -> Void
    ) {
        self.items = items
        self.viewMode = viewMode
        self.selectedIDs = selectedIDs
        self.sortColumn = sortColumn
        self.sortAscending = sortAscending
        self.renamingItemID = renamingItemID
        self.renamingText = renamingText
        self.onSelect = onSelect
        self.onOpen = onOpen
        self.onSort = onSort
        self.onCommitRename = onCommitRename
        self.onCancelRename = onCancelRename
        self.onExplore = onExplore
        self.onOpenWithNotepad = onOpenWithNotepad
        self.onOpenWithDefaultApp = onOpenWithDefaultApp
        self.onDelete = onDelete
        self.onStartRename = onStartRename
        self.onProperties = onProperties
    }

    @ObservedObject public var folderOptions = FolderOptionsSettings.shared

    public var displayedFilteredItems: [FileItem] {
        if folderOptions.showHiddenFiles {
            return items
        }
        return items.filter { !$0.name.hasPrefix(".") }
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            Group {
                switch viewMode {
                case .thumbnails:
                    thumbnailsView
                case .tiles:
                    tilesView
                case .icons:
                    iconsView
                case .list:
                    listView
                case .details:
                    detailsView
                }
            }
            .padding(10)
        }
        .background(Color.white)
    }

    // MARK: - 1. Thumbnails View
    private var thumbnailsView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110, maximum: 130), spacing: 12)], spacing: 12) {
            ForEach(displayedFilteredItems) { item in
                let isSelected = selectedIDs.contains(item.id)
                let isRenaming = (renamingItemID == item.id)

                VStack(spacing: 6) {
                    // Preview Card Box (Classic XP Photo Frame)
                    ZStack {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white)
                            .frame(width: 96, height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(Color.gray.opacity(0.4), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.12), radius: 2, x: 1, y: 1)

                        if isImageFile(item), let img = NSImage(contentsOf: item.url) {
                            Image(nsImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: 88, maxHeight: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                        } else {
                            Image(systemName: item.iconName)
                                .font(.system(size: 38))
                                .foregroundColor(iconColor(for: item))
                        }
                    }

                    // Label / Rename
                    if isRenaming {
                        TextField("", text: renamingText, onCommit: {
                            onCommitRename(item, renamingText.wrappedValue)
                        })
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 11))
                        .padding(2)
                        .background(Color.white)
                        .border(Color(red: 0.19, green: 0.42, blue: 0.77), width: 1)
                    } else {
                        Text(displayName(for: item))
                            .font(.system(size: 11))
                            .foregroundColor(isSelected ? .white : .black)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(isSelected ? Color(red: 0.19, green: 0.42, blue: 0.77) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                }
                .frame(width: 110)
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    onOpen(item)
                }
                .onTapGesture(count: 1) {
                    onSelect(item, false)
                }
                .fileContextMenu(
                    item: item,
                    onOpen: { onOpen(item) },
                    onExplore: { onExplore(item) },
                    onOpenWithNotepad: { onOpenWithNotepad(item) },
                    onOpenWithDefaultApp: { onOpenWithDefaultApp(item) },
                    onDelete: { onDelete(item) },
                    onRename: { onStartRename(item) },
                    onProperties: { onProperties(item) }
                )
            }
        }
    }

    // MARK: - 2. Tiles View
    private var tilesView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 190, maximum: 260), spacing: 10)], spacing: 10) {
            ForEach(displayedFilteredItems) { item in
                let isSelected = selectedIDs.contains(item.id)
                let isRenaming = (renamingItemID == item.id)

                HStack(spacing: 8) {
                    Image(systemName: item.iconName)
                        .font(.system(size: 28))
                        .foregroundColor(iconColor(for: item))
                        .frame(width: 36, height: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        if isRenaming {
                            TextField("", text: renamingText, onCommit: {
                                onCommitRename(item, renamingText.wrappedValue)
                            })
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 11))
                            .background(Color.white)
                            .border(Color(red: 0.19, green: 0.42, blue: 0.77), width: 1)
                        } else {
                            Text(displayName(for: item))
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(isSelected ? .white : .black)
                                .lineLimit(1)
                        }

                        if item.isVolume || item.path == "/" {
                            // Authentic Drive Free Space Bar
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.formattedSize.isEmpty ? "Local Disk" : "Free Space: \(item.formattedSize)")
                                    .font(.system(size: 9))
                                    .foregroundColor(isSelected ? Color.white.opacity(0.85) : Color.gray)

                                ProgressView(value: 0.65)
                                    .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 0.20, green: 0.50, blue: 0.90)))
                                    .frame(width: 80, height: 4)
                            }
                        } else {
                            Text(item.isDirectory ? item.typeDescription : (item.formattedSize.isEmpty ? item.typeDescription : "\(item.typeDescription)\n\(item.formattedSize)"))
                                .font(.system(size: 10))
                                .foregroundColor(isSelected ? Color.white.opacity(0.85) : Color.gray)
                                .lineLimit(2)
                        }
                    }

                    Spacer()
                }
                .padding(4)
                .background(isSelected ? Color(red: 0.19, green: 0.42, blue: 0.77) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    onOpen(item)
                }
                .onTapGesture(count: 1) {
                    onSelect(item, false)
                }
                .fileContextMenu(
                    item: item,
                    onOpen: { onOpen(item) },
                    onExplore: { onExplore(item) },
                    onOpenWithNotepad: { onOpenWithNotepad(item) },
                    onOpenWithDefaultApp: { onOpenWithDefaultApp(item) },
                    onDelete: { onDelete(item) },
                    onRename: { onStartRename(item) },
                    onProperties: { onProperties(item) }
                )
            }
        }
    }

    private func isImageFile(_ item: FileItem) -> Bool {
        let exts = ["png", "jpg", "jpeg", "gif", "webp", "bmp", "icns", "tif", "tiff"]
        return exts.contains(item.fileExtension.lowercased())
    }

    private func displayName(for item: FileItem) -> String {
        if folderOptions.hideExtensions && !item.isDirectory && !item.fileExtension.isEmpty {
            return (item.name as NSString).deletingPathExtension
        }
        return item.name
    }

    // MARK: - 3. Icons View
    private var iconsView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80, maximum: 95), spacing: 10)], spacing: 10) {
            ForEach(displayedFilteredItems) { item in
                let isSelected = selectedIDs.contains(item.id)
                let isRenaming = (renamingItemID == item.id)

                VStack(spacing: 4) {
                    Image(systemName: item.iconName)
                        .font(.system(size: 32))
                        .foregroundColor(iconColor(for: item))
                        .frame(width: 44, height: 40)

                    if isRenaming {
                        TextField("", text: renamingText, onCommit: {
                            onCommitRename(item, renamingText.wrappedValue)
                        })
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 11))
                        .background(Color.white)
                        .border(Color(red: 0.19, green: 0.42, blue: 0.77), width: 1)
                    } else {
                        Text(displayName(for: item))
                            .font(.system(size: 11))
                            .foregroundColor(isSelected ? .white : .black)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(isSelected ? Color(red: 0.19, green: 0.42, blue: 0.77) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                }
                .frame(width: 85)
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    onOpen(item)
                }
                .onTapGesture(count: 1) {
                    onSelect(item, false)
                }
                .fileContextMenu(
                    item: item,
                    onOpen: { onOpen(item) },
                    onExplore: { onExplore(item) },
                    onOpenWithNotepad: { onOpenWithNotepad(item) },
                    onOpenWithDefaultApp: { onOpenWithDefaultApp(item) },
                    onDelete: { onDelete(item) },
                    onRename: { onStartRename(item) },
                    onProperties: { onProperties(item) }
                )
            }
        }
    }

    // MARK: - 4. List View
    private var listView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 6)], spacing: 4) {
            ForEach(displayedFilteredItems) { item in
                let isSelected = selectedIDs.contains(item.id)
                let isRenaming = (renamingItemID == item.id)

                HStack(spacing: 6) {
                    Image(systemName: item.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(iconColor(for: item))
                        .frame(width: 16, height: 16)

                    if isRenaming {
                        TextField("", text: renamingText, onCommit: {
                            onCommitRename(item, renamingText.wrappedValue)
                        })
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 11))
                        .background(Color.white)
                        .border(Color(red: 0.19, green: 0.42, blue: 0.77), width: 1)
                    } else {
                        Text(displayName(for: item))
                            .font(.system(size: 11))
                            .foregroundColor(isSelected ? .white : .black)
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(isSelected ? Color(red: 0.19, green: 0.42, blue: 0.77) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    onOpen(item)
                }
                .onTapGesture(count: 1) {
                    onSelect(item, false)
                }
                .fileContextMenu(
                    item: item,
                    onOpen: { onOpen(item) },
                    onExplore: { onExplore(item) },
                    onOpenWithNotepad: { onOpenWithNotepad(item) },
                    onOpenWithDefaultApp: { onOpenWithDefaultApp(item) },
                    onDelete: { onDelete(item) },
                    onRename: { onStartRename(item) },
                    onProperties: { onProperties(item) }
                )
            }
        }
    }

    // MARK: - 5. Details View (Table)
    private var detailsView: some View {
        VStack(spacing: 0) {
            // Header Row
            HStack(spacing: 0) {
                detailsHeader(title: "Name", column: .name, width: 220)
                detailsHeader(title: "Size", column: .size, width: 80, alignment: .trailing)
                detailsHeader(title: "Type", column: .type, width: 140)
                detailsHeader(title: "Date Modified", column: .dateModified, width: 150)
                Spacer()
            }
            .frame(height: 22)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.97, green: 0.97, blue: 0.98), Color(red: 0.88, green: 0.88, blue: 0.90)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75)),
                alignment: .bottom
            )

            // Rows
            VStack(spacing: 0) {
                ForEach(displayedFilteredItems) { item in
                    let isSelected = selectedIDs.contains(item.id)
                    let isRenaming = (renamingItemID == item.id)

                    HStack(spacing: 0) {
                        // Name column
                        HStack(spacing: 6) {
                            Image(systemName: item.iconName)
                                .font(.system(size: 14))
                                .foregroundColor(iconColor(for: item))
                                .frame(width: 16, height: 16)

                            if isRenaming {
                                TextField("", text: renamingText, onCommit: {
                                    onCommitRename(item, renamingText.wrappedValue)
                                })
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 11))
                                .background(Color.white)
                                .border(Color(red: 0.19, green: 0.42, blue: 0.77), width: 1)
                            } else {
                                Text(displayName(for: item))
                                    .font(.system(size: 11))
                                    .foregroundColor(isSelected ? .white : .black)
                                    .lineLimit(1)
                            }
                        }
                        .frame(width: 220, alignment: .leading)
                        .padding(.leading, 4)

                        // Size column
                        Text(item.isDirectory ? "" : item.formattedSize)
                            .font(.system(size: 11))
                            .foregroundColor(isSelected ? .white : Color(red: 0.2, green: 0.2, blue: 0.2))
                            .frame(width: 80, alignment: .trailing)
                            .padding(.trailing, 8)

                        // Type column
                        Text(item.typeDescription)
                            .font(.system(size: 11))
                            .foregroundColor(isSelected ? .white : Color(red: 0.2, green: 0.2, blue: 0.2))
                            .frame(width: 140, alignment: .leading)
                            .lineLimit(1)

                        // Date Modified column
                        Text(formattedDate(item.dateModified))
                            .font(.system(size: 11))
                            .foregroundColor(isSelected ? .white : Color(red: 0.3, green: 0.3, blue: 0.3))
                            .frame(width: 150, alignment: .leading)
                            .lineLimit(1)

                        Spacer()
                    }
                    .frame(height: 20)
                    .background(isSelected ? Color(red: 0.19, green: 0.42, blue: 0.77) : Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        onOpen(item)
                    }
                    .onTapGesture(count: 1) {
                        onSelect(item, false)
                    }
                    .fileContextMenu(
                        item: item,
                        onOpen: { onOpen(item) },
                        onExplore: { onExplore(item) },
                        onOpenWithNotepad: { onOpenWithNotepad(item) },
                        onOpenWithDefaultApp: { onOpenWithDefaultApp(item) },
                        onDelete: { onDelete(item) },
                        onRename: { onStartRename(item) },
                        onProperties: { onProperties(item) }
                    )
                }
            }
        }
    }

    private func detailsHeader(title: String, column: ExplorerSortColumn, width: CGFloat, alignment: Alignment = .leading) -> some View {
        Button(action: {
            onSort(column)
        }) {
            HStack(spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.black)

                if sortColumn == column {
                    Image(systemName: sortAscending ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                        .font(.system(size: 6))
                        .foregroundColor(Color.gray)
                }
            }
            .frame(width: width, alignment: alignment)
            .padding(.horizontal, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75)),
            alignment: .trailing
        )
    }

    private func iconColor(for item: FileItem) -> Color {
        if item.isVolume {
            return Color(red: 0.20, green: 0.50, blue: 0.85)
        }
        if item.isDirectory {
            return Color(red: 0.98, green: 0.80, blue: 0.20)
        }
        return Color(red: 0.30, green: 0.55, blue: 0.85)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
