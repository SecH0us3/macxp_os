import XCTest
@testable import MacXP

final class MediaPlayerTests: XCTestCase {

    func testMediaPlayerAppTypeProperties() {
        let app = XPAppType.mediaPlayer(fileURL: nil)
        XCTAssertEqual(app.defaultTitle, "Windows Media Player")
        XCTAssertEqual(app.defaultIcon, "play.rectangle.fill")
        XCTAssertEqual(app.defaultSize.width, 720)
        XCTAssertEqual(app.defaultSize.height, 500)
    }

    func testMediaPlayerViewModelInitialization() {
        let vm = MediaPlayerViewModel()
        XCTAssertFalse(vm.playlist.isEmpty, "Should have default sample tracks (David Byrne, XP Title, Beethoven)")
        XCTAssertNotNil(vm.currentTrack)
        XCTAssertEqual(vm.visualizerMode, .barsAndWaves)
        XCTAssertEqual(vm.playbackState, .stopped)
    }

    func testMediaPlayerPlaybackStateTransitions() {
        let vm = MediaPlayerViewModel()
        
        vm.play()
        XCTAssertEqual(vm.playbackState, .playing)
        
        vm.pause()
        XCTAssertEqual(vm.playbackState, .paused)
        
        vm.play()
        XCTAssertEqual(vm.playbackState, .playing)
        
        vm.stop()
        XCTAssertEqual(vm.playbackState, .stopped)
        XCTAssertEqual(vm.currentTime, 0)
    }

    func testMediaPlayerPlaylistNavigation() {
        let vm = MediaPlayerViewModel()
        guard vm.playlist.count >= 2 else {
            XCTFail("Should have at least 2 tracks")
            return
        }

        let first = vm.playlist[0]
        let second = vm.playlist[1]

        vm.selectTrack(at: 0)
        XCTAssertEqual(vm.currentTrack?.id, first.id)

        vm.nextTrack()
        XCTAssertEqual(vm.currentTrack?.id, second.id)

        vm.previousTrack()
        XCTAssertEqual(vm.currentTrack?.id, first.id)
    }

    func testMediaPlayerVisualizerCycle() {
        let vm = MediaPlayerViewModel()
        let initialMode = vm.visualizerMode

        vm.nextVisualizerMode()
        XCTAssertNotEqual(vm.visualizerMode, initialMode)

        vm.previousVisualizerMode()
        XCTAssertEqual(vm.visualizerMode, initialMode)
    }

    func testMediaPlayerAddLocalFile() {
        let vm = MediaPlayerViewModel()
        let initialCount = vm.playlist.count
        let testURL = URL(fileURLWithPath: "/Users/test/Music/song.mp3")

        vm.addTrack(url: testURL, title: "Custom Song")
        XCTAssertEqual(vm.playlist.count, initialCount + 1)
        XCTAssertEqual(vm.playlist.last?.title, "Custom Song")
    }

    func testRunDialogResolvesWMP() {
        let engine = RunDialogEngine()
        XCTAssertEqual(engine.resolveCommand("wmplayer"), .openApp(.mediaPlayer(fileURL: nil)))
        XCTAssertEqual(engine.resolveCommand("wmplayer.exe"), .openApp(.mediaPlayer(fileURL: nil)))
        XCTAssertEqual(engine.resolveCommand("wmp"), .openApp(.mediaPlayer(fileURL: nil)))
        XCTAssertEqual(engine.resolveCommand("mplayer2"), .openApp(.mediaPlayer(fileURL: nil)))
    }
}
