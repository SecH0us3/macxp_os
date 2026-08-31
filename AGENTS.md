# AGENTS.md — Autonomous Agent Guidelines for MacXP

Welcome to **MacXP**, a native macOS application recreating the Microsoft Windows XP Luna Blue desktop environment using Swift and SwiftUI.

This document establishes operational rules, architecture references, and development workflows for AI coding assistants and autonomous agents.

---

## 🛠️ Tech Stack & Constraints

- **Platform:** macOS 13.0+ (Ventura, Sonoma, Sequoia).
- **Language & Runtime:** Swift 5.9+ / Swift Package Manager (SPM).
- **UI Frameworks:** SwiftUI + AppKit integration (where custom window handling, screensavers, or key monitors are required).
- **Audio:** `AVFoundation` + in-memory 44.1kHz PCM RIFF/WAVE synthesis fallback in `SoundEffects.swift`.
- **Third-Party Dependencies:** Zero heavy UI dependencies. Keep the binary standalone and lightweight.

---

## ⚡ Critical Operational Rules

### 1. RTK - Rust Token Killer Integration
All shell commands **MUST** be prefixed with `rtk` (e.g. `rtk swift test`, `rtk make app`, `rtk make dmg`, `rtk git status`, `rtk git add`, `rtk git commit`) to minimize token consumption.

### 2. Test-Driven Development & Verification
- Always write or update unit tests in `Tests/MacXPTests/` for any new feature or bugfix.
- Verify that **100% of tests pass** (`rtk swift test`) before claiming completion.
- When modifying build scripts or bundle packaging, run `rtk make app` and `rtk make dmg`.

### 3. Dynamic User Path Resolution
- **NEVER hardcode local developer paths** (e.g., `/Users/username/...`).
- Always resolve paths dynamically using `FileManager.default.homeDirectoryForCurrentUser`, `NSUserName()`, `NSHomeDirectory()`, or `URL(fileURLWithPath:)`.

### 4. Authenticity & Design Fidelity
- Maintain pixel-perfect Windows XP Luna Blue aesthetic:
  - **Colors:** Classic Luna Blue titlebars (`#0055ea` $\\rightarrow$ `#0a64dc` $\\rightarrow$ `#1c7fed`), Taskbar (`#1f2f86` $\\rightarrow$ `#1941a5`), Start button (`#388438` $\\rightarrow$ `#1a561a`), Window background (`#ece9d8`).
  - **Fonts:** Tahoma / Segoe UI / San Francisco with crisp font sizes (11pt-13pt).
  - **Icons:** Use `XPAssetProvider` to load authentic XP icons (`my_computer`, `drive_harddisk`, `flash`, `minesweeper`, `ie`, etc.).

---

## 🏗️ Codebase Layout

```text
macxp_os/
├── Package.swift                    # Swift Package Manager manifest
├── Makefile                         # Automation targets (all, build, test, app, dmg, run, clean)
├── Sources/
│   └── MacXP/
│       ├── MacXPApp.swift           # Main SwiftUI App entry point & AppDelegate
│       ├── Models/                  # Window state (XPWindowInstance, XPAppType), file items
│       ├── Managers/                # Central WindowManager (z-ordering, focus, cascading)
│       ├── Services/                # System services (FileSystemService, ShellService, SoundManager, HotkeyManager)
│       ├── Screensavers/            # 3D Pipes, Starfield, Mystify, XP 3D Logo screensavers
│       ├── Resources/               # XPAssetProvider, SoundEffects, Info.plist, Icons, Sounds
│       └── Views/                   # UI Components (LunaWindowView, TaskbarView, StartMenu, DesktopView, Apps)
├── Tests/
│   └── MacXPTests/                  # Comprehensive unit test suite (144+ tests)
├── Resources/                       # Original image assets, PNG icons, WAV/MP3 sound effects
├── docs/                            # GitHub Pages website, specification documents, plans
└── scripts/
    ├── build_app.sh                 # Release .app bundle packager with ad-hoc codesign
    └── build_dmg.sh                 # Compressed .dmg disk image creator with /Applications symlink
```

---

## 🚀 Key Commands

| Task | Command |
| :--- | :--- |
| **Run All Tests** | `rtk swift test` |
| **Run Specific Test** | `rtk swift test --filter <TestClass>/<testMethod>` |
| **Build App Bundle** | `rtk make app` (outputs `build/MacXP.app`) |
| **Build Distributable DMG** | `rtk make dmg` (outputs `build/MacXP.dmg`) |
| **Launch App Locally** | `rtk make run` or `rtk swift run MacXP` |
| **Check Git Status** | `rtk git status` |

---

## 🛡️ License & Trademarks

- Source code is released under the **MIT License**.
- Windows XP, Luna, and related assets are trademarks of Microsoft Corporation.
- Macromedia and Flash are trademarks of Adobe Systems Inc.
