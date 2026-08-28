import XCTest
import SwiftUI
@testable import MacXP

final class SoundAndHotkeyTests: XCTestCase {

    // MARK: - 1. SoundEffects Synthesizer Tests

    func testSoundEffectsWAVGeneration() {
        for sound in XPSound.allCases {
            let wavData = XPSoundSynthesizer.generateWAV(for: sound)
            XCTAssertFalse(wavData.isEmpty, "Generated WAV data for \(sound) should not be empty")
            
            // Check RIFF WAVE header (first 4 bytes "RIFF", bytes 8-11 "WAVE")
            XCTAssertGreaterThanOrEqual(wavData.count, 44, "WAV data must contain at least a 44-byte header")
            let riffString = String(data: wavData.subdata(in: 0..<4), encoding: .ascii)
            let waveString = String(data: wavData.subdata(in: 8..<12), encoding: .ascii)
            XCTAssertEqual(riffString, "RIFF")
            XCTAssertEqual(waveString, "WAVE")
        }
    }

    func testSoundEnumAllCases() {
        let expectedCases: [XPSound] = [.startup, .shutdown, .navigation, .error, .exclamation, .recycleBin]
        XCTAssertEqual(XPSound.allCases.count, expectedCases.count)
        for sound in expectedCases {
            XCTAssertTrue(XPSound.allCases.contains(sound))
        }
    }

    // MARK: - 2. SoundManager Tests

    func testSoundManagerDefaultState() {
        let soundManager = SoundManager.shared
        XCTAssertGreaterThanOrEqual(soundManager.volume, 0.0)
        XCTAssertLessThanOrEqual(soundManager.volume, 1.0)
        XCTAssertFalse(soundManager.isMuted)
        XCTAssertTrue(soundManager.isEnabled)
    }

    func testSoundManagerVolumeClamping() {
        let soundManager = SoundManager()
        
        soundManager.setVolume(1.5)
        XCTAssertEqual(soundManager.volume, 1.0)
        
        soundManager.setVolume(-0.5)
        XCTAssertEqual(soundManager.volume, 0.0)
        
        soundManager.setVolume(0.65)
        XCTAssertEqual(soundManager.volume, 0.65)
    }

    func testSoundManagerMuteToggling() {
        let soundManager = SoundManager()
        XCTAssertFalse(soundManager.isMuted)
        
        soundManager.toggleMute()
        XCTAssertTrue(soundManager.isMuted)
        
        soundManager.toggleMute()
        XCTAssertFalse(soundManager.isMuted)
        
        soundManager.setMuted(true)
        XCTAssertTrue(soundManager.isMuted)
    }

    func testSoundManagerPlayUpdatesState() {
        let soundManager = SoundManager()
        let initialCount = soundManager.playCount
        
        soundManager.play(.startup)
        XCTAssertEqual(soundManager.lastPlayedSound, .startup)
        XCTAssertEqual(soundManager.playCount, initialCount + 1)
        
        soundManager.play(.navigation)
        XCTAssertEqual(soundManager.lastPlayedSound, .navigation)
        XCTAssertEqual(soundManager.playCount, initialCount + 2)
        
        soundManager.play(.error)
        XCTAssertEqual(soundManager.lastPlayedSound, .error)
        XCTAssertEqual(soundManager.playCount, initialCount + 3)
    }

    func testSoundManagerMutePreventsAudioPlayback() {
        let soundManager = SoundManager()
        soundManager.setMuted(true)
        
        let initialCount = soundManager.playCount
        soundManager.play(.recycleBin)
        
        XCTAssertEqual(soundManager.lastPlayedSound, .recycleBin)
        XCTAssertEqual(soundManager.playCount, initialCount + 1)
    }

    // MARK: - 3. HotkeyManager Tests

