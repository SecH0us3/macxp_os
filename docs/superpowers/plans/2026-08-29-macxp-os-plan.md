# MacXP OS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS Swift application that faithfully recreates the Windows XP desktop environment (Luna Blue theme) with real macOS filesystem integration, start menu, taskbar, sound effects, and built-in apps (Explorer, Notepad, cmd.exe, Calculator, Minesweeper, Paint, Control Panel, Run).

**Architecture:** Pure SwiftUI for UI rendering with an injected `WindowManager` (`ObservableObject`) managing `XPWindowInstance` states. AppKit is used for the borderless fullscreen `NSWindow` container, keyboard events, and system APIs.

**Tech Stack:** Swift 5.9, SwiftUI, AppKit, AVFoundation, Process/Pipe (for cmd.exe), FileManager, NSWorkspace.

## Global Constraints

- Platform: macOS 13+
- Swift version: 5.9+
- Build system: Swift Package Manager (`swift build` / `swift run` / `swift test`)
- No heavy third-party UI libraries (pure native Swift/SwiftUI/AppKit).
- All terminal commands MUST be prefixed with `rtk`.
- Visual authenticity: Faithful Windows XP Luna Blue colors, 3D bevels, Tahoma typography, Bliss background, and pixel-precise UI layouts.

---

### Task 1: Project Scaffolding & Core Architecture
(Status: COMPLETED in commit 6612b47)

---

### Task 2: Window Manager & State Models
(Status: COMPLETED in commit 0401928)

---

### Task 3: Luna Blue Window Chrome Component
(Status: COMPLETED in commit 620c260)

---

### Task 4: Desktop Canvas, Start Menu, Taskbar & Context Menus

**Files:**
- Create: `Sources/MacXP/Views/Taskbar/TaskbarView.swift`
- Create: `Sources/MacXP/Views/Taskbar/StartButton.swift`
- Create: `Sources/MacXP/Views/Taskbar/StartMenu.swift`
- Create: `Sources/MacXP/Views/Taskbar/SystemTrayView.swift`
- Create: `Sources/MacXP/Views/Desktop/DesktopView.swift`
- Create: `Sources/MacXP/Views/Desktop/DesktopIconView.swift`
- Create: `Sources/MacXP/Views/Desktop/DesktopContextMenu.swift`
- Create: `Sources/MacXP/Views/Desktop/MarqueeSelection.swift`
- Modify: `Sources/MacXP/MacXPApp.swift`
- Create: `Tests/MacXPTests/DesktopAndTaskbarTests.swift`

**Interfaces:**
- Consumes: `WindowManager`, `XPWindowInstance`, `LunaWindowView`
- Produces: Complete interactive Windows XP desktop with:
  - Bliss wallpaper background (procedural / high-res vector/image).
  - Desktop icons: My Computer, My Documents, Recycle Bin, Internet Explorer, plus user's `~/Desktop` files.
  - Marquee drag selection box (`#316ac5` translucent fill with dotted/solid border).
  - Desktop right-click context menu (Arrange Icons By, Refresh, New -> Folder / Text Document, Properties).
  - Authentic Start Button with Windows flag logo, curved edge, green gradient.
  - Authentic Start Menu (User banner, 2-column layout: Pinned & Recent apps on left, System folders & Control Panel/Run on right, Log Off & Turn Off buttons at bottom).
  - Taskbar window tabs with active/depressed styles and click-to-minimize/restore.
  - System tray with real live macOS clock, volume popup slider, battery indicator.

- [ ] **Step 1: Write tests for Taskbar and Desktop models/views**
- [ ] **Step 2: Implement StartButton and StartMenu with XP Luna theme**
- [ ] **Step 3: Implement TaskbarView and SystemTrayView with live clock and volume control**
- [ ] **Step 4: Implement DesktopView, DesktopIconView, Marquee selection, and DesktopContextMenu**
- [ ] **Step 5: Run tests and verify all pass (`rtk swift test`)**
- [ ] **Step 6: Commit**

---

### Task 5: Windows Explorer (Проводник) & File Management

**Files:**
- Create: `Sources/MacXP/Services/FileSystemService.swift`
- Create: `Sources/MacXP/Views/Explorer/ExplorerWindowView.swift`
- Create: `Sources/MacXP/Views/Explorer/ExplorerToolbar.swift`
- Create: `Sources/MacXP/Views/Explorer/ExplorerAddressBar.swift`
- Create: `Sources/MacXP/Views/Explorer/ExplorerSidebar.swift`
- Create: `Sources/MacXP/Views/Explorer/ExplorerItemGrid.swift`
- Create: `Sources/MacXP/Views/Explorer/FileContextMenu.swift`
- Create: `Tests/MacXPTests/FileSystemServiceTests.swift`
- Create: `Tests/MacXPTests/ExplorerViewTests.swift`

**Interfaces:**
- Consumes: `WindowManager`, `LunaWindowView`
- Produces: Complete Windows Explorer with:
  - Top menu (`File`, `Edit`, `View`, `Favorites`, `Tools`, `Help`).
  - Toolbar: Back, Forward, Up, Search, Folders, Views dropdown (Tiles, Icons, List, Details) + XP flag logo.
  - Address Bar with editable path and green "Go" button.
  - Left Sidebar: "File and Folder Tasks", "Other Places", "Details" with preview.
  - Real macOS filesystem integration: navigate directories, open files via `NSWorkspace` or internal apps, create folders, rename files inline, delete to macOS Trash.
  - Right-click file context menu: Open, Explore, Open With (Notepad), Delete, Rename, Properties.

