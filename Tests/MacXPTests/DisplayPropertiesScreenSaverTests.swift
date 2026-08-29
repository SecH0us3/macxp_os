import XCTest
@testable import MacXP

final class DisplayPropertiesScreenSaverTests: XCTestCase {
    func testScreenSaverManagerDefaultsAndProperties() {
        let manager = ScreenSaverManager.shared
        manager.selectedType = .pipes3D
        manager.waitMinutes = 5
        XCTAssertEqual(manager.selectedType, .pipes3D)
        XCTAssertEqual(manager.waitMinutes, 5)
    }

    func testScreenSaverManagerPreviewAndDismiss() {
        let manager = ScreenSaverManager.shared
        manager.selectedType = .starfield
        manager.triggerFullScreenPreview()
        XCTAssertTrue(manager.isFullScreenActive)
        
        manager.dismissScreenSaver()
        XCTAssertFalse(manager.isFullScreenActive)
    }

    func testScreenSaverSettingsMutation() {
        let manager = ScreenSaverManager.shared
        manager.starfieldSettings.starCount = 800
        XCTAssertEqual(manager.starfieldSettings.starCount, 800)

        manager.pipesSettings.maxPipes = 6
        XCTAssertEqual(manager.pipesSettings.maxPipes, 6)
    }
}
