import XCTest
@testable import MacXP

final class ScreenSaverTests: XCTestCase {
    func testScreenSaverTypesAndTitles() {
        let types = ScreenSaverType.allCases
        XCTAssertTrue(types.contains(.pipes3D))
        XCTAssertTrue(types.contains(.starfield))
        XCTAssertTrue(types.contains(.xp3DLogo))
        XCTAssertTrue(types.contains(.mystify))
        XCTAssertTrue(types.contains(.blank))
        XCTAssertTrue(types.contains(.none))

        XCTAssertEqual(ScreenSaverType.pipes3D.title, "3D Pipes")
        XCTAssertEqual(ScreenSaverType.starfield.title, "Starfield")
        XCTAssertEqual(ScreenSaverType.xp3DLogo.title, "Windows XP 3D")
        XCTAssertEqual(ScreenSaverType.mystify.title, "Mystify")
        XCTAssertEqual(ScreenSaverType.blank.title, "Blank Screen")
    }

    func testStarfieldSettingsAndMotion() {
        var settings = StarfieldSettings()
        XCTAssertEqual(settings.starCount, 400)
        XCTAssertEqual(settings.speed, 10.0)

        settings.starCount = 1000
        settings.speed = 25.0
        XCTAssertEqual(settings.starCount, 1000)
        XCTAssertEqual(settings.speed, 25.0)

        var engine = StarfieldEngine(settings: settings)
        XCTAssertEqual(engine.stars.count, 1000)
        let initialZ = engine.stars[0].z
        engine.update(deltaTime: 0.05)
        XCTAssertNotEqual(engine.stars[0].z, initialZ)
    }
}