    func testHotkeyManagerShortcutParsing() {
        let hotkeyManager = HotkeyManager.shared
        
        // Win+E / Cmd+E -> Open Explorer
        let actionE = hotkeyManager.parseKey(
            keyCode: 14, // 'e'
            characters: "e",
            modifierFlags: .command
        )
        XCTAssertEqual(actionE, .openExplorer)
        
        // Win+D / Cmd+D -> Show Desktop
        let actionD = hotkeyManager.parseKey(
            keyCode: 2, // 'd'
            characters: "d",
            modifierFlags: .command
        )
        XCTAssertEqual(actionD, .showDesktop)
        
        // Win+R / Cmd+R -> Open Run Dialog
        let actionR = hotkeyManager.parseKey(
            keyCode: 15, // 'r'
            characters: "r",
            modifierFlags: .command
        )
        XCTAssertEqual(actionR, .openRunDialog)
        
        // Cmd+W -> Close Active Window
        let actionW = hotkeyManager.parseKey(
            keyCode: 13, // 'w'
            characters: "w",
            modifierFlags: .command
        )
        XCTAssertEqual(actionW, .closeActiveWindow)
        
        // Alt+F4 -> Close Active Window
        let actionF4 = hotkeyManager.parseKey(
            keyCode: 118, // F4
            characters: nil,
            modifierFlags: .option
        )
        XCTAssertEqual(actionF4, .closeActiveWindow)
        
        // Alt+Tab / Cmd+Tab -> Task Switcher Next
        let actionTab = hotkeyManager.parseKey(
            keyCode: 48, // Tab
            characters: "\t",
            modifierFlags: .option
        )
        XCTAssertEqual(actionTab, .taskSwitcherNext)
        
        // Shift+Alt+Tab / Shift+Cmd+Tab -> Task Switcher Previous
        let actionShiftTab = hotkeyManager.parseKey(
            keyCode: 48, // Tab
            characters: "\t",
            modifierFlags: [.option, .shift]
        )
        XCTAssertEqual(actionShiftTab, .taskSwitcherPrevious)
        
        // F11 -> Toggle Fullscreen
        let actionF11 = hotkeyManager.parseKey(
            keyCode: 103, // F11
            characters: nil,
            modifierFlags: []
        )
        XCTAssertEqual(actionF11, .toggleFullscreen)
        
        // Ctrl+Esc -> Toggle Start Menu
        let actionCtrlEsc = hotkeyManager.parseKey(
            keyCode: 53, // Escape
            characters: "\u{1b}",
            modifierFlags: .control
        )
        XCTAssertEqual(actionCtrlEsc, .toggleStartMenu)
    }

    func testHotkeyManagerTaskSwitcherCycle() {
        let hotkeyManager = HotkeyManager()
        
        hotkeyManager.startTaskSwitching(windowCount: 4)
        XCTAssertTrue(hotkeyManager.isTaskSwitcherVisible)
        XCTAssertEqual(hotkeyManager.taskSwitcherIndex, 1) // Initially selected second window (MRU)
        
        hotkeyManager.cycleTaskSwitcher(forward: true, windowCount: 4)
        XCTAssertEqual(hotkeyManager.taskSwitcherIndex, 2)
        
        hotkeyManager.cycleTaskSwitcher(forward: true, windowCount: 4)
        XCTAssertEqual(hotkeyManager.taskSwitcherIndex, 3)
        
        // Wraparound forward
        hotkeyManager.cycleTaskSwitcher(forward: true, windowCount: 4)
        XCTAssertEqual(hotkeyManager.taskSwitcherIndex, 0)
        
        // Backward cycle
        hotkeyManager.cycleTaskSwitcher(forward: false, windowCount: 4)
        XCTAssertEqual(hotkeyManager.taskSwitcherIndex, 3)
        
        hotkeyManager.cancelTaskSwitcher()
        XCTAssertFalse(hotkeyManager.isTaskSwitcherVisible)
    }

    func testHotkeyManagerTaskSwitcherConfirmFocusesWindow() {
        let hotkeyManager = HotkeyManager()
        let windowManager = WindowManager()
        let win1 = windowManager.openWindow(appType: .notepad(fileURL: nil))
        let _ = windowManager.openWindow(appType: .calculator)
        let _ = windowManager.openWindow(appType: .cmd)
        
        hotkeyManager.startTaskSwitching(windowCount: windowManager.windows.count)
        hotkeyManager.taskSwitcherIndex = 0 // win1
        
        hotkeyManager.confirmTaskSwitcher(windowManager: windowManager)
        XCTAssertFalse(hotkeyManager.isTaskSwitcherVisible)
        XCTAssertTrue(windowManager.window(for: win1)?.isFocused ?? false)
    }

    // MARK: - 4. Turn Off Dialog Logic & Model Tests

    func testTurnOffDialogModelActions() {
        let windowManager = WindowManager()
        _ = windowManager.openWindow(appType: .notepad(fileURL: nil))
        _ = windowManager.openWindow(appType: .calculator)
        XCTAssertEqual(windowManager.windows.count, 2)
        
        var didStandBy = false
        var didTurnOff = false
        var didRestart = false
        
        let turnOffModel = TurnOffDialogModel(
            onStandBy: { didStandBy = true },
            onTurnOff: { didTurnOff = true },
            onRestart: { didRestart = true }
        )
        
        turnOffModel.standBy()
        XCTAssertTrue(didStandBy)
        
        turnOffModel.restart(windowManager: windowManager)
        XCTAssertTrue(didRestart)
        XCTAssertEqual(windowManager.windows.count, 0) // Restart resets windows
        
        turnOffModel.turnOff()
        XCTAssertTrue(didTurnOff)
        XCTAssertEqual(SoundManager.shared.lastPlayedSound, .shutdown)
    }

    // MARK: - 5. Calculator Keyboard Input Tests

