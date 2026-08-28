# MacXP 🪟

> **The Nostalgic Windows XP Experience, Reimagined for macOS.**

MacXP is a native, pixel-accurate recreation of Microsoft Windows XP (Luna Blue theme) built entirely in Swift and SwiftUI for macOS 13.0+ (Ventura, Sonoma, and Sequoia). It brings the golden era of desktop computing back to life with an authentic desktop, window manager, start menu, taskbar, sound synthesis engine, and a complete suite of classic built-in applications.

---

## ✨ Features

### 🏞️ Iconic Desktop & Bliss Wallpaper
- **Procedural Bliss Wallpaper**: Faithful vector and gradient rendering of the iconic rolling green hills and blue sky with wispy clouds.
- **Desktop Icons**: Classic system shortcuts including *My Computer*, *My Documents*, *Recycle Bin*, and *Internet Explorer*.
- **Marquee Selection**: Multi-icon rubberband drag selection with authentic translucent blue selection rectangle.
- **Context Menus**: Right-click desktop menu with *Arrange Icons*, *Refresh*, *New Folder*, *New Text Document*, and *Properties*.

### 🎨 Authentic Luna Theme & Window Management
- **Luna Blue Window Frames**: Classic rounded royal blue title bars with high-gloss gradients, 3D beveled borders, and authentic close, maximize, and minimize buttons.
- **Multi-Window Desktop**: Drag windows freely across the workspace, resize from 8 directions (edges and corners), and bring windows to front on focus.
- **Cascading Placement**: New windows cascade intelligently when launched.
- **Window Snapping & Maximization**: Maximize windows to fill the work area above the taskbar or restore them to their previous dimensions.

### 🟢 Start Menu & Taskbar
- **Two-Column Start Menu**:
  - Top header with user avatar and username.
  - Left column featuring pinned Internet Explorer and Outlook Express, plus frequently used applications.
  - *All Programs* flyout menu with categorized accessories and tools.
  - Right column with shortcuts to *My Documents*, *My Pictures*, *My Computer*, *Control Panel*, *Search*, and *Run...*.
  - Bottom bar with *Log Off* and *Turn Off Computer* actions.
- **Luna Taskbar**:
  - Green **start** button with embossed 4-color Windows XP flag.
  - Active window buttons with pressed/active state styling and click-to-minimize/restore behavior.
  - System tray with real-time digital clock and interactive volume slider with mute toggle.

### 💻 Classic Built-in Applications

