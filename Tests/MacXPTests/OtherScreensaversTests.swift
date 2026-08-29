import XCTest
@testable import MacXP

final class OtherScreensaversTests: XCTestCase {
    func testMystifyPolygonMotionAndBounds() {
        var poly = MystifyPolygon(vertexCount: 4, bounds: CGSize(width: 800, height: 600))
        XCTAssertEqual(poly.vertices.count, 4)
        let initialX = poly.vertices[0].x
        poly.step(bounds: CGSize(width: 800, height: 600))
        XCTAssertNotEqual(poly.vertices[0].x, initialX)
    }

    func testXP3DLogoStateAndRotation() {
        var state = XP3DLogoState(bounds: CGSize(width: 800, height: 600))
        let initialAngle = state.rotationAngle
        state.update(deltaTime: 0.05, bounds: CGSize(width: 800, height: 600))
        XCTAssertNotEqual(state.rotationAngle, initialAngle)
    }
}
