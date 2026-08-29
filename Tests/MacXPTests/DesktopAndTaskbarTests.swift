import XCTest
import SwiftUI
@testable import MacXP

final class DesktopAndTaskbarTests: XCTestCase {
    
    // MARK: - Desktop Icon & Manager Tests
    
    func testDesktopIconItemInitialization() {
        let id = UUID()
        let item = DesktopIconItem(
            id: id,
            title: "My Computer",
            iconName: "desktopcomputer",
            isSystem: true,
            appType: .explorer(path: "/"),
            position: CGPoint(x: 20, y: 20),
            isSelected: false
        )
        
        XCTAssertEqual(item.id, id)
        XCTAssertEqual(item.title, "My Computer")
        XCTAssertEqual(item.iconName, "desktopcomputer")
        XCTAssertTrue(item.isSystem)
        XCTAssertEqual(item.appType, .explorer(path: "/"))
        XCTAssertEqual(item.position, CGPoint(x: 20, y: 20))
        XCTAssertFalse(item.isSelected)
    }
    
    func testDesktopManagerDefaultIcons() {
        let manager = DesktopManager()
        
        // Should contain standard system icons
        let titles = manager.icons.map(\.title)
        XCTAssertTrue(titles.contains("My Computer"))
        XCTAssertTrue(titles.contains("My Documents"))
        XCTAssertTrue(titles.contains("Recycle Bin"))
        XCTAssertTrue(titles.contains("Internet Explorer"))
    }
    
    func testDesktopManagerSelection() {
        let manager = DesktopManager()
        guard let firstID = manager.icons.first?.id else {
            XCTFail("Manager should have default icons")
            return
        }
        
        manager.selectIcon(id: firstID, exclusive: true)
        XCTAssertTrue(manager.isIconSelected(id: firstID))
        XCTAssertEqual(manager.selectedIconIDs.count, 1)
        
        // Select second exclusively
        if manager.icons.count > 1 {
            let secondID = manager.icons[1].id
            manager.selectIcon(id: secondID, exclusive: true)
            XCTAssertFalse(manager.isIconSelected(id: firstID))
            XCTAssertTrue(manager.isIconSelected(id: secondID))
            XCTAssertEqual(manager.selectedIconIDs.count, 1)
            
            // Multi-select without exclusive
            manager.selectIcon(id: firstID, exclusive: false)
            XCTAssertTrue(manager.isIconSelected(id: firstID))
            XCTAssertTrue(manager.isIconSelected(id: secondID))
            XCTAssertEqual(manager.selectedIconIDs.count, 2)
            
            // Toggle off first
            manager.selectIcon(id: firstID, exclusive: false)
            XCTAssertFalse(manager.isIconSelected(id: firstID))
            XCTAssertTrue(manager.isIconSelected(id: secondID))
            XCTAssertEqual(manager.selectedIconIDs.count, 1)
        }
        
        manager.clearSelection()
        XCTAssertTrue(manager.selectedIconIDs.isEmpty)
    }
    
    func testDesktopMarqueeSelectionCalculation() {
        // Test 4 drag quadrants
        let rect1 = MarqueeHelper.calculateRect(from: CGPoint(x: 10, y: 10), to: CGPoint(x: 100, y: 80))
        XCTAssertEqual(rect1, CGRect(x: 10, y: 10, width: 90, height: 70))
        
        let rect2 = MarqueeHelper.calculateRect(from: CGPoint(x: 100, y: 80), to: CGPoint(x: 10, y: 10))
        XCTAssertEqual(rect2, CGRect(x: 10, y: 10, width: 90, height: 70))
        
        let rect3 = MarqueeHelper.calculateRect(from: CGPoint(x: 10, y: 80), to: CGPoint(x: 100, y: 10))
        XCTAssertEqual(rect3, CGRect(x: 10, y: 10, width: 90, height: 70))
        
        let rect4 = MarqueeHelper.calculateRect(from: CGPoint(x: 100, y: 10), to: CGPoint(x: 10, y: 80))
        XCTAssertEqual(rect4, CGRect(x: 10, y: 10, width: 90, height: 70))
    }
    
    func testDesktopMarqueeIntersection() {
        let manager = DesktopManager()
        manager.icons = [
            DesktopIconItem(title: "Icon 1", iconName: "doc", position: CGPoint(x: 20, y: 20)),
            DesktopIconItem(title: "Icon 2", iconName: "doc", position: CGPoint(x: 20, y: 120)),
            DesktopIconItem(title: "Icon 3", iconName: "doc", position: CGPoint(x: 120, y: 20))
        ]
        
        // Marquee covering only Icon 1 and 2
        let marqueeRect = CGRect(x: 0, y: 0, width: 90, height: 200)
        manager.selectIconsInMarquee(marqueeRect: marqueeRect, itemSize: CGSize(width: 75, height: 75))
        
        XCTAssertEqual(manager.selectedIconIDs.count, 2)
        XCTAssertTrue(manager.isIconSelected(id: manager.icons[0].id))
        XCTAssertTrue(manager.isIconSelected(id: manager.icons[1].id))
        XCTAssertFalse(manager.isIconSelected(id: manager.icons[2].id))
    }
    
