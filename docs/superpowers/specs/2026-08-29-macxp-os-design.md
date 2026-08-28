# MacXP OS — Native Windows XP Experience for macOS
## Design Specification

- **Date:** 2026-08-29
- **Platform:** macOS 13+ (Apple Silicon & Intel)
- **Tech Stack:** Swift, SwiftUI, AppKit, AVFoundation, Foundation Process/FileManager

---

## 1. Executive Summary

MacXP OS is a standalone, high-performance, native macOS application designed to faithfully recreate the nostalgic Windows XP experience (Luna Blue theme) while deeply integrating with real macOS system capabilities (filesystem, app launching, terminal execution, system metrics, audio). It starts in immersive fullscreen mode by default, transforming the Mac into a fully interactive Windows XP desktop.

---

## 2. Architectural Overview

### 2.1 Technology Stack
- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI for declarative views & state management + AppKit for native windowing, mouse cursor manipulation, and system-level hotkey integration.
- **Audio:** `AVFoundation` / `NSSound` for authentic XP sound effects.
- **Filesystem & Process:** `FileManager`, `NSWorkspace`, `Process`, and `Pipe` for real macOS interaction.
- **Project Structure:** Standalone Swift Package / macOS App with zero heavy third-party dependencies.

### 2.2 Core Subsystems

```
┌─────────────────────────────────────────────────────────────┐
│                       MacXP Desktop                         │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                    WindowManager                      │  │
│  │  ┌─────────────────┐ ┌───────────────┐ ┌────────────┐ │  │
│  │  │ Explorer (File) │ │  cmd.exe      │ │ Notepad    │ │  │
│  │  └─────────────────┘ └───────────────┘ └────────────┘ │  │
│  │  ┌─────────────────┐ ┌───────────────┐ ┌────────────┐ │  │
│  │  │ Calculator      │ │ Minesweeper   │ │ Paint      │ │  │
│  │  └─────────────────┘ └───────────────┘ └────────────┘ │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                      Taskbar                          │  │
│  │  [Start] [QuickLaunch]   [Window Tabs]     [SysTray]  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Detailed Component Specifications

### 3.1 Window Manager & Luna Blue Chrome
- **`XPWindowInstance` State Model:**
  - `id: UUID`: Unique window identifier.
  - `appType: XPAppType`: Discriminator (`.explorer(path)`, `.notepad(url?)`, `.cmd`, `.calculator`, `.minesweeper`, `.paint`, `.controlPanel`, `.systemProperties`, `.runDialog`).
  - `title: String`: Window caption with dynamic update.
  - `icon: String`: XP icon identifier.
  - `rect: CGRect`: Position and dimensions on desktop.
  - `state: WindowDisplayState`: `.normal`, `.minimized`, `.maximized`.
  - `zIndex: Double`: Layering order.
  - `isFocused: Bool`: Focus state determining title bar gradient.
  - `minSize: CGSize`: Minimum resize constraints.
- **Luna Chrome Rendering:**
  - Active Titlebar: Three-tier blue linear gradient with white glossy highlight stripe (`#0055ea` → `#0a64dc` → `#1c7fed`).
  - Inactive Titlebar: Desaturated slate-blue gradient (`#769bdf` → `#86a7e9`).
  - Window Controls:
    - Minimize (`_`): Embossed blue square with inset white line.
    - Maximize/Restore (`□` / `❐`): Embossed blue square with inset frame.
    - Close (`✕`): Red rounded bevel button (`#e04322` → `#d82d0e`) with hover glow and white bold cross.
  - Borders: 3-pixel XP frame with beveled highlights and 8-direction interactive resize handles.

### 3.2 Desktop & Filesystem Integration
- **Wallpaper:** High-resolution original "Bliss" (Sonoma green hill with fluffy clouds) scaled aspect-fill.
- **Desktop Icons:**
  - "My Computer", "My Documents", "Recycle Bin", "My Network Places", "Internet Explorer".
  - Real macOS files from user's `~/Desktop` directory.
- **Interactions:**
  - Marquee selection box (semi-transparent XP blue rectangle `#316ac5` with dotted/solid border).
  - Drag-and-drop icon rearrangement on a virtual desktop grid.
  - Context Menu: View (Large/Small Icons), Sort By (Name, Size, Type, Date), Refresh, New (Folder, Text Document), Properties.

### 3.3 Windows Explorer (Проводник)
- **Top Menu:** `File`, `Edit`, `View`, `Favorites`, `Tools`, `Help`.
- **XP Toolbar:**
  - Navigation: Back (with history stack), Forward, Up one directory level.
  - Actions: Search, Folders toggle, Views mode dropdown (Large Icons, Tiles, List, Details).
  - XP animated flag watermark in the upper right.
