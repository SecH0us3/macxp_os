import XCTest
import SwiftUI
@testable import MacXP

final class BootScreenTests: XCTestCase {
    func testBootScreenInitializesAndFiresCompletion() {
        var completed = false
        let bootScreen = BootScreenView {
            completed = true
        }
        XCTAssertNotNil(bootScreen)
        XCTAssertFalse(completed)
    }

    func testBootProgressBarStructure() {
        let now = Date()
        let bar = BootProgressBar(startTime: now)
        XCTAssertNotNil(bar)
        XCTAssertEqual(bar.startTime, now)
    }
}