    func testDesktopArrangeIcons() {
        let manager = DesktopManager()
        manager.icons = [
            DesktopIconItem(title: "Zebra", iconName: "doc", position: .zero),
            DesktopIconItem(title: "Apple", iconName: "doc", position: .zero),
            DesktopIconItem(title: "Mango", iconName: "doc", position: .zero)
        ]
        
        manager.arrangeIcons(by: .name, desktopHeight: 600)
        let titles = manager.icons.map(\.title)
        XCTAssertEqual(titles, ["Apple", "Mango", "Zebra"])
        
        // Positions should be arranged in grid columns
        XCTAssertEqual(manager.icons[0].position.x, 20)
        XCTAssertEqual(manager.icons[0].position.y, 20)
        XCTAssertEqual(manager.icons[1].position.x, 20)
        XCTAssertGreaterThan(manager.icons[1].position.y, manager.icons[0].position.y)
    }
    
    func testDesktopArrangeBySizeAndType() {
        let manager = DesktopManager()
        manager.icons = [
            DesktopIconItem(title: "Doc B", iconName: "doc", isSystem: false, position: .zero),
            DesktopIconItem(title: "Sys A", iconName: "desktopcomputer", isSystem: true, position: .zero),
            DesktopIconItem(title: "Doc A", iconName: "doc", isSystem: false, position: .zero)
        ]
        
        manager.arrangeIcons(by: .type, desktopHeight: 600)
        // System icons should come first
        XCTAssertTrue(manager.icons[0].isSystem)
        XCTAssertEqual(manager.icons[0].title, "Sys A")
        XCTAssertEqual(manager.icons[1].title, "Doc A")
        XCTAssertEqual(manager.icons[2].title, "Doc B")
    }
    
    func testDesktopNewFolderAndDocument() {
        let manager = DesktopManager()
        let initialCount = manager.icons.count
        
        let folderItem = manager.createNewFolder()
        XCTAssertEqual(folderItem.title, "New Folder")
        XCTAssertEqual(manager.icons.count, initialCount + 1)
        
        let docItem = manager.createNewTextDocument()
        XCTAssertEqual(docItem.title, "New Text Document.txt")
        XCTAssertEqual(manager.icons.count, initialCount + 2)
        
        // Unique names for subsequent creations
        let folderItem2 = manager.createNewFolder()
        XCTAssertEqual(folderItem2.title, "New Folder (2)")
    }
    
    // MARK: - Start Menu & Items Tests
    
    func testStartMenuDefaultItems() {
        let startMenuModel = StartMenuModel()
        
        XCTAssertFalse(startMenuModel.userName.isEmpty)
        XCTAssertFalse(startMenuModel.pinnedItems.isEmpty)
        XCTAssertFalse(startMenuModel.recentItems.isEmpty)
        XCTAssertFalse(startMenuModel.systemShortcuts.isEmpty)
        XCTAssertFalse(startMenuModel.allPrograms.isEmpty)
        
        let pinnedTitles = startMenuModel.pinnedItems.map(\.title)
        XCTAssertTrue(pinnedTitles.contains("Internet"))
        XCTAssertTrue(pinnedTitles.contains("E-mail"))
        
        let recentTitles = startMenuModel.recentItems.map(\.title)
        XCTAssertTrue(recentTitles.contains("Notepad"))
        XCTAssertTrue(recentTitles.contains("Command Prompt"))
        XCTAssertTrue(recentTitles.contains("Calculator"))
        XCTAssertTrue(recentTitles.contains("Minesweeper"))
        XCTAssertTrue(recentTitles.contains("Paint"))
        
        let systemTitles = startMenuModel.systemShortcuts.map(\.title)
        XCTAssertTrue(systemTitles.contains("My Documents"))
        XCTAssertTrue(systemTitles.contains("My Computer"))
        XCTAssertTrue(systemTitles.contains("Control Panel"))
        XCTAssertTrue(systemTitles.contains("Run..."))
    }
    