- **Address Bar:** "Address" label + editable directory path + green "Go" arrow button.
- **Left Sidebar (Classic Task Panes):**
  - Collapsible blue-headed panels with arrow toggle:
    - *File and Folder Tasks*: Create Folder, Rename, Delete, Share.
    - *Other Places*: My Computer, My Documents, Desktop, Network.
    - *Details*: Selected file icon, name, file size, modification date.
- **Main Viewport:**
  - Real macOS filesystem navigation starting at root, user home, or desktop.
  - Support for creating directories, renaming items inline, deleting (to macOS Trash with confirmation sound).
  - Double click folder: Enters folder with navigation click sound.
  - Double click file: Launches in XP Notepad if text-based, or launches via `NSWorkspace.shared.open()` for macOS apps/files.

### 3.4 Start Menu & Taskbar
- **Start Menu:**
  - Top header: User icon (avatar) and current macOS username.
  - Left column (White): Pinned Internet (browser) and E-mail, separator, recent programs list, "All Programs" flyout submenu.
  - Right column (Luna Blue tint): My Documents, My Pictures, My Music, My Computer, Control Panel, Search, Run...
  - Bottom bar: Log Off (yellow key icon) and Turn Off Computer (red power button).
- **Taskbar:**
  - "Start" Button: Green pill button (`#388238` → `#5c9f3b`) with Windows flag logo, curved right edge, and pressed/hover states.
  - Quick Launch toolbar: Show Desktop icon, Internet Explorer shortcut.
  - Window Buttons: Interactive tabs for open windows with active/depressed visual states and click-to-focus/minimize.
  - System Tray:
    - Interactive volume speaker (opens XP vertical volume slider).
    - Real macOS battery percentage and status icon.
    - Digital clock (`HH:mm a`) showing full date tooltip and opening XP Date & Time calendar window on click.

### 3.5 Built-in XP Applications
1. **Notepad:**
   - Full text editing area with Tahoma/Courier font, line wrap toggle, New/Open/Save/Save As/Exit file operations.
   - Status bar with Line & Column tracking.
2. **Command Prompt (`cmd.exe`):**
   - Authentic black CRT-style window with classic banner.
   - Connected to interactive macOS `zsh` sub-process.
   - Built-in DOS compatibility aliases: `dir`, `cls`, `cd`, `ver`, `echo`, `type`, `help`, `exit`.
3. **Calculator:**
   - Standard XP layout with memory keys (`MC`, `MR`, `MS`, `M+`), arithmetic, `sqrt`, `%`, `1/x`, keyboard input support.
4. **Minesweeper (`winmine.exe`):**
   - Classic smiley button with reaction faces (Smile, Surprised, Dead, Cool), 7-segment LED counters, Beginner/Intermediate/Expert grids, right-click flagging, victory/defeat detection.
5. **MS Paint:**
   - Classic drawing canvas with Pencil, Brush, Eraser, Line, Rectangle, Ellipse, 28-color palette, stroke size, and image export.
6. **Control Panel & System Properties:**
   - System Properties displaying authentic Windows XP specs overlaying real Mac CPU/RAM/OS information.
   - Date & Time properties with ticking analog clock and interactive calendar.
7. **Run Dialog:**
   - Classic prompt supporting `cmd`, `notepad`, `calc`, `paint`, `winmine`, `control`, `explorer`, URLs, and file paths.

### 3.6 Sound Engine & Hotkeys
- **Sound Effects:**
  - Startup: Windows XP Startup chime on launch.
  - Navigation: `start.wav` on Explorer folder traversal.
  - Errors: `chord.wav` / `ding.wav` on invalid actions or alerts.
  - Shutdown: Windows XP Shutdown chime on exit.
- **Keyboard Shortcuts:**
  - `Win` / `Cmd` or `Ctrl+Esc`: Toggle Start Menu.
  - `Win+E`: Open Explorer.
  - `Win+D`: Show Desktop (minimize/restore all).
  - `Win+R`: Open Run dialog.
  - `Alt+F4`: Close active window.
  - `Alt+Tab`: XP Task Switcher HUD.
  - `F11` / `Cmd+Ctrl+F`: Toggle Fullscreen mode.

---

## 4. Error Handling & Edge Cases
- File permissions: Graceful alert dialog in XP format if accessing restricted directories.
- Screen resize / Display changes: Window positions automatically clamped within visible desktop boundaries.
- Exit handling: Clean process termination for `cmd.exe` background sessions and audio players on exit.

---

## 5. Verification & Testing Strategy
- Unit tests for `WindowManager` (opening, closing, z-index sorting, minimize/maximize state transitions).
- Filesystem helper tests (directory listing, path formatting, XP path alias resolution).
- Integration test for `cmd.exe` process execution and output capturing.
- Visual inspection of Luna Blue theme components, gradients, and font scaling in fullscreen.
