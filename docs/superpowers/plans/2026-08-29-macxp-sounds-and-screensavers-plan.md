# MacXP Authentic Sounds & 3D Screensavers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the complete authentic Windows XP WAV sound scheme with genuine audio files and the full suite of 5 classic Windows XP screensavers (3D Pipes, Starfield, Windows XP 3D Logo, Mystify, Blank) with real-time CRT mini-preview in Display Properties, settings dialogs, and idle-time activation.

**Architecture:**
- **Sound Subsystem:** Bundle authentic 16-bit 44.1kHz WAV assets in `Resources/Sounds/` and update `SoundManager` to load and cache them via `AVAudioPlayer`, connecting them to all OS events (startup, shutdown, navigation, errors, trash, balloons).
- **Screensaver Engine:** A modular `ScreenSaverType` enum and `ScreenSaverRenderer` protocols with SwiftUI / Canvas rendering for 3D Pipes, Starfield, Windows XP 3D Logo, Mystify, and Blank.
- **Display Properties & Settings:** Integrate the Screen Saver tab into `DisplayPropertiesView` with a CRT monitor live mini-viewport, "Settings..." dialog per screensaver, "Preview" full-screen mode, and an idle-timer `ScreenSaverManager` with mouse/keyboard wake-up detection.

**Tech Stack:** Swift 5.9, SwiftUI, AppKit, AVFoundation, Canvas / Geometry2D / SceneKit, XCTest.

## Global Constraints
- Platform: macOS 13+
- Swift version: 5.9+
- Build system: Swift Package Manager (`swift build`, `swift test`)
- All shell commands MUST be prefixed with `rtk` (e.g. `rtk swift test`, `rtk make app`, `rtk make dmg`)
- Zero external third-party heavy dependencies; use native Apple frameworks (AVFoundation, SwiftUI, AppKit, Canvas).
- Strict visual and auditory authenticity to Windows XP Luna Blue (Tahoma typography, 3D bevels, classic palettes, pixel precision).

---

### Task 1: Authentic Windows XP WAV Sound Pack & SoundManager Integration

**Files:**
- Create: `Resources/Sounds/` (directory with 12 authentic Windows XP WAV files)
- Modify: `Sources/MacXP/Services/SoundManager.swift`
- Modify: `Sources/MacXP/Resources/SoundEffects.swift`
- Modify: `Sources/MacXP/Resources/XPAssetProvider.swift`
- Modify: `scripts/build_app.sh`
- Test: `Tests/MacXPTests/AuthenticSoundTests.swift`

---

### Task 2: Core Screensaver Engine & Starfield Simulation

**Files:**
- Create: `Sources/MacXP/Screensavers/ScreenSaverModel.swift`
- Create: `Sources/MacXP/Screensavers/StarfieldScreenSaverView.swift`
- Test: `Tests/MacXPTests/ScreenSaverTests.swift`

---

### Task 3: 3D Pipes Screensaver (Трубопровод 3D)

**Files:**
- Create: `Sources/MacXP/Screensavers/Pipes3DScreenSaverView.swift`
- Modify: `Sources/MacXP/Screensavers/ScreenSaverModel.swift`
- Test: `Tests/MacXPTests/Pipes3DTests.swift`

---

### Task 4: Windows XP 3D Logo, Mystify & Blank Screensavers

**Files:**
- Create: `Sources/MacXP/Screensavers/XP3DLogoScreenSaverView.swift`
- Create: `Sources/MacXP/Screensavers/MystifyScreenSaverView.swift`
- Create: `Sources/MacXP/Screensavers/BlankScreenSaverView.swift`
- Modify: `Sources/MacXP/Screensavers/ScreenSaverModel.swift`
- Test: `Tests/MacXPTests/OtherScreensaversTests.swift`

---

### Task 5: Display Properties Screen Saver Tab, Settings Modals & Idle Manager

**Files:**
- Create: `Sources/MacXP/Services/ScreenSaverManager.swift`
- Create: `Sources/MacXP/Views/Screensaver/ScreenSaverSettingsDialog.swift`
- Create: `Sources/MacXP/Views/Screensaver/FullScreenSaverOverlay.swift`
- Modify: `Sources/MacXP/Views/Apps/DisplayPropertiesView.swift`
- Modify: `Sources/MacXP/Views/Desktop/DesktopView.swift`
- Test: `Tests/MacXPTests/DisplayPropertiesScreenSaverTests.swift`

---

### Task 6: System-wide Sound Events Wiring, Final Packaging & Verification

**Files:**
- Modify: `Sources/MacXP/Views/Desktop/DesktopView.swift`
- Modify: `Sources/MacXP/Views/Taskbar/TaskbarView.swift`
- Modify: `Sources/MacXP/Views/Taskbar/StartMenu.swift`
- Modify: `Sources/MacXP/Views/Apps/ExplorerWindowView.swift`
- Modify: `Sources/MacXP/Views/Apps/RunDialogView.swift`
- Modify: `Sources/MacXP/Views/TurnOffDialogView.swift`
- Modify: `README.md`
- Test: `Tests/MacXPTests/PackagingTests.swift`
