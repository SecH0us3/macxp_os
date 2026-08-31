import XCTest
@testable import MacXP

final class PinballTests: XCTestCase {
    
    func testPinballAppTypeProperties() {
        let app = XPAppType.pinball
        XCTAssertEqual(app.defaultTitle, "3D Pinball for Windows - Space Cadet")
        XCTAssertEqual(app.defaultIcon, "pinball")
        XCTAssertEqual(app.defaultSize.width, 520)
        XCTAssertEqual(app.defaultSize.height, 640)
    }
    
    func testSolitaireAppTypeProperties() {
        let app = XPAppType.solitaire
        XCTAssertEqual(app.defaultTitle, "Solitaire")
        XCTAssertEqual(app.defaultIcon, "solitaire")
        XCTAssertEqual(app.defaultSize.width, 680)
        XCTAssertEqual(app.defaultSize.height, 520)
    }
    
    func testRunDialogResolvesGames() {
        let engine = RunDialogEngine()
        
        XCTAssertEqual(engine.resolveCommand("pinball"), .openApp(.pinball))
        XCTAssertEqual(engine.resolveCommand("pinball.exe"), .openApp(.pinball))
        XCTAssertEqual(engine.resolveCommand("spacecadet"), .openApp(.pinball))
        
        XCTAssertEqual(engine.resolveCommand("sol"), .openApp(.solitaire))
        XCTAssertEqual(engine.resolveCommand("sol.exe"), .openApp(.solitaire))
        XCTAssertEqual(engine.resolveCommand("solitaire"), .openApp(.solitaire))
    }
    
    func testPinballScenePhysicsSetup() {
        let scene = PinballScene(size: CGSize(width: 480, height: 560))
        XCTAssertEqual(scene.physicsWorld.gravity.dy, -9.8, accuracy: 0.1)
    }
}