    func testCalculatorKeyboardInputHandling() {
        let calc = CalculatorEngine()
        
        // Type "4", "2", "+", "8", "=" -> 50
        calc.handleKeyInput("4")
        calc.handleKeyInput("2")
        XCTAssertEqual(calc.displayValue, "42")
        
        calc.handleKeyInput("+")
        calc.handleKeyInput("8")
        XCTAssertEqual(calc.displayValue, "8")
        
        calc.handleKeyInput("=")
        XCTAssertEqual(calc.displayValue, "50")
        
        // Test backspace key input
        calc.handleKeyInput("1")
        calc.handleKeyInput("5")
        calc.handleKeyInput("\u{7f}") // Backspace
        XCTAssertEqual(calc.displayValue, "1")
        
        // Test clear key input
        calc.handleKeyInput("c")
        XCTAssertEqual(calc.displayValue, "0")
        
        // Test Enter key as '='
        calc.handleKeyInput("9")
        calc.handleKeyInput("*")
        calc.handleKeyInput("3")
        calc.handleKeyInput("\r")
        XCTAssertEqual(calc.displayValue, "27")
    }

    // MARK: - 6. System Integration Tests

    func testSystemTrayAndSoundManagerSync() {
        let soundManager = SoundManager.shared
        let trayModel = SystemTrayModel()
        
        // Sync volume
        trayModel.setVolume(0.4)
        soundManager.setVolume(0.4)
        XCTAssertEqual(trayModel.volumeLevel, 0.4)
        XCTAssertEqual(soundManager.volume, 0.4)
        
        // Sync mute
        trayModel.toggleMute()
        soundManager.setMuted(trayModel.isMuted)
        XCTAssertEqual(trayModel.isMuted, soundManager.isMuted)
    }

    func testHotkeyManagerTaskSwitcherNavigationKeys() {
        let hotkeyManager = HotkeyManager()
        hotkeyManager.startTaskSwitching(windowCount: 3)
        
        // When task switcher is visible, Esc cancels
        let escAction = hotkeyManager.parseKey(keyCode: 53, characters: nil, modifierFlags: [])
        XCTAssertEqual(escAction, .taskSwitcherCancel)
        
        // Return confirms
        let returnAction = hotkeyManager.parseKey(keyCode: 36, characters: nil, modifierFlags: [])
        XCTAssertEqual(returnAction, .taskSwitcherConfirm)
        
        // Space confirms
        let spaceAction = hotkeyManager.parseKey(keyCode: 49, characters: nil, modifierFlags: [])
        XCTAssertEqual(spaceAction, .taskSwitcherConfirm)
        
        // Tab navigates
        let tabAction = hotkeyManager.parseKey(keyCode: 48, characters: nil, modifierFlags: [])
        XCTAssertEqual(tabAction, .taskSwitcherNext)
        
        let shiftTabAction = hotkeyManager.parseKey(keyCode: 48, characters: nil, modifierFlags: .shift)
        XCTAssertEqual(shiftTabAction, .taskSwitcherPrevious)
    }

    func testHotkeyManagerTaskSwitcherBoundaryConditions() {
        let hotkeyManager = HotkeyManager()
        
        // 0 windows
        hotkeyManager.startTaskSwitching(windowCount: 0)
        XCTAssertFalse(hotkeyManager.isTaskSwitcherVisible)
        
        // 1 window
        hotkeyManager.startTaskSwitching(windowCount: 1)
        XCTAssertTrue(hotkeyManager.isTaskSwitcherVisible)
        XCTAssertEqual(hotkeyManager.taskSwitcherIndex, 0)
        
        // Cycle 1 window stays at 0
        hotkeyManager.cycleTaskSwitcher(forward: true, windowCount: 1)
        XCTAssertEqual(hotkeyManager.taskSwitcherIndex, 0)
    }

    func testSoundManagerStopAll() {
        let soundManager = SoundManager()
        soundManager.play(.startup)
        soundManager.stopAll()
        XCTAssertEqual(soundManager.lastPlayedSound, .startup)
    }

    func testCalculatorKeyboardAdvancedOperations() {
        let calc = CalculatorEngine()
        
        // Sqrt with '@'
        calc.handleKeyInput("1")
        calc.handleKeyInput("6")
        calc.handleKeyInput("@")
        XCTAssertEqual(calc.displayValue, "4")
        
        // Reciprocal with 'r'
        calc.clearAll()
        calc.handleKeyInput("5")
        calc.handleKeyInput("r")
        XCTAssertEqual(calc.displayValue, "0.2")
        
        // Percentage with '%'
        calc.clearAll()
        calc.handleKeyInput("5")
        calc.handleKeyInput("0")
        calc.handleKeyInput("%")
        XCTAssertEqual(calc.displayValue, "0.5")
        
        // Negate with 'n'
        calc.clearAll()
        calc.handleKeyInput("7")
        calc.handleKeyInput("n")
        XCTAssertEqual(calc.displayValue, "-7")
    }
}
