import SwiftUI

public class ExplorerViewModel: ObservableObject {
    @Published public var state: ExplorerState
    @Published public var items: [FileItem] = []
    @Published public var selectedItemIDs: Set<UUID> = []
    @Published public var viewMode: ExplorerViewMode = .icons
    @Published public var sortColumn: ExplorerSortColumn = .name
    @Published public var sortAscending: Bool = true
    @Published public var isSidebarVisible: Bool = true
    @Published public var isSearchActive: Bool = false
    @Published public var isFolderTreeActive: Bool = false
    @Published public var searchCategory: SearchCategory = .allFiles
    @Published public var isSearchingRunning: Bool = false
    @Published public var isFolderOptionsOpen: Bool = false
    @Published public var searchQuery: String = ""
    @Published public var renamingItemID: UUID? = nil
    @Published public var renamingText: String = ""
    @Published public var isPropertiesOpen: Bool = false
    @Published public var propertiesItem: FileItem? = nil
    @Published public var errorMessage: String? = nil

    public init(initialPath: String = "computer://") {
        self.state = ExplorerState(initialPath: initialPath)
        loadDirectoryContents()
    }

    public var currentPath: String {
        state.currentPath
    }

    public var selectedItems: [FileItem] {
        items.filter { selectedItemIDs.contains($0.id) }
    }

    public var displayedItems: [FileItem] {
        var result = items
        if isSearchActive && !searchQuery.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }

        result.sort { a, b in
            // Folders always first unless sorting specifically
            if a.isDirectory != b.isDirectory {
                return a.isDirectory && !b.isDirectory
            }

            switch sortColumn {
            case .name:
                let comp = a.name.localizedStandardCompare(b.name)
                return sortAscending ? (comp == .orderedAscending) : (comp == .orderedDescending)
            case .size:
                return sortAscending ? (a.size < b.size) : (a.size > b.size)
            case .type:
                let comp = a.typeDescription.localizedStandardCompare(b.typeDescription)
                return sortAscending ? (comp == .orderedAscending) : (comp == .orderedDescending)
            case .dateModified:
                return sortAscending ? (a.dateModified < b.dateModified) : (a.dateModified > b.dateModified)
            }
        }
        return result
    }

    public func loadDirectoryContents() {
        do {
            items = try FileSystemService.shared.contentsOfDirectory(at: state.currentPath)
            selectedItemIDs.removeAll()
            renamingItemID = nil
        } catch {
            errorMessage = error.localizedDescription
            SoundManager.shared.play(.error)
            items = []
        }
    }

    public func navigateTo(path: String) {
        SoundManager.shared.play(.navigation)
        state.navigateTo(path: path)
        loadDirectoryContents()
    }

    public func goBack() {
        SoundManager.shared.play(.navigation)
        state.goBack()
        loadDirectoryContents()
    }

    public func goForward() {
        SoundManager.shared.play(.navigation)
        state.goForward()
        loadDirectoryContents()
    }

    public func goUp() {
        SoundManager.shared.play(.navigation)
        state.goUp()
        loadDirectoryContents()
    }

    public func selectItem(_ item: FileItem, exclusive: Bool = true) {
        if exclusive {
            selectedItemIDs = [item.id]
        } else {
            if selectedItemIDs.contains(item.id) {
                selectedItemIDs.remove(item.id)
            } else {
                selectedItemIDs.insert(item.id)
            }
        }
    }

    public func clearSelection() {
        selectedItemIDs.removeAll()
        renamingItemID = nil
    }

    public func selectAll() {
        selectedItemIDs = Set(items.map(\.id))
    }

    public func invertSelection() {
        let allIDs = Set(items.map(\.id))
        selectedItemIDs = allIDs.subtracting(selectedItemIDs)
    }

    public func toggleSort(column: ExplorerSortColumn) {
        if sortColumn == column {
            sortAscending.toggle()
        } else {
            sortColumn = column
            sortAscending = true
        }
    }

    public func createNewFolder() {
        guard state.currentPath != "computer://" else { return }
        do {
            let newFolder = try FileSystemService.shared.createFolder(at: state.currentPath)
            loadDirectoryContents()
            selectedItemIDs = [newFolder.id]
            startRenaming(item: newFolder)
        } catch {
            errorMessage = error.localizedDescription
            SoundManager.shared.play(.error)
        }
    }

    public func createNewTextDocument() {
        guard state.currentPath != "computer://" else { return }
        do {
            let newDoc = try FileSystemService.shared.createTextDocument(at: state.currentPath)
            loadDirectoryContents()
            selectedItemIDs = [newDoc.id]
            startRenaming(item: newDoc)
        } catch {
            errorMessage = error.localizedDescription
            SoundManager.shared.play(.error)
        }
    }

    public func startRenaming(item: FileItem) {
        renamingItemID = item.id
        renamingText = item.name
    }

    public func commitRename(item: FileItem, newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != item.name else {
            renamingItemID = nil
            return
        }

        do {
            _ = try FileSystemService.shared.renameItem(at: item.path, newName: trimmed)
            loadDirectoryContents()
        } catch {
            errorMessage = error.localizedDescription
            SoundManager.shared.play(.error)
        }
        renamingItemID = nil
    }

    public func cancelRename() {
        renamingItemID = nil
    }

    public func deleteSelectedItems() {
        let itemsToDelete = selectedItems
        for item in itemsToDelete {
            try? FileSystemService.shared.deleteItem(at: item.path)
        }
        if !itemsToDelete.isEmpty {
            SoundManager.shared.play(.recycleBin)
        }
        loadDirectoryContents()
    }

    public func showProperties(for item: FileItem? = nil) {
        if let item = item {
            propertiesItem = item
        } else if let first = selectedItems.first {
            propertiesItem = first
        } else {
            let prop = FileSystemService.shared.itemProperties(for: state.currentPath)
            propertiesItem = FileItem(
                name: prop.name,
                url: URL(fileURLWithPath: prop.path),
                path: prop.path,
                isDirectory: prop.isDirectory,
                size: prop.size,
                dateModified: prop.dateModified,
                typeDescription: prop.typeDescription
            )
        }
        isPropertiesOpen = true
    }

    public func toggleSearchCompanion() {
        withAnimation {
            isSearchActive.toggle()
            if isSearchActive {
                isFolderTreeActive = false
            }
        }
    }

    public func toggleFolderTree() {
        withAnimation {
            isFolderTreeActive.toggle()
            if isFolderTreeActive {
                isSearchActive = false
            }
        }
    }

    public func copySelectedItems() {
        ExplorerClipboard.shared.copy(items: selectedItems)
    }

    public func cutSelectedItems() {
        ExplorerClipboard.shared.cut(items: selectedItems)
    }

    public func pasteClipboard() {
        ExplorerClipboard.shared.paste(toDestinationPath: state.currentPath)
        loadDirectoryContents()
    }
}