- [ ] **Step 1: Write tests for FileSystemService**
- [ ] **Step 2: Implement FileSystemService for macOS file operations**
- [ ] **Step 3: Implement Explorer toolbar, address bar, sidebar, and grid views**
- [ ] **Step 4: Implement FileContextMenu and file operations (create folder, rename, trash)**
- [ ] **Step 5: Run tests and verify all pass (`rtk swift test`)**
- [ ] **Step 6: Commit**

---

### Task 6: Built-in XP Applications

**Files:**
- Create: `Sources/MacXP/Views/Apps/NotepadView.swift`
- Create: `Sources/MacXP/Views/Apps/CmdView.swift`
- Create: `Sources/MacXP/Views/Apps/CalculatorView.swift`
- Create: `Sources/MacXP/Views/Apps/MinesweeperView.swift`
- Create: `Sources/MacXP/Views/Apps/PaintView.swift`
- Create: `Sources/MacXP/Views/Apps/ControlPanelView.swift`
- Create: `Sources/MacXP/Views/Apps/SystemPropertiesView.swift`
- Create: `Sources/MacXP/Views/Apps/RunDialogView.swift`
- Create: `Sources/MacXP/Services/ShellService.swift`
- Create: `Tests/MacXPTests/BuiltinAppsTests.swift`

**Interfaces:**
- Consumes: `WindowManager`, `XPAppType`, `LunaWindowView`
- Produces:
  - **Notepad:** Real text editor with File/Edit menus, status bar, open/save files.
  - **cmd.exe:** Connected to macOS `zsh` via `Process`/`Pipe` with DOS command aliases (`dir`, `cls`, `ver`, `cd`, `echo`).
  - **Calculator:** Standard XP calculator with memory functions and keyboard support.
  - **Minesweeper:** Complete game with smiley face reactions, 7-segment LED counters, beginner/intermediate/expert modes.
  - **Paint:** Canvas drawing tool with pencil, brush, eraser, shapes, and 28-color palette.
  - **Control Panel & System Properties:** Real Mac specs displayed in classic XP dialog.
  - **Run Dialog:** Launch apps, URLs, or file paths.

- [ ] **Step 1: Write tests for ShellService and Builtin Apps**
- [ ] **Step 2: Implement ShellService for cmd.exe zsh integration**
- [ ] **Step 3: Implement Notepad, cmd.exe, Calculator, Minesweeper, Paint, Control Panel, Run Dialog**
- [ ] **Step 4: Integrate apps into WindowManager and Start Menu dispatch**
- [ ] **Step 5: Run tests and verify all pass (`rtk swift test`)**
- [ ] **Step 6: Commit**

---

### Task 7: Sound Engine, Hotkeys & System Integration

**Files:**
- Create: `Sources/MacXP/Services/SoundManager.swift`
- Create: `Sources/MacXP/Services/HotkeyManager.swift`
- Create: `Sources/MacXP/Resources/SoundEffects.swift`
- Create: `Tests/MacXPTests/SoundAndHotkeyTests.swift`

**Interfaces:**
- Consumes: `WindowManager`
- Produces:
  - Sound effects: Startup chime, folder navigation click, error chord, exclamation ding, shutdown chime.
  - Hotkeys: `Cmd`/`Win` (Start menu), `Win+E` (Explorer), `Win+D` (Show desktop), `Win+R` (Run dialog), `Alt+F4` (Close window), `Alt+Tab` (Task switcher HUD).
  - Fullscreen toggle (`F11` / `Cmd+Ctrl+F`) and Turn Off Computer dialog.

- [ ] **Step 1: Write tests for SoundManager and HotkeyManager**
- [ ] **Step 2: Implement SoundManager with synthesized/bundled authentic XP sound waveforms**
- [ ] **Step 3: Implement HotkeyManager with NSEvent monitor for global shortcuts**
- [ ] **Step 4: Implement Alt+Tab task switcher HUD and Turn Off Computer dialog**
- [ ] **Step 5: Run tests and verify all pass (`rtk swift test`)**
- [ ] **Step 6: Commit**

---

### Task 8: App Packaging, Assets & DMG Build Script

**Files:**
- Create: `scripts/build_app.sh`
- Create: `scripts/build_dmg.sh`
- Create: `Makefile`
- Create: `Resources/Info.plist`
- Create: `Resources/AppIcon.icns`
- Create: `README.md`
- Create: `Tests/MacXPTests/PackagingTests.swift`

**Interfaces:**
- Produces:
  - Standalone macOS `.app` bundle (`MacXP.app`).
  - Distributable `.dmg` disk image with Applications shortcut.
  - Simple `make app` and `make dmg` commands.

- [ ] **Step 1: Create Info.plist and Makefile**
- [ ] **Step 2: Create build_app.sh and build_dmg.sh scripts**
- [ ] **Step 3: Test build process and verify DMG generation**
- [ ] **Step 4: Write comprehensive README.md with usage and shortcuts**
- [ ] **Step 5: Commit and verify full build**
