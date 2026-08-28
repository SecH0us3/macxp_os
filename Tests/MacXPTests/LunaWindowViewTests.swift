import XCTest
import SwiftUI
@testable import MacXP

final class LunaWindowViewTests: XCTestCase {
    func testLunaWindowViewCompiles() {
        let instance = XPWindowInstance(appType: .notepad(fileURL: nil), title: "Untitled - Notepad")
        let view = LunaWindowView(window: instance, onClose: {}) {
            Text("Content")
        }
        XCTAssertNotNil(view)
    }

    func testLunaWindowViewCallbacks() {
        var closed = false
        var minimized = false
        var maximizedToggled = false
        var focused = false
        var dragDelta = CGSize.zero
        var resizeDirection: ResizeDirection?
        var resizeDelta = CGSize.zero

        let instance = XPWindowInstance(
            appType: .notepad(fileURL: nil),
            title: "Test Notepad",
            isFocused: true
        )

        let view = LunaWindowView(
            window: instance,
            onClose: { closed = true },
            onMinimize: { minimized = true },
            onToggleMaximize: { maximizedToggled = true },
            onFocus: { focused = true },
            onDrag: { delta in dragDelta = delta },
            onResize: { direction, delta in
                resizeDirection = direction
                resizeDelta = delta
            }
        ) {
            Text("Test Body")
        }

        XCTAssertNotNil(view)
        
        // Execute callbacks
        view.onClose?()
        XCTAssertTrue(closed)

        view.onMinimize?()
        XCTAssertTrue(minimized)

        view.onToggleMaximize?()
        XCTAssertTrue(maximizedToggled)

        view.onFocus?()
        XCTAssertTrue(focused)

        view.onDrag?(CGSize(width: 15, height: 25))
        XCTAssertEqual(dragDelta, CGSize(width: 15, height: 25))

        view.onResize?(.bottomRight, CGSize(width: 40, height: 50))
        XCTAssertEqual(resizeDirection, .bottomRight)
        XCTAssertEqual(resizeDelta, CGSize(width: 40, height: 50))
    }

    func testTitleBarButtonTypes() {
        var clickedMinimize = false
        var clickedMaximize = false
        var clickedRestore = false
        var clickedClose = false

        let minBtn = TitleBarButton(type: .minimize, isWindowFocused: true) { clickedMinimize = true }
        let maxBtn = TitleBarButton(type: .maximize, isWindowFocused: true) { clickedMaximize = true }
        let resBtn = TitleBarButton(type: .restore, isWindowFocused: false) { clickedRestore = true }
        let closeBtn = TitleBarButton(type: .close, isWindowFocused: true) { clickedClose = true }

        XCTAssertNotNil(minBtn)
        XCTAssertNotNil(maxBtn)
        XCTAssertNotNil(resBtn)
        XCTAssertNotNil(closeBtn)

        XCTAssertEqual(minBtn.type, .minimize)
        XCTAssertEqual(maxBtn.type, .maximize)
        XCTAssertEqual(resBtn.type, .restore)
        XCTAssertEqual(closeBtn.type, .close)

        XCTAssertTrue(minBtn.isWindowFocused)
        XCTAssertFalse(resBtn.isWindowFocused)

        minBtn.action()
        XCTAssertTrue(clickedMinimize)

        maxBtn.action()
        XCTAssertTrue(clickedMaximize)

        resBtn.action()
        XCTAssertTrue(clickedRestore)

        closeBtn.action()
        XCTAssertTrue(clickedClose)
    }

    func testResizeDirectionsEnum() {
        let directions: [ResizeDirection] = ResizeDirection.allCases
        XCTAssertEqual(directions.count, 8)
        XCTAssertTrue(directions.contains(.top))
        XCTAssertTrue(directions.contains(.bottom))
        XCTAssertTrue(directions.contains(.left))
        XCTAssertTrue(directions.contains(.right))
        XCTAssertTrue(directions.contains(.topLeft))
        XCTAssertTrue(directions.contains(.topRight))
        XCTAssertTrue(directions.contains(.bottomLeft))
        XCTAssertTrue(directions.contains(.bottomRight))
    }

    func testTopRoundedRectanglePath() {
        let shape = TopRoundedRectangle(radius: 8)
        let rect = CGRect(x: 0, y: 0, width: 400, height: 300)
        let path = shape.path(in: rect)
        XCTAssertFalse(path.isEmpty)
        XCTAssertEqual(path.boundingRect.width, 400, accuracy: 1.0)
        XCTAssertEqual(path.boundingRect.height, 300, accuracy: 1.0)

        let insetShape = shape.inset(by: 3)
        let insetPath = insetShape.path(in: rect)
        XCTAssertFalse(insetPath.isEmpty)
    }

    func testInactiveWindowViewConfiguration() {
        let inactiveInstance = XPWindowInstance(
            appType: .explorer(path: "/Users"),
            title: "Users",
            rect: CGRect(x: 50, y: 50, width: 500, height: 350),
            state: .normal,
            isFocused: false
        )

        let view = LunaWindowView(window: inactiveInstance) {
            Text("Inactive Content")
        }

        XCTAssertFalse(view.window.isFocused)
        XCTAssertEqual(view.window.rect.width, 500)
        XCTAssertEqual(view.window.rect.height, 350)
    }

    func testMaximizedWindowConfiguration() {
        let maxInstance = XPWindowInstance(
            appType: .paint,
            title: "Paint",
            rect: CGRect(x: 0, y: 0, width: 1024, height: 768),
            state: .maximized,
            isFocused: true
        )

        let view = LunaWindowView(window: maxInstance) {
            Text("Paint Canvas")
        }

        XCTAssertEqual(view.window.state, .maximized)
        XCTAssertTrue(view.window.isFocused)
    }

    func testDefaultWindowViewInitializers() {
        let instance = XPWindowInstance(appType: .calculator)
        let view = LunaWindowView(window: instance) {
            Text("Calc")
        }

        XCTAssertNil(view.onClose)
        XCTAssertNil(view.onMinimize)
        XCTAssertNil(view.onToggleMaximize)
        XCTAssertNil(view.onFocus)
        XCTAssertNil(view.onDrag)
        XCTAssertNil(view.onResize)
    }
}
