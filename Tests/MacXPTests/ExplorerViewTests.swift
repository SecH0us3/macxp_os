import XCTest
import SwiftUI
@testable import MacXP

final class ExplorerViewTests: XCTestCase {
    var tempDirectory: URL!
    var windowManager: WindowManager!

    override func setUp() {
        super.setUp()
        windowManager = WindowManager()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - ViewModel Navigation & State Tests

    func testViewModelInitialization() {
        let vm = ExplorerViewModel(initialPath: "computer://")
        XCTAssertEqual(vm.currentPath, "computer://")
        XCTAssertFalse(vm.items.isEmpty)
        XCTAssertEqual(vm.viewMode, .icons)
        XCTAssertEqual(vm.sortColumn, .name)
        XCTAssertTrue(vm.sortAscending)
        XCTAssertTrue(vm.isSidebarVisible)
        XCTAssertFalse(vm.isSearchActive)
    }

    func testViewModelNavigation() {
        let vm = ExplorerViewModel(initialPath: "computer://")
        XCTAssertFalse(vm.state.canGoBack)

        vm.navigateTo(path: tempDirectory.path)
        XCTAssertEqual(vm.currentPath, tempDirectory.path)
        XCTAssertTrue(vm.state.canGoBack)

        vm.goBack()
        XCTAssertEqual(vm.currentPath, "computer://")
        XCTAssertTrue(vm.state.canGoForward)

        vm.goForward()
        XCTAssertEqual(vm.currentPath, tempDirectory.path)
    }

    func testViewModelSelection() throws {
        let vm = ExplorerViewModel(initialPath: tempDirectory.path)
        vm.createNewFolder()
        vm.createNewTextDocument()

        XCTAssertEqual(vm.items.count, 2)

        // Select first
        let first = vm.items[0]
        vm.selectItem(first, exclusive: true)
        XCTAssertEqual(vm.selectedItemIDs.count, 1)
        XCTAssertEqual(vm.selectedItems.count, 1)
        XCTAssertEqual(vm.selectedItems.first?.id, first.id)

        // Select all
        vm.selectAll()
        XCTAssertEqual(vm.selectedItemIDs.count, 2)

        // Invert
        vm.selectItem(first, exclusive: true)
        vm.invertSelection()
        XCTAssertEqual(vm.selectedItemIDs.count, 1)
        XCTAssertFalse(vm.selectedItemIDs.contains(first.id))

        // Clear
        vm.clearSelection()
        XCTAssertTrue(vm.selectedItemIDs.isEmpty)
    }

    func testViewModelSorting() throws {
        let vm = ExplorerViewModel(initialPath: tempDirectory.path)
        
        // Create files with different names
        let fileB = tempDirectory.appendingPathComponent("B_File.txt")
        let fileA = tempDirectory.appendingPathComponent("A_File.txt")
        try "Content B".write(to: fileB, atomically: true, encoding: .utf8)
        try "Content A".write(to: fileA, atomically: true, encoding: .utf8)

        vm.loadDirectoryContents()
        XCTAssertEqual(vm.items.count, 2)

        // Sort by Name Ascending
        vm.sortColumn = .name
        vm.sortAscending = true
        XCTAssertEqual(vm.displayedItems.first?.name, "A_File.txt")

        // Toggle Sort to Descending
        vm.toggleSort(column: .name)
        XCTAssertFalse(vm.sortAscending)
        XCTAssertEqual(vm.displayedItems.first?.name, "B_File.txt")

        // Switch Sort to Size
        vm.toggleSort(column: .size)
        XCTAssertEqual(vm.sortColumn, .size)
        XCTAssertTrue(vm.sortAscending)
    }

    func testViewModelSearchFiltering() throws {
        let vm = ExplorerViewModel(initialPath: tempDirectory.path)

        let file1 = tempDirectory.appendingPathComponent("Apple.txt")
        let file2 = tempDirectory.appendingPathComponent("Banana.txt")
        let file3 = tempDirectory.appendingPathComponent("Orange.txt")
        try "A".write(to: file1, atomically: true, encoding: .utf8)
        try "B".write(to: file2, atomically: true, encoding: .utf8)
        try "O".write(to: file3, atomically: true, encoding: .utf8)

        vm.loadDirectoryContents()
        XCTAssertEqual(vm.items.count, 3)

        // Search inactive
        vm.isSearchActive = false
        vm.searchQuery = "an"
        XCTAssertEqual(vm.displayedItems.count, 3)

        // Search active
        vm.isSearchActive = true
        XCTAssertEqual(vm.displayedItems.count, 2) // Banana and Orange contain "an"
    }

    func testViewModelFileOperations() {
        let vm = ExplorerViewModel(initialPath: tempDirectory.path)

        // Create Folder
        vm.createNewFolder()
        XCTAssertEqual(vm.items.count, 1)
        XCTAssertTrue(vm.items[0].isDirectory)
        XCTAssertEqual(vm.items[0].name, "New Folder")

        // Create Text Document
        vm.createNewTextDocument()
        XCTAssertEqual(vm.items.count, 2)

        // Rename
        if let doc = vm.items.first(where: { !$0.isDirectory }) {
            vm.startRenaming(item: doc)
            XCTAssertEqual(vm.renamingItemID, doc.id)
            XCTAssertEqual(vm.renamingText, doc.name)

            vm.commitRename(item: doc, newName: "MyStory.txt")
            XCTAssertNil(vm.renamingItemID)
            XCTAssertTrue(vm.items.contains(where: { $0.name == "MyStory.txt" }))
        }

        // Delete
        vm.selectAll()
        vm.deleteSelectedItems()
        XCTAssertEqual(vm.items.count, 0)
    }

    func testViewModelPropertiesDialog() {
        let vm = ExplorerViewModel(initialPath: tempDirectory.path)
        vm.createNewFolder()
        guard let folder = vm.items.first else { return }

        vm.showProperties(for: folder)
        XCTAssertTrue(vm.isPropertiesOpen)
        XCTAssertEqual(vm.propertiesItem?.name, folder.name)
    }

    // MARK: - View Component Compilation Tests

    func testExplorerToolbarCompiles() {
        let toolbar = ExplorerToolbar(
            canGoBack: true,
            canGoForward: false,
            canGoUp: true,
            isFoldersActive: true,
            isSearchActive: false,
            currentViewMode: .details,
            onBack: {},
            onForward: {},
            onUp: {},
            onSearch: {},
            onToggleFolders: {},
            onSelectViewMode: { _ in }
        )
        XCTAssertNotNil(toolbar.body)
    }

    func testExplorerAddressBarCompiles() {
        let addressBar = ExplorerAddressBar(currentPath: "/Users", onNavigate: { _ in })
        XCTAssertNotNil(addressBar.body)
    }

    func testExplorerSidebarCompiles() {
        let sidebar = ExplorerSidebar(
            currentPath: "/Users",
            selectedItems: [],
            onNavigate: { _ in },
            onNewFolder: {},
            onRenameSelected: {},
            onDeleteSelected: {}
        )
        XCTAssertNotNil(sidebar.body)
    }

    // MARK: - Advanced Explorer Features Tests

    func testSearchCompanionRoverState() {
        let vm = ExplorerViewModel(initialPath: tempDirectory.path)
        XCTAssertFalse(vm.isSearchActive)
        
        vm.toggleSearchCompanion()
        XCTAssertTrue(vm.isSearchActive)
        XCTAssertEqual(vm.searchCategory, .allFiles)
        
        vm.searchCategory = .picturesAndMusic
        XCTAssertEqual(vm.searchCategory, .picturesAndMusic)
    }

    func testFolderTreeViewNavigation() {
        let vm = ExplorerViewModel(initialPath: "computer://")
        XCTAssertFalse(vm.isFolderTreeActive)
        
        vm.toggleFolderTree()
        XCTAssertTrue(vm.isFolderTreeActive)

        let rootNodes = FolderTreeService.shared.getRootNodes()
        XCTAssertFalse(rootNodes.isEmpty)
        XCTAssertTrue(rootNodes.contains(where: { $0.title == "Desktop" }))
        XCTAssertTrue(rootNodes.first?.children.contains(where: { $0.title == "My Computer" }) ?? false)
    }

    func testFolderOptionsDialogState() {
        let vm = ExplorerViewModel(initialPath: "computer://")
        XCTAssertFalse(vm.isFolderOptionsOpen)

        vm.isFolderOptionsOpen = true
        XCTAssertTrue(vm.isFolderOptionsOpen)
        
        let settings = FolderOptionsSettings.shared
        let initialHidden = settings.showHiddenFiles
        settings.showHiddenFiles.toggle()
        XCTAssertNotEqual(settings.showHiddenFiles, initialHidden)
        settings.showHiddenFiles.toggle() // restore
    }

    func testClipboardCutCopyPaste() throws {
        let vm = ExplorerViewModel(initialPath: tempDirectory.path)
        let file = tempDirectory.appendingPathComponent("Original.txt")
        try "Original Content".write(to: file, atomically: true, encoding: .utf8)
        vm.loadDirectoryContents()

        guard let item = vm.items.first(where: { $0.name == "Original.txt" }) else {
            XCTFail("Original file not found")
            return
        }

        vm.selectItem(item)
        vm.copySelectedItems()
        XCTAssertTrue(ExplorerClipboard.shared.hasContent)
        XCTAssertEqual(ExplorerClipboard.shared.items.first?.name, "Original.txt")

        // Test paste
        let subDir = tempDirectory.appendingPathComponent("SubFolder")
        try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)
        
        vm.navigateTo(path: subDir.path)
        vm.pasteClipboard()
        vm.loadDirectoryContents()
        XCTAssertTrue(vm.items.contains(where: { $0.name == "Original.txt" }))
    }
}

