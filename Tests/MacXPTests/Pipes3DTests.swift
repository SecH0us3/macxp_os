import XCTest
@testable import MacXP

final class Pipes3DTests: XCTestCase {
    func testPipes3DSettingsDefaults() {
        let settings = Pipes3DSettings()
        XCTAssertEqual(settings.jointType, .mixed)
        XCTAssertGreaterThan(settings.maxPipes, 0)
        XCTAssertEqual(settings.pipeRadius, 8.0)
    }

    func testPipes3DEngineStepAndGrowth() {
        var engine = Pipes3DEngine(settings: Pipes3DSettings(maxPipes: 4))
        XCTAssertEqual(engine.pipes.count, 4)
        let initialSegmentsCount = engine.pipes[0].segments.count
        engine.step()
        XCTAssertGreaterThanOrEqual(engine.pipes[0].segments.count, initialSegmentsCount)
    }
}
