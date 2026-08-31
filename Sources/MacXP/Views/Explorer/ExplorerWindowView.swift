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

            // Authentic Windows XP Menu Dropdown Overlay
            if let activeMenu = openMenu {
                VStack {
                    HStack {
                        dropdownMenuView(for: activeMenu)
                            .padding(.leading, menuXOffset(for: activeMenu))
                            .padding(.top, 22)
                        Spacer()
                    }
                    Spacer()
                }
                .zIndex(50)
            }
        }
    }

    @State private var openMenu: String? = nil
    @State private var openSubmenu: String? = nil

    // MARK: - Authentic Windows XP Menu Bar
    private var menuBarView: some View {
        HStack(spacing: 0) {
            menuBarButton(title: "File")
            menuBarButton(title: "Edit")
            menuBarButton(title: "View")
            menuBarButton(title: "Favorites")
            menuBarButton(title: "Tools")
            menuBarButton(title: "Help")
            Spacer()
        }
        .frame(height: 22)
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

    private func menuBarButton(title: String) -> some View {
        let isOpen = (openMenu == title)
        return Button(action: {
            if openMenu == title {
                openMenu = nil
                openSubmenu = nil
            } else {
                openMenu = title
                openSubmenu = nil
            }
        }) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.black)
                .padding(.horizontal, 7)
                .frame(height: 20)
                .background(
                    isOpen ? Color(red: 0.19, green: 0.42, blue: 0.77).opacity(0.18) : Color.clear
                )
                .overlay(
                    isOpen ? RoundedRectangle(cornerRadius: 2).stroke(Color(red: 0.19, green: 0.42, blue: 0.77), lineWidth: 1) : nil
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func menuXOffset(for menu: String) -> CGFloat {
        switch menu {
        case "File": return 4
        case "Edit": return 32
        case "View": return 64
        case "Favorites": return 100
        case "Tools": return 156
        case "Help": return 198
        default: return 4
        }
    }

    // MARK: - Dropdown Menus
    @ViewBuilder
    private func dropdownMenuView(for menu: String) -> some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                switch menu {
                case "File":
                    fileDropdownMenu
                case "Edit":
                    editDropdownMenu
                case "View":
                    viewDropdownMenu
                case "Favorites":
                    favoritesDropdownMenu
                case "Tools":
                    toolsDropdownMenu
                case "Help":
                    helpDropdownMenu
                default:
                    EmptyView()
                }
            }
            .frame(width: 175)
            .padding(.vertical, 2)
            .background(Color.white)
            .overlay(Rectangle().stroke(Color(red: 0.45, green: 0.45, blue: 0.45), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.22), radius: 5, x: 2, y: 3)

            // Submenus Flyout
            if let sub = openSubmenu {
                submenuFlyoutView(for: sub)
                    .offset(x: 173, y: submenuYOffset(for: sub))
            }
        }
    }

    private var fileDropdownMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            XPMenuRow(title: "New", hasSubmenu: true) {
                openSubmenu = (openSubmenu == "New" ? nil : "New")
            }
            menuDivider
            XPMenuRow(title: "Delete", shortcut: "Del", isEnabled: !viewModel.selectedItems.isEmpty) {
                closeAllMenus()
                viewModel.deleteSelectedItems()
            }
            XPMenuRow(title: "Rename", shortcut: "F2", isEnabled: viewModel.selectedItems.count == 1) {
                closeAllMenus()
                if let first = viewModel.selectedItems.first {
                    viewModel.startRenaming(item: first)
                }
            }
            XPMenuRow(title: "Properties") {
                closeAllMenus()
                viewModel.showProperties()
            }
            menuDivider
            XPMenuRow(title: "Close", shortcut: "Alt+F4") {
                closeAllMenus()
                if let win = window {
                    windowManager.closeWindow(id: win.id)
                }
            }
        }
    }

    private var editDropdownMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            XPMenuRow(title: "Cut", shortcut: "Ctrl+X", isEnabled: !viewModel.selectedItems.isEmpty) {
                closeAllMenus()
                viewModel.cutSelectedItems()
            }
            XPMenuRow(title: "Copy", shortcut: "Ctrl+C", isEnabled: !viewModel.selectedItems.isEmpty) {
                closeAllMenus()
                viewModel.copySelectedItems()
            }
            XPMenuRow(title: "Paste", shortcut: "Ctrl+V", isEnabled: ExplorerClipboard.shared.hasContent) {
                closeAllMenus()
                viewModel.pasteClipboard()
            }
            menuDivider
            XPMenuRow(title: "Select All", shortcut: "Ctrl+A") {
                closeAllMenus()
                viewModel.selectAll()
            }
            XPMenuRow(title: "Invert Selection") {
                closeAllMenus()
                viewModel.invertSelection()
            }
        }
    }

    private var viewDropdownMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            XPMenuRow(title: "Toolbars", hasSubmenu: true) {
                openSubmenu = (openSubmenu == "Toolbars" ? nil : "Toolbars")
            }
            XPMenuRow(title: "Explorer Bar", hasSubmenu: true) {
                openSubmenu = (openSubmenu == "ExplorerBar" ? nil : "ExplorerBar")
            }
            menuDivider
            ForEach(ExplorerViewMode.allCases) { mode in
                XPMenuRow(title: mode.rawValue, isChecked: viewModel.viewMode == mode) {
                    closeAllMenus()
                    viewModel.viewMode = mode
                }
            }
            menuDivider
            XPMenuRow(title: "Arrange Icons By", hasSubmenu: true) {
                openSubmenu = (openSubmenu == "Arrange" ? nil : "Arrange")
            }
            menuDivider
            XPMenuRow(title: "Refresh", shortcut: "F5") {
                closeAllMenus()
                viewModel.loadDirectoryContents()
            }
        }
    }

    private var favoritesDropdownMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            XPMenuRow(title: "Add to Favorites...") {
                closeAllMenus()
            }
            XPMenuRow(title: "Organize Favorites...") {
                closeAllMenus()
            }
        }
    }

    private var toolsDropdownMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            XPMenuRow(title: "Map Network Drive...") {
                closeAllMenus()
            }
            XPMenuRow(title: "Disconnect Network Drive...") {
                closeAllMenus()
            }
            menuDivider
            XPMenuRow(title: "Folder Options...") {
                closeAllMenus()
                viewModel.isFolderOptionsOpen = true
            }
        }
    }

    private var helpDropdownMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            XPMenuRow(title: "Help and Support Center") {
                closeAllMenus()
            }
            menuDivider
            XPMenuRow(title: "About Windows XP") {
                closeAllMenus()
                windowManager.openWindow(appType: .systemProperties)
            }
        }
    }

    @ViewBuilder
    private func submenuFlyoutView(for submenu: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            switch submenu {
            case "New":
                XPMenuRow(title: "Folder", icon: "folder.fill") {
                    closeAllMenus()
                    viewModel.createNewFolder()
                }
                XPMenuRow(title: "Text Document", icon: "doc.text.fill") {
                    closeAllMenus()
                    viewModel.createNewTextDocument()
                }
            case "Toolbars":
                XPMenuRow(title: "Standard Buttons", isChecked: true) {}
                XPMenuRow(title: "Address Bar", isChecked: true) {}
            case "ExplorerBar":
                XPMenuRow(title: "Search", isChecked: viewModel.isSearchActive) {
                    closeAllMenus()
                    viewModel.toggleSearchCompanion()
                }
                XPMenuRow(title: "Folders", isChecked: viewModel.isFolderTreeActive) {
                    closeAllMenus()
                    viewModel.toggleFolderTree()
                }
            case "Arrange":
                XPMenuRow(title: "Name", isChecked: viewModel.sortColumn == .name) {
                    closeAllMenus()
                    viewModel.toggleSort(column: .name)
                }
                XPMenuRow(title: "Size", isChecked: viewModel.sortColumn == .size) {
                    closeAllMenus()
                    viewModel.toggleSort(column: .size)
                }
                XPMenuRow(title: "Type", isChecked: viewModel.sortColumn == .type) {
                    closeAllMenus()
                    viewModel.toggleSort(column: .type)
                }
                XPMenuRow(title: "Modified", isChecked: viewModel.sortColumn == .dateModified) {
                    closeAllMenus()
                    viewModel.toggleSort(column: .dateModified)
                }
            default:
                EmptyView()
            }
        }
        .frame(width: 155)
        .padding(.vertical, 2)
        .background(Color.white)
        .overlay(Rectangle().stroke(Color(red: 0.45, green: 0.45, blue: 0.45), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.22), radius: 5, x: 2, y: 3)
    }

    private func submenuYOffset(for submenu: String) -> CGFloat {
        switch submenu {
        case "New": return 0
        case "Toolbars": return 0
        case "ExplorerBar": return 22
        case "Arrange": return 138
        default: return 0
        }
    }

    private var menuDivider: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.85))
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
    }

    private func closeAllMenus() {
        openMenu = nil
        openSubmenu = nil
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

public struct XPMenuRow: View {
    public let title: String
    public var shortcut: String? = nil
    public var icon: String? = nil
    public var isChecked: Bool = false
    public var hasSubmenu: Bool = false
    public var isEnabled: Bool = true
    public let action: () -> Void

    @State private var isHovered: Bool = false

    public init(
        title: String,
        shortcut: String? = nil,
        icon: String? = nil,
        isChecked: Bool = false,
        hasSubmenu: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.shortcut = shortcut
        self.icon = icon
        self.isChecked = isChecked
        self.hasSubmenu = hasSubmenu
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: {
            if isEnabled {
                action()
            }
        }) {
            HStack(spacing: 6) {
                // Gutter Icon / Checkmark
                ZStack {
                    if isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(isHovered ? .white : .black)
                    } else if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 11))
                            .foregroundColor(isHovered ? .white : Color(red: 0.20, green: 0.40, blue: 0.80))
                    }
                }
                .frame(width: 16)

                // Title
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(isEnabled ? (isHovered ? .white : .black) : Color.gray)

                Spacer()

                // Shortcut / Submenu indicator
                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.system(size: 10))
                        .foregroundColor(isEnabled ? (isHovered ? .white.opacity(0.9) : Color.gray) : Color.gray.opacity(0.5))
                } else if hasSubmenu {
                    Image(systemName: "play.fill")
                        .font(.system(size: 6))
                        .foregroundColor(isHovered ? .white : Color.black.opacity(0.7))
                }
            }
            .padding(.horizontal, 6)
            .frame(height: 22)
            .background(isHovered && isEnabled ? Color(red: 0.19, green: 0.42, blue: 0.77) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

