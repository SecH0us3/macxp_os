import XCTest
@testable import MacXP

final class FileSystemServiceTests: XCTestCase {
    var service: FileSystemService!
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        service = FileSystemService()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Path Resolution Tests

    func testResolveVirtualMyComputer() {
        let path = service.resolvePath("My Computer")
        XCTAssertEqual(path, "computer://")

        let pathLower = service.resolvePath("computer://")
        XCTAssertEqual(pathLower, "computer://")
    }

    func testResolveWindowsDriveLetter() {
        let resolvedRoot = service.resolvePath("C:\\")
        XCTAssertEqual(resolvedRoot, "/")

        let resolvedSub = service.resolvePath("C:\\Users")
        XCTAssertEqual(resolvedSub, "/Users")
        
        let resolvedForward = service.resolvePath("C:/Users")
        XCTAssertEqual(resolvedForward, "/Users")
    }

    func testResolveTildeAndUnixPaths() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let resolvedTilde = service.resolvePath("~")
        XCTAssertEqual(resolvedTilde, home)

        let resolvedTildeSub = service.resolvePath("~/Documents")
        XCTAssertEqual(resolvedTildeSub, (home as NSString).appendingPathComponent("Documents"))

        let resolvedUnix = service.resolvePath("/Library")
        XCTAssertEqual(resolvedUnix, "/Library")
    }

    func testFormatPathForDisplay() {
        let myComputerDisplay = service.formatPathForDisplay("computer://")
        XCTAssertEqual(myComputerDisplay, "My Computer")

        let rootDisplay = service.formatPathForDisplay("/")
        XCTAssertEqual(rootDisplay, "C:\\")

        let usersDisplay = service.formatPathForDisplay("/Users")
        XCTAssertEqual(usersDisplay, "C:\\Users")
    }

    // MARK: - Navigation & History Tests

    func testHistoryNavigation() {
        var state = ExplorerState(initialPath: "computer://")
        XCTAssertFalse(state.canGoBack)
        XCTAssertFalse(state.canGoForward)

        state.navigateTo(path: "/Users")
        XCTAssertTrue(state.canGoBack)
        XCTAssertFalse(state.canGoForward)
        XCTAssertEqual(state.currentPath, "/Users")

        state.navigateTo(path: "/Library")
        XCTAssertTrue(state.canGoBack)
        XCTAssertFalse(state.canGoForward)
        XCTAssertEqual(state.currentPath, "/Library")

        // Go Back
        state.goBack()
        XCTAssertEqual(state.currentPath, "/Users")
        XCTAssertTrue(state.canGoBack)
        XCTAssertTrue(state.canGoForward)

        // Go Back again to My Computer
        state.goBack()
        XCTAssertEqual(state.currentPath, "computer://")
        XCTAssertFalse(state.canGoBack)
        XCTAssertTrue(state.canGoForward)

        // Go Forward
        state.goForward()
        XCTAssertEqual(state.currentPath, "/Users")
        XCTAssertTrue(state.canGoBack)
        XCTAssertTrue(state.canGoForward)
    }

    func testParentDirectoryTraversal() {
        let state = ExplorerState(initialPath: "/Users/Shared")
        XCTAssertTrue(state.canGoUp)
        
        let parent1 = service.parentDirectory(of: "/Users/Shared")
        XCTAssertEqual(parent1, "/Users")

        let parent2 = service.parentDirectory(of: "/Users")
        XCTAssertEqual(parent2, "/")

        let parent3 = service.parentDirectory(of: "/")
        XCTAssertEqual(parent3, "computer://")

        let parent4 = service.parentDirectory(of: "computer://")
        XCTAssertEqual(parent4, "computer://")
    }

    // MARK: - File Listing & Directory Contents

    func testMyComputerDrivesListing() {
        let items = service.myComputerDrives()
        XCTAssertFalse(items.isEmpty)

        // Should contain Local Disk (C:)
        let cDrive = items.first(where: { $0.name.contains("Local Disk (C:)") || $0.path == "/" })
        XCTAssertNotNil(cDrive)
        XCTAssertTrue(cDrive?.isDirectory ?? false)
        XCTAssertTrue(cDrive?.isVolume ?? false)

        // Should contain Home directory
        let homeDrive = items.first(where: { $0.path == FileManager.default.homeDirectoryForCurrentUser.path })
        XCTAssertNotNil(homeDrive)
    }

    func testContentsOfDirectory() throws {
        // Create test files in temp directory
        let file1URL = tempDirectory.appendingPathComponent("test1.txt")
        try "Hello XP".write(to: file1URL, atomically: true, encoding: .utf8)

        let subDirURL = tempDirectory.appendingPathComponent("FolderA")
        try FileManager.default.createDirectory(at: subDirURL, withIntermediateDirectories: true)

        let items = try service.contentsOfDirectory(at: tempDirectory.path)
        XCTAssertEqual(items.count, 2)

        let folderItem = items.first(where: { $0.name == "FolderA" })
        XCTAssertNotNil(folderItem)
        XCTAssertTrue(folderItem?.isDirectory ?? false)
        XCTAssertEqual(folderItem?.typeDescription, "File Folder")

        let fileItem = items.first(where: { $0.name == "test1.txt" })
        XCTAssertNotNil(fileItem)
        XCTAssertFalse(fileItem?.isDirectory ?? true)
        XCTAssertEqual(fileItem?.typeDescription, "Text Document")
        XCTAssertEqual(fileItem?.fileExtension, "txt")
    }

    // MARK: - File Operations Tests

    func testCreateFolder() throws {
        let newFolder = try service.createFolder(at: tempDirectory.path, name: "New Folder")
        XCTAssertTrue(FileManager.default.fileExists(atPath: newFolder.path))
        XCTAssertTrue(newFolder.isDirectory)
        XCTAssertEqual(newFolder.name, "New Folder")

        // Duplicate creation produces unique name
        let folder2 = try service.createFolder(at: tempDirectory.path, name: "New Folder")
        XCTAssertEqual(folder2.name, "New Folder (2)")
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder2.path))
    }

    func testCreateTextDocument() throws {
        let doc = try service.createTextDocument(at: tempDirectory.path, name: "New Text Document.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: doc.path))
        XCTAssertFalse(doc.isDirectory)
        XCTAssertEqual(doc.name, "New Text Document.txt")

        let doc2 = try service.createTextDocument(at: tempDirectory.path, name: "New Text Document.txt")
        XCTAssertEqual(doc2.name, "New Text Document (2).txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: doc2.path))
    }

    func testRenameItem() throws {
        let doc = try service.createTextDocument(at: tempDirectory.path, name: "Original.txt")
        let renamed = try service.renameItem(at: doc.path, newName: "Renamed.txt")

        XCTAssertFalse(FileManager.default.fileExists(atPath: doc.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: renamed.path))
        XCTAssertEqual(renamed.name, "Renamed.txt")
    }

    func testDeleteItem() throws {
        let doc = try service.createTextDocument(at: tempDirectory.path, name: "ToDelete.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: doc.path))

        try service.deleteItem(at: doc.path)
        XCTAssertFalse(FileManager.default.fileExists(atPath: doc.path))
    }

    // MARK: - File Formatting & Properties

    func testFormatXPSize() {
        XCTAssertEqual(service.formatXPSize(bytes: 0), "0 KB")
        XCTAssertEqual(service.formatXPSize(bytes: 500), "1 KB")
        XCTAssertEqual(service.formatXPSize(bytes: 2048), "2 KB")
        XCTAssertEqual(service.formatXPSize(bytes: 1048576), "1.00 MB")
        XCTAssertEqual(service.formatXPSize(bytes: 1073741824), "1.00 GB")
    }

    func testFileTypeDescription() {
        XCTAssertEqual(service.typeDescription(forExtension: "txt", isDirectory: false), "Text Document")
        XCTAssertEqual(service.typeDescription(forExtension: "swift", isDirectory: false), "Swift Source File")
        XCTAssertEqual(service.typeDescription(forExtension: "png", isDirectory: false), "PNG Image")
        XCTAssertEqual(service.typeDescription(forExtension: "app", isDirectory: false), "Application")
        XCTAssertEqual(service.typeDescription(forExtension: "", isDirectory: true), "File Folder")
    }

    func testDiskSpace() {
        let space = service.diskSpace(for: "/")
        XCTAssertGreaterThan(space.total, 0)
        XCTAssertGreaterThan(space.free, 0)
    }
}