    func testStartMenuItemActionDispatchesToWindowManager() {
        let windowManager = WindowManager()
        let startMenuModel = StartMenuModel()
        
        guard let notepadItem = startMenuModel.recentItems.first(where: { $0.title == "Notepad" }) else {
            XCTFail("Notepad item not found in start menu")
            return
        }
        
        notepadItem.action(windowManager)
        XCTAssertEqual(windowManager.windows.count, 1)
        XCTAssertEqual(windowManager.windows.first?.appType, .notepad(fileURL: nil))
        
        // Test System shortcut dispatch
        guard let runItem = startMenuModel.systemShortcuts.first(where: { $0.title == "Run..." }) else {
            XCTFail("Run item not found in start menu")
            return
        }
        
        runItem.action(windowManager)
        XCTAssertEqual(windowManager.windows.count, 2)
        XCTAssertEqual(windowManager.windows.last?.appType, .runDialog)

        // Test Pinned Internet Explorer dispatch
        guard let ieItem = startMenuModel.pinnedItems.first(where: { $0.title == "Internet" }) else {
            XCTFail("Internet item not found in start menu")
            return
        }
        ieItem.action(windowManager)
        XCTAssertEqual(windowManager.windows.count, 3)
        XCTAssertEqual(windowManager.windows.last?.appType, .internetExplorer(url: "https://www.google.com"))
    }
    
    // MARK: - System Tray & Volume Tests
    
    func testSystemTrayModelProperties() {
        let trayModel = SystemTrayModel()
        
        XCTAssertGreaterThanOrEqual(trayModel.volumeLevel, 0.0)
        XCTAssertLessThanOrEqual(trayModel.volumeLevel, 1.0)
        XCTAssertFalse(trayModel.isMuted)
        
        trayModel.setVolume(0.75)
        XCTAssertEqual(trayModel.volumeLevel, 0.75)
        
        trayModel.toggleMute()
        XCTAssertTrue(trayModel.isMuted)
        
        trayModel.toggleMute()
        XCTAssertFalse(trayModel.isMuted)
    }
    
    func testSystemTrayVolumeBoundaryClamping() {
        let trayModel = SystemTrayModel()
        
        trayModel.setVolume(1.5)
        XCTAssertEqual(trayModel.volumeLevel, 1.0)
        
        trayModel.setVolume(-0.5)
        XCTAssertEqual(trayModel.volumeLevel, 0.0)
    }
    
    func testSystemTrayClockFormatting() {
        let testDate = Date(timeIntervalSince1970: 1600000000) // 2020-09-13
        let timeString = SystemTrayModel.formatTime(testDate)
        XCTAssertFalse(timeString.isEmpty)
        
        let dateString = SystemTrayModel.formatFullDate(testDate)
        XCTAssertFalse(dateString.isEmpty)
    }
    
    // MARK: - Taskbar Window Tab Interactions Tests
    
    func testTaskbarTabClickBehavior() {
        let windowManager = WindowManager()
        let win1ID = windowManager.openWindow(appType: .notepad(fileURL: nil))
        let win2ID = windowManager.openWindow(appType: .calculator)
        
        // win2 is focused initially
        XCTAssertTrue(windowManager.window(for: win2ID)?.isFocused ?? false)
        XCTAssertFalse(windowManager.window(for: win1ID)?.isFocused ?? true)
        
        // Clicking inactive tab (win1) should focus it
        TaskbarHelper.handleTabClick(windowID: win1ID, windowManager: windowManager)
        XCTAssertTrue(windowManager.window(for: win1ID)?.isFocused ?? false)
        XCTAssertFalse(windowManager.window(for: win2ID)?.isFocused ?? true)
        
        // Clicking active focused tab (win1) should minimize it
        TaskbarHelper.handleTabClick(windowID: win1ID, windowManager: windowManager)
        XCTAssertEqual(windowManager.window(for: win1ID)?.state, .minimized)
        
        // Clicking minimized tab (win1) should restore and focus it
        TaskbarHelper.handleTabClick(windowID: win1ID, windowManager: windowManager)
        XCTAssertEqual(windowManager.window(for: win1ID)?.state, .normal)
        XCTAssertTrue(windowManager.window(for: win1ID)?.isFocused ?? false)
    }
    
    func testQuickLaunchTriggers() {
        let windowManager = WindowManager()
        
        // Open a window
        _ = windowManager.openWindow(appType: .notepad(fileURL: nil))
        XCTAssertEqual(windowManager.windows.filter({ $0.state != .minimized }).count, 1)
        
        // Trigger show desktop
        TaskbarHelper.handleQuickLaunch(action: .showDesktop, windowManager: windowManager)
        XCTAssertEqual(windowManager.windows.filter({ $0.state != .minimized }).count, 0)
        
        // Trigger open explorer
        TaskbarHelper.handleQuickLaunch(action: .openExplorer, windowManager: windowManager)
        XCTAssertEqual(windowManager.windows.count, 2)
        XCTAssertEqual(windowManager.windows.last?.appType, .explorer(path: "/"))
        
        // Trigger open cmd
        TaskbarHelper.handleQuickLaunch(action: .openCmd, windowManager: windowManager)
        XCTAssertEqual(windowManager.windows.count, 3)
        XCTAssertEqual(windowManager.windows.last?.appType, .cmd)
    }
}
