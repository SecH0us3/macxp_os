import XCTest
@testable import MacXP

final class WindowManagerTests: XCTestCase {
    func testWindowManagerState() {
        let manager = WindowManager()
        XCTAssertEqual(manager.windows.count, 0)
        XCTAssertNil(manager.activeWindow)
        
        let id = manager.openWindow(appType: .explorer(path: "/"), title: "My Computer")
        XCTAssertEqual(manager.windows.count, 1)
        XCTAssertEqual(manager.windows[0].title, "My Computer")
        XCTAssertTrue(manager.windows[0].isFocused)
        XCTAssertEqual(manager.windows[0].id, id)
        XCTAssertEqual(manager.activeWindow?.id, id)
        
        manager.closeWindow(id: id)
        XCTAssertEqual(manager.windows.count, 0)
        XCTAssertNil(manager.activeWindow)
    }

    func testAppTypesAndDefaults() {
        let manager = WindowManager()
        let testURL = URL(fileURLWithPath: "/tmp/test.txt")
        
        let expId = manager.openWindow(appType: .explorer(path: "/Users/test"))
        let noteId = manager.openWindow(appType: .notepad(fileURL: testURL))
        let noteEmptyId = manager.openWindow(appType: .notepad(fileURL: nil))
        let cmdId = manager.openWindow(appType: .cmd)
        let calcId = manager.openWindow(appType: .calculator)
        let mineId = manager.openWindow(appType: .minesweeper)
        let paintId = manager.openWindow(appType: .paint)
        let ctrlId = manager.openWindow(appType: .controlPanel)
        let sysId = manager.openWindow(appType: .systemProperties)
        let runId = manager.openWindow(appType: .runDialog)
        
        XCTAssertEqual(manager.windows.count, 10)
        
        let expWin = manager.window(for: expId)!
        XCTAssertEqual(expWin.appType, .explorer(path: "/Users/test"))
        XCTAssertEqual(expWin.title, "test")
        XCTAssertEqual(expWin.icon, "folder")
        
        let noteWin = manager.window(for: noteId)!
        XCTAssertEqual(noteWin.appType, .notepad(fileURL: testURL))
        XCTAssertEqual(noteWin.title, "test.txt - Notepad")
        XCTAssertEqual(noteWin.icon, "doc.text")
        
        let noteEmptyWin = manager.window(for: noteEmptyId)!
        XCTAssertEqual(noteEmptyWin.title, "Untitled - Notepad")
        
        let cmdWin = manager.window(for: cmdId)!
        XCTAssertEqual(cmdWin.appType, .cmd)
        XCTAssertEqual(cmdWin.title, "Command Prompt")
        XCTAssertEqual(cmdWin.icon, "terminal")
        
        let calcWin = manager.window(for: calcId)!
        XCTAssertEqual(calcWin.appType, .calculator)
        XCTAssertEqual(calcWin.title, "Calculator")
        
        let mineWin = manager.window(for: mineId)!
        XCTAssertEqual(mineWin.appType, .minesweeper)
        XCTAssertEqual(mineWin.title, "Minesweeper")
        
        let paintWin = manager.window(for: paintId)!
        XCTAssertEqual(paintWin.appType, .paint)
        XCTAssertEqual(paintWin.title, "untitled - Paint")
        
        let ctrlWin = manager.window(for: ctrlId)!
        XCTAssertEqual(ctrlWin.appType, .controlPanel)
        XCTAssertEqual(ctrlWin.title, "Control Panel")
        
        let sysWin = manager.window(for: sysId)!
        XCTAssertEqual(sysWin.appType, .systemProperties)
        XCTAssertEqual(sysWin.title, "System Properties")
        
        let runWin = manager.window(for: runId)!
        XCTAssertEqual(runWin.appType, .runDialog)
        XCTAssertEqual(runWin.title, "Run")
    }

    func testFocusAndBringToFront() {
        let manager = WindowManager()
        let win1 = manager.openWindow(appType: .cmd, title: "cmd 1")
        let win2 = manager.openWindow(appType: .calculator, title: "calc 2")
        
        XCTAssertFalse(manager.windows.first(where: { $0.id == win1 })!.isFocused)
        XCTAssertTrue(manager.windows.first(where: { $0.id == win2 })!.isFocused)
        XCTAssertGreaterThan(
            manager.windows.first(where: { $0.id == win2 })!.zIndex,
            manager.windows.first(where: { $0.id == win1 })!.zIndex
        )
        
        manager.focusWindow(id: win1)
        XCTAssertTrue(manager.windows.first(where: { $0.id == win1 })!.isFocused)
        XCTAssertFalse(manager.windows.first(where: { $0.id == win2 })!.isFocused)
        XCTAssertGreaterThan(
            manager.windows.first(where: { $0.id == win1 })!.zIndex,
            manager.windows.first(where: { $0.id == win2 })!.zIndex
        )

        // Test bringToFront alias
        manager.bringToFront(id: win2)
        XCTAssertTrue(manager.windows.first(where: { $0.id == win2 })!.isFocused)
        XCTAssertFalse(manager.windows.first(where: { $0.id == win1 })!.isFocused)
    }

