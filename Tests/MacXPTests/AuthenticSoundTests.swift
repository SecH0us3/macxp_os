import XCTest
@testable import MacXP

final class AuthenticSoundTests: XCTestCase {
    func testAllXPSoundCasesHaveWAVAssets() {
        let soundCases = XPSound.allCases
        XCTAssertGreaterThanOrEqual(soundCases.count, 13)
        for sound in soundCases {
            let data = SoundEffects.generateSoundData(for: sound)
            XCTAssertFalse(data.isEmpty, "Sound \(sound) must produce valid non-empty audio data")
            XCTAssertTrue(data.starts(with: "RIFF".utf8), "Sound data for \(sound) must be valid RIFF/WAVE header")
        }
    }

    func testSoundManagerPlaysAllSoundTypes() {
        let manager = SoundManager.shared
        manager.setVolume(1.0)
        manager.setMuted(false)
        
        manager.play(.startup)
        XCTAssertEqual(manager.lastPlayedSound, .startup)
        
        manager.play(.balloon)
        XCTAssertEqual(manager.lastPlayedSound, .balloon)
        
        manager.play(.recycle)
        XCTAssertEqual(manager.lastPlayedSound, .recycle)

        manager.play(.hardwareInsert)
        XCTAssertEqual(manager.lastPlayedSound, .hardwareInsert)
    }
}