| Application | Description |
| :--- | :--- |
| **🗂️ Windows Explorer** | Virtualized `C:\` and `D:\` drive structure, breadcrumb address bar, forward/back history, folder tree sidebar, icon grid view, and file context menus (Open, Rename, Delete). |
| **📝 Notepad** | Lightweight text editor with File (New, Open, Save, Save As), Edit (Undo, Cut, Copy, Paste, Delete, Time/Date `F5`), Word Wrap toggle, and status bar line/column tracking. |
| **🔢 Calculator** | Standard XP calculator supporting memory operations (`MC`, `MR`, `MS`, `M+`), basic arithmetic (`+`, `-`, `*`, `/`), square root, reciprocal, percentage, sign inversion, and full keyboard control. |
| **🎨 Paint** | Classic raster canvas with Pencil, Brush, Line, Rectangle, Ellipse, and Eraser tools, 28-color palette, brush thickness controls, and multi-step Undo history. |
| **⌨️ Command Prompt (`cmd.exe`)** | Virtual DOS/XP terminal emulator supporting `DIR`, `CD`, `CLS`, `ECHO`, `HELP`, `VER`, `PING`, `COLOR`, and `EXIT` with authentic font rendering. |
| **💣 Minesweeper** | Authentic gameplay with Beginner (9x9, 10 mines), Intermediate (16x16, 40 mines), and Expert (30x16, 99 mines) modes, first-click guaranteed safety, interactive yellow smiley face reaction button, 7-segment digital timer/counter, and high scores. |
| **⚙️ Control Panel** | Category and Classic view navigation with applets for System Properties (OS details, hardware specs), Display, and Sound settings. |
| **🚀 Run Dialog** | Quick-launch command dialog (`Win+R`) with persistent history for launching system applications and DOS commands. |
| **🔌 Turn Off Computer** | Modal dialog with Stand By, Turn Off (with shutdown chime), and Restart actions. |

### 🔊 In-Memory Sound Synthesis Engine
- **Zero External Audio Assets**: Uses pure Swift waveform synthesis to generate 16-bit 44.1kHz mono PCM audio in memory.
- Synthesizes classic sound effects:
  - `Startup`: Warm 4-chord harmonized greeting.
  - `Shutdown`: Descending 4-chord harmonic resolution.
  - `Navigation`: Crisp tactile click for folders and links.
  - `Error / Hand`: Resonant alert chord for invalid actions.
  - `Exclamation`: High C6 bell chime.
  - `Recycle Bin`: Crumple and paper whoosh effect on file deletion.
- **Audio Control**: System tray volume slider and mute controls with automatic fallback safety for headless environments.

### ⌨️ Global Hotkeys & Shortcuts

| Shortcut | Action |
| :--- | :--- |
| **`Cmd+E`** / **`Win+E`** | Open Windows Explorer |
| **`Cmd+D`** / **`Win+D`** | Show / Hide Desktop (Minimize all windows) |
| **`Cmd+R`** / **`Win+R`** | Open Run Dialog |
| **`Cmd+W`** / **`Alt+F4`** | Close Active Window |
| **`Alt+Tab`** / **`Cmd+Tab`** | Cycle Task Switcher HUD forward |
| **`Shift+Alt+Tab`** / **`Shift+Cmd+Tab`** | Cycle Task Switcher HUD backward |
| **`Ctrl+Esc`** | Toggle Start Menu |
| **`F11`** / **`Cmd+Ctrl+F`** | Toggle Fullscreen |
| **`F5`** (in Notepad) | Insert Current Date and Time |
| **`0-9, +, -, *, /, =, Enter, Esc`** (in Calculator) | Keyboard calculation inputs |

---

## 🛠️ Build & Installation

### Requirements
- **macOS 13.0 (Ventura)** or later (tested on macOS 14 Sonoma & macOS 15 Sequoia)
- **Xcode 15+** or **Swift 5.9+** command line tools

### Quick Start with Make

The repository includes a comprehensive `Makefile` for building, testing, and packaging:

```bash
# Build the project (debug mode)
make build

# Run the test suite
make test

# Launch MacXP directly
make run

# Build standalone macOS Application bundle (build/MacXP.app)
make app

# Package into distributable Apple Disk Image (build/MacXP.dmg)
make dmg

# Clean build artifacts
make clean
```

### Manual Swift Package Manager Commands

```bash
# Build debug binary
swift build

# Run tests
swift test

# Build release binary
swift build -c release

# Run MacXP
swift run MacXP
```

---

## 📦 Packaging & Distribution

MacXP includes automated build scripts located in `scripts/`:

- **`scripts/build_app.sh`**:
  - Compiles the release binary with compiler optimizations.
  - Generates the standard macOS `.app` bundle structure:
    - `build/MacXP.app/Contents/MacOS/MacXP`
    - `build/MacXP.app/Contents/Info.plist`
    - `build/MacXP.app/Contents/Resources/AppIcon.icns`
    - `build/MacXP.app/Contents/PkgInfo`
  - Applies ad-hoc code signing via `codesign`.

- **`scripts/build_dmg.sh`**:
  - Invokes `build_app.sh` to construct the `.app` bundle.
  - Prepares a staging folder with `MacXP.app` and an `/Applications` drag-and-drop symlink.
  - Uses `hdiutil` to package a compressed `.dmg` image ready for distribution at `build/MacXP.dmg`.

---

## 🏗️ Architecture

MacXP follows modern declarative SwiftUI architecture:
- **`Models/`**: Core data structures (`XPWindowInstance`, `WindowAppType`, `FileSystemItem`, `DesktopIconItem`).
- **`Managers/`**: Central state managers (`WindowManager` with z-ordering, focus tracking, cascading, and minimized states).
- **`Services/`**: System infrastructure (`FileSystemService`, `ShellService`, `SoundManager`, `HotkeyManager`).
- **`Resources/`**: Audio synthesis algorithms (`SoundEffects.swift`), metadata (`Info.plist`), and application icons (`AppIcon.icns`).
- **`Views/`**: Pixel-perfect SwiftUI views for Luna window chrome, Taskbar, Start Menu, Desktop, Task Switcher, and all built-in apps.

---

## 📄 License

This project is created for educational and nostalgia purposes. Windows XP, Luna, and related assets are trademarks of Microsoft Corporation.