    func testMinimizeAndRestore() {
        let manager = WindowManager()
        let win1 = manager.openWindow(appType: .cmd, title: "cmd 1")
        let win2 = manager.openWindow(appType: .calculator, title: "calc 2")
        
        manager.minimizeWindow(id: win2)
        XCTAssertEqual(manager.windows.first(where: { $0.id == win2 })!.state, .minimized)
        XCTAssertFalse(manager.windows.first(where: { $0.id == win2 })!.isFocused)
        // Focus should transfer to win1
        XCTAssertTrue(manager.windows.first(where: { $0.id == win1 })!.isFocused)
        XCTAssertEqual(manager.activeWindow?.id, win1)

        // Focusing a minimized window should un-minimize it
        manager.focusWindow(id: win2)
        XCTAssertEqual(manager.windows.first(where: { $0.id == win2 })!.state, .normal)
        XCTAssertTrue(manager.windows.first(where: { $0.id == win2 })!.isFocused)
        XCTAssertEqual(manager.activeWindow?.id, win2)
    }

    func testToggleMaximize() {
        let manager = WindowManager()
        let desktopBounds = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let customRect = CGRect(x: 50, y: 50, width: 400, height: 300)
        let win1 = manager.openWindow(appType: .paint, title: "Paint", rect: customRect)
        
        // Maximize
        manager.toggleMaximize(id: win1, desktopBounds: desktopBounds)
        let maxWin = manager.windows.first(where: { $0.id == win1 })!
        XCTAssertEqual(maxWin.state, .maximized)
        XCTAssertEqual(maxWin.rect, desktopBounds)
        XCTAssertEqual(maxWin.restoreRect, customRect)
        
        // Restore
        manager.toggleMaximize(id: win1, desktopBounds: desktopBounds)
        let restoredWin = manager.windows.first(where: { $0.id == win1 })!
        XCTAssertEqual(restoredWin.state, .normal)
        XCTAssertEqual(restoredWin.rect, customRect)
    }

    func testMinimizeAllAndShowDesktopToggle() {
        let manager = WindowManager()
        _ = manager.openWindow(appType: .cmd, title: "cmd")
        let win2 = manager.openWindow(appType: .calculator, title: "calc")
        
        manager.minimizeAll()
        for window in manager.windows {
            XCTAssertEqual(window.state, .minimized)
            XCTAssertFalse(window.isFocused)
        }
        XCTAssertNil(manager.activeWindow)
        
        // Toggle show desktop should restore all
        manager.toggleShowDesktop()
        for window in manager.windows {
            XCTAssertEqual(window.state, .normal)
        }
        XCTAssertEqual(manager.activeWindow?.id, win2)
        
        // Toggle show desktop again should minimize all
        manager.toggleShowDesktop()
        for window in manager.windows {
            XCTAssertEqual(window.state, .minimized)
        }
    }

    func testCloseFocusedWindowShiftsFocus() {
        let manager = WindowManager()
        let win1 = manager.openWindow(appType: .cmd, title: "cmd 1")
        let win2 = manager.openWindow(appType: .calculator, title: "calc 2")
        let win3 = manager.openWindow(appType: .notepad(fileURL: nil), title: "notepad 3")
        
        XCTAssertTrue(manager.windows.first(where: { $0.id == win3 })!.isFocused)
        
        manager.closeWindow(id: win3)
        XCTAssertEqual(manager.windows.count, 2)
        // Focus should shift to win2 (highest zIndex unminimized)
        XCTAssertTrue(manager.windows.first(where: { $0.id == win2 })!.isFocused)
        XCTAssertFalse(manager.windows.first(where: { $0.id == win1 })!.isFocused)
    }

    func testUpdateRectAndTitle() {
        let manager = WindowManager()
        let winId = manager.openWindow(appType: .explorer(path: "/"), title: "Old Title")
        
        let newRect = CGRect(x: 200, y: 150, width: 800, height: 600)
        manager.updateWindowRect(id: winId, rect: newRect)
        XCTAssertEqual(manager.window(for: winId)?.rect, newRect)
        
        manager.updateWindowTitle(id: winId, title: "New Title")
        XCTAssertEqual(manager.window(for: winId)?.title, "New Title")
    }

    func testCascadingWindowPositions() {
        let manager = WindowManager()
        let win1 = manager.openWindow(appType: .notepad())
        let win2 = manager.openWindow(appType: .notepad())
        
        let rect1 = manager.window(for: win1)!.rect
        let rect2 = manager.window(for: win2)!.rect
        
        XCTAssertNotEqual(rect1.origin, rect2.origin)
        XCTAssertEqual(rect2.origin.x, rect1.origin.x + 26)
        XCTAssertEqual(rect2.origin.y, rect1.origin.y + 26)
    }
}
