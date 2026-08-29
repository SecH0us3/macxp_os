import XCTest
import SwiftUI
@testable import MacXP

final class FlashPlayerTests: XCTestCase {
    func testFlashGameTypesAndFilenames() {
        XCTAssertEqual(FlashGameType.copter.filename, "copter2004.swf")
        XCTAssertEqual(FlashGameType.spaceBlast.filename, "space_blast.swf")
        XCTAssertEqual(FlashGameType.allCases.count, 2)
    }

    func testFlashAppTypeDefaults() {
        let wm = WindowManager()
        let id = wm.openWindow(appType: .flashPlayer(game: "copter2004"))
        let win = wm.windows.first(where: { $0.id == id })
        XCTAssertEqual(win?.title, "Macromedia Flash Player 8 - copter2004.swf")
        XCTAssertEqual(win?.appType, XPAppType.flashPlayer(game: "copter2004"))
    }
}