public struct ExplorerWindowView: View {
    @ObservedObject public var windowManager: WindowManager
    public var window: XPWindowInstance?
    @StateObject public var viewModel: ExplorerViewModel

    public init(
        initialPath: String = "computer://",
        windowManager: WindowManager,
        window: XPWindowInstance? = nil
    ) {
        self.windowManager = windowManager
        self.window = window
        _viewModel = StateObject(wrappedValue: ExplorerViewModel(initialPath: initialPath))
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 1. Classic Windows XP Menu Bar (File, Edit, View, Favorites, Tools, Help)
                menuBarView

                // 2. Toolbar (Back, Forward, Up, Search, Folders, Views)
                ExplorerToolbar(
                    canGoBack: viewModel.state.canGoBack,
                    canGoForward: viewModel.state.canGoForward,
                    canGoUp: viewModel.state.canGoUp,
                    isFoldersActive: viewModel.isFolderTreeActive,
                    isSearchActive: viewModel.isSearchActive,
                    currentViewMode: viewModel.viewMode,
                    onBack: { viewModel.goBack() },
                    onForward: { viewModel.goForward() },
                    onUp: { viewModel.goUp() },
                    onSearch: {
                        viewModel.toggleSearchCompanion()
                    },
                    onToggleFolders: {
                        viewModel.toggleFolderTree()
                    },
                    onSelectViewMode: { mode in
                        viewModel.viewMode = mode
                    }
                )

                // 3. Address Bar
                ExplorerAddressBar(
                    currentPath: viewModel.currentPath,
                    onNavigate: { newPath in
                        viewModel.navigateTo(path: newPath)
                    }
                )

                // 4. Main Body: Left Sidebar (Search Companion / Folder Tree / Common Tasks) + Viewport
                HStack(spacing: 0) {
                    if viewModel.isSearchActive {
                        SearchCompanionView(viewModel: viewModel) { query in
                            viewModel.isSearchingRunning = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                viewModel.isSearchingRunning = false
                                viewModel.loadDirectoryContents()
                            }
                        }

                        Rectangle()
                            .frame(width: 1)
                            .foregroundColor(Color(red: 0.70, green: 0.75, blue: 0.85))
                    } else if viewModel.isFolderTreeActive {
                        FolderTreeView(currentPath: viewModel.currentPath) { newPath in
                            viewModel.navigateTo(path: newPath)
                        }

                        Rectangle()
                            .frame(width: 1)
                            .foregroundColor(Color(red: 0.70, green: 0.75, blue: 0.85))
                    } else if viewModel.isSidebarVisible {
                        ExplorerSidebar(
                            currentPath: viewModel.currentPath,
                            selectedItems: viewModel.selectedItems,
                            onNavigate: { path in
                                viewModel.navigateTo(path: path)
                            },
                            onNewFolder: {
                                viewModel.createNewFolder()
                            },
                            onRenameSelected: {
                                if let first = viewModel.selectedItems.first {
                                    viewModel.startRenaming(item: first)
                                }
                            },
                            onDeleteSelected: {
                                viewModel.deleteSelectedItems()
                            }
                        )

                        // Vertical divider between sidebar and viewport
                        Rectangle()
                            .frame(width: 1)
                            .foregroundColor(Color(red: 0.70, green: 0.75, blue: 0.85))
                    }

                    // Viewport Grid
                    ExplorerItemGrid(
                        items: viewModel.displayedItems,
                        viewMode: viewModel.viewMode,
                        selectedIDs: viewModel.selectedItemIDs,
                        sortColumn: viewModel.sortColumn,
                        sortAscending: viewModel.sortAscending,
                        renamingItemID: viewModel.renamingItemID,
                        renamingText: $viewModel.renamingText,
                        onSelect: { item, multi in
                            viewModel.selectItem(item, exclusive: !multi)
                        },
                        onOpen: { item in
                            handleOpenItem(item)
                        },
                        onSort: { column in
                            viewModel.toggleSort(column: column)
                        },
                        onCommitRename: { item, newName in
                            viewModel.commitRename(item: item, newName: newName)
                        },
                        onCancelRename: {
                            viewModel.cancelRename()
                        },
                        onExplore: { item in
                            if item.isDirectory {
                                windowManager.openWindow(appType: .explorer(path: item.path), title: item.name)
                            }
                        },
                        onOpenWithNotepad: { item in
                            windowManager.openWindow(appType: .notepad(fileURL: item.url), title: "\(item.name) - Notepad")
                        },
                        onOpenWithDefaultApp: { item in
                            #if os(macOS)
                            NSWorkspace.shared.open(item.url)
                            #endif
                        },
                        onDelete: { item in
                            viewModel.selectItem(item)
                            viewModel.deleteSelectedItems()
                        },
                        onStartRename: { item in
                            viewModel.startRenaming(item: item)
                        },
                        onProperties: { item in
                            viewModel.showProperties(for: item)
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.clearSelection()
                    }
                    .explorerBackgroundContextMenu(
                        currentViewMode: viewModel.viewMode,
                        onSelectViewMode: { mode in viewModel.viewMode = mode },
                        onArrange: { col in viewModel.toggleSort(column: col) },
                        onRefresh: { viewModel.loadDirectoryContents() },
                        onNewFolder: { viewModel.createNewFolder() },
                        onNewTextDocument: { viewModel.createNewTextDocument() },
                        onProperties: { viewModel.showProperties() }
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 5. Windows XP Explorer Status Bar
                statusBarView
            }
            .background(Color(red: 0.94, green: 0.94, blue: 0.94))

            // Properties Dialog Modal
            if viewModel.isPropertiesOpen, let propItem = viewModel.propertiesItem {
                propertiesDialog(for: propItem)
                    .zIndex(100)
            }

            // Folder Options Dialog Modal
            if viewModel.isFolderOptionsOpen {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        viewModel.isFolderOptionsOpen = false
                    }

                FolderOptionsDialog {
                    viewModel.isFolderOptionsOpen = false
                    viewModel.loadDirectoryContents()
                }
                .zIndex(101)
            }
        }
    }

    // MARK: - Menu Bar
    private var menuBarView: some View {
        HStack(spacing: 12) {
            // File Menu
            Menu("File") {
                Menu("New") {
                    Button("Folder") { viewModel.createNewFolder() }
                    Button("Text Document") { viewModel.createNewTextDocument() }
                }
                Divider()
                Button("Delete") { viewModel.deleteSelectedItems() }
                Button("Rename") {
                    if let first = viewModel.selectedItems.first {
                        viewModel.startRenaming(item: first)
                    }
                }
                Button("Properties") { viewModel.showProperties() }
                Divider()
                Button("Close") {
                    if let win = window {
                        windowManager.closeWindow(id: win.id)
                    }
                }
            }

            // Edit Menu
            Menu("Edit") {
                Button("Cut") { viewModel.cutSelectedItems() }
                Button("Copy") { viewModel.copySelectedItems() }
                Button("Paste") { viewModel.pasteClipboard() }
                Divider()
                Button("Select All") { viewModel.selectAll() }
                Button("Invert Selection") { viewModel.invertSelection() }
            }

            // View Menu
            Menu("View") {
                Menu("Toolbars") {
                    Button("Standard Buttons") {}
                    Button("Address Bar") {}
                }
                Menu("Explorer Bar") {
                    Button("Search") { viewModel.toggleSearchCompanion() }
                    Button("Folders") { viewModel.toggleFolderTree() }
                }
                Divider()
                ForEach(ExplorerViewMode.allCases) { mode in
                    Button(mode.rawValue) {
                        viewModel.viewMode = mode
                    }
                }
                Divider()
                Menu("Arrange Icons By") {
                    Button("Name") { viewModel.toggleSort(column: .name) }
                    Button("Size") { viewModel.toggleSort(column: .size) }
                    Button("Type") { viewModel.toggleSort(column: .type) }
                    Button("Modified") { viewModel.toggleSort(column: .dateModified) }
                }
                Button("Refresh") { viewModel.loadDirectoryContents() }
            }

            // Favorites Menu
            Menu("Favorites") {
                Button("Add to Favorites...") {}
                Button("Organize Favorites...") {}
            }

            // Tools Menu
            Menu("Tools") {
                Button("Map Network Drive...") {}
                Button("Disconnect Network Drive...") {}
                Button("Folder Options...") {
                    viewModel.isFolderOptionsOpen = true
                }
            }

            // Help Menu
            Menu("Help") {
                Button("Help and Support Center") {}
                Divider()
                Button("About Windows XP") {
                    windowManager.openWindow(appType: .systemProperties)
                }
            }

            Spacer()
        }
        .font(.system(size: 11))
        .foregroundColor(.black)
        .padding(.horizontal, 8)
        .frame(height: 20)
        .background(
            LinearGradient(
                colors: [Color(red: 0.96, green: 0.95, blue: 0.93), Color(red: 0.90, green: 0.89, blue: 0.86)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(red: 0.82, green: 0.80, blue: 0.78)),
            alignment: .bottom
        )
    }

    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.gray)
                .font(.system(size: 12))

            TextField("Search in current folder...", text: $viewModel.searchQuery)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 11))
                .foregroundColor(.black)

            if !viewModel.searchQuery.isEmpty {
                Button(action: { viewModel.searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 24)
        .background(Color(red: 0.98, green: 0.98, blue: 0.94))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(red: 0.85, green: 0.82, blue: 0.75)),
            alignment: .bottom
        )
    }

    // MARK: - Status Bar
    private var statusBarView: some View {
        HStack(spacing: 2) {
            // Segment 1: Objects Count
            statusSegment(
                text: "\(viewModel.displayedItems.count) objects"
            )
            .frame(width: 140, alignment: .leading)

            // Segment 2: Selected Size
            statusSegment(
                text: selectedStatusText
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            // Segment 3: Zone / Disk space
            statusSegment(
                text: diskSpaceStatusText,
                icon: "desktopcomputer"
            )
            .frame(width: 160, alignment: .leading)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .frame(height: 22)
        .background(
            LinearGradient(
                colors: [Color(red: 0.93, green: 0.92, blue: 0.90), Color(red: 0.88, green: 0.87, blue: 0.84)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func statusSegment(text: String, icon: String? = nil) -> some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(Color(red: 0.20, green: 0.45, blue: 0.85))
            }
            Text(text)
                .font(.system(size: 10))
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 4)
        .frame(height: 18)
        .background(Color(red: 0.94, green: 0.94, blue: 0.92))
        .overlay(
            Rectangle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color(red: 0.65, green: 0.65, blue: 0.65), Color.white],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }

    private var selectedStatusText: String {
        let count = viewModel.selectedItems.count
        if count == 0 {
            return ""
        }
        if count == 1 {
            let item = viewModel.selectedItems[0]
            return item.isDirectory ? "1 folder selected" : "\(item.formattedSize)"
        }
        let totalBytes = viewModel.selectedItems.reduce(0) { $0 + $1.size }
        return "\(count) objects selected (\(FileSystemService.shared.formatXPSize(bytes: totalBytes)))"
    }

    private var diskSpaceStatusText: String {
        if viewModel.currentPath == "computer://" {
            return "My Computer"
        }
        let space = FileSystemService.shared.diskSpace(for: viewModel.currentPath)
        return "\(FileSystemService.shared.formatXPSize(bytes: space.free)) free"
    }

    private func handleOpenItem(_ item: FileItem) {
        if item.isDirectory {
            viewModel.navigateTo(path: item.path)
        } else {
            FileSystemService.shared.openItem(item, windowManager: windowManager)
        }
    }

    // MARK: - Properties Dialog
    private func propertiesDialog(for item: FileItem) -> some View {
        let prop = FileSystemService.shared.itemProperties(for: item.path)

        return ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.isPropertiesOpen = false
                }

            VStack(spacing: 0) {
                // Title Bar
                HStack {
                    Text("\(item.name) Properties")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { viewModel.isPropertiesOpen = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 16, height: 16)
                            .background(Color(red: 0.85, green: 0.25, blue: 0.20))
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 8)
                .frame(height: 24)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.00, green: 0.33, blue: 0.92), Color(red: 0.11, green: 0.50, blue: 0.93)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Tab Content (General Tab)
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: item.iconName)
                            .font(.system(size: 32))
                            .foregroundColor(Color(red: 0.95, green: 0.75, blue: 0.20))
                        Text(item.name)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        propRow(label: "Type of file:", value: prop.typeDescription)
                        propRow(label: "Location:", value: prop.path)
                        propRow(label: "Size:", value: prop.formattedSize)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        if let created = prop.dateCreated {
                            propRow(label: "Created:", value: formattedDate(created))
                        }
                        propRow(label: "Modified:", value: formattedDate(prop.dateModified))
                    }

                    Divider()

                    HStack(spacing: 16) {
                        Text("Attributes:")
                            .font(.system(size: 10))
                            .foregroundColor(Color.gray)
                        HStack(spacing: 4) {
                            Image(systemName: prop.isReadOnly ? "checkmark.square.fill" : "square")
                                .font(.system(size: 11))
                            Text("Read-only")
                                .font(.system(size: 10))
                        }
                        HStack(spacing: 4) {
                            Image(systemName: prop.isHidden ? "checkmark.square.fill" : "square")
                                .font(.system(size: 11))
                            Text("Hidden")
                                .font(.system(size: 10))
                        }
                    }

                    Spacer()

                    // OK / Cancel Buttons
                    HStack {
                        Spacer()
                        Button("OK") {
                            viewModel.isPropertiesOpen = false
                        }
                        .buttonStyle(PlainButtonStyle())
                        .font(.system(size: 11))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.90, green: 0.90, blue: 0.92))
                        .border(Color(red: 0.20, green: 0.40, blue: 0.80), width: 1)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.94, green: 0.94, blue: 0.92))
            }
            .frame(width: 340, height: 380)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color(red: 0.00, green: 0.33, blue: 0.92), lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 10, x: 2, y: 4)
        }
    }

    private func propRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(Color.gray)
                .frame(width: 75, alignment: .leading)

            Text(value)
                .font(.system(size: 10))
                .foregroundColor(.black)
                .lineLimit(2)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
