import SwiftUI

public struct BlissWallpaperView: View {
    @State private var wallpaperImage: NSImage? = nil

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            if let image = wallpaperImage ?? XPAssetProvider.loadBlissImage() {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            } else {
                ZStack {
                    // Vibrant Blue Sky
                    LinearGradient(
                        colors: [
                            Color(red: 0.10, green: 0.45, blue: 0.88),
                            Color(red: 0.30, green: 0.62, blue: 0.95),
                            Color(red: 0.58, green: 0.78, blue: 0.98)
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )

                    // Fluffy Cloud Wisps
                    Path { path in
                        path.addEllipse(in: CGRect(x: geo.size.width * 0.10, y: geo.size.height * 0.08, width: geo.size.width * 0.50, height: geo.size.height * 0.16))
                        path.addEllipse(in: CGRect(x: geo.size.width * 0.52, y: geo.size.height * 0.05, width: geo.size.width * 0.42, height: geo.size.height * 0.14))
                    }
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.50), Color.white.opacity(0.0)],
                            center: .center,
                            startRadius: 10,
                            endRadius: geo.size.width * 0.25
                        )
                    )
                    .blur(radius: 14)

                    // Background Rolling Hill
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geo.size.height * 0.62))
                        path.addCurve(
                            to: CGPoint(x: geo.size.width, y: geo.size.height * 0.48),
                            control1: CGPoint(x: geo.size.width * 0.35, y: geo.size.height * 0.42),
                            control2: CGPoint(x: geo.size.width * 0.70, y: geo.size.height * 0.58)
                        )
                        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                        path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.32, green: 0.72, blue: 0.16),
                                Color(red: 0.18, green: 0.50, blue: 0.08)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Foreground Rolling Green Hill
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geo.size.height * 0.52))
                        path.addCurve(
                            to: CGPoint(x: geo.size.width, y: geo.size.height * 0.68),
                            control1: CGPoint(x: geo.size.width * 0.32, y: geo.size.height * 0.70),
                            control2: CGPoint(x: geo.size.width * 0.65, y: geo.size.height * 0.46)
                        )
                        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                        path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.42, green: 0.80, blue: 0.20),
                                Color(red: 0.24, green: 0.60, blue: 0.10),
                                Color(red: 0.14, green: 0.42, blue: 0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
            }
        }
        .onAppear {
            if wallpaperImage == nil {
                wallpaperImage = XPAssetProvider.loadBlissImage()
            }
        }
        .ignoresSafeArea()
    }
}

public struct DesktopView: View {
    @ObservedObject public var windowManager: WindowManager
    @ObservedObject public var hotkeyManager: HotkeyManager = HotkeyManager.shared
    @StateObject public var desktopManager = DesktopManager()
    @StateObject public var systemTrayModel = SystemTrayModel()
    @StateObject public var startMenuModel = StartMenuModel()

    @State private var isStartMenuOpen: Bool = false
    @State private var isVolumePopupOpen: Bool = false
    @State private var isTurnOffDialogOpen: Bool = false
    @State private var marqueeStart: CGPoint? = nil
    @State private var marqueeCurrent: CGPoint? = nil

    public init(windowManager: WindowManager) {
        self.windowManager = windowManager
    }

    public var body: some View {
        GeometryReader { desktopGeo in
            ZStack(alignment: .bottomLeading) {
                // 1. Bliss Wallpaper & Desktop Canvas
                BlissWallpaperView()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        desktopManager.clearSelection()
                        isStartMenuOpen = false
                        isVolumePopupOpen = false
                    }
                    .gesture(
                        DragGesture(minimumDistance: 4)
                            .onChanged { value in
                                isStartMenuOpen = false
                                isVolumePopupOpen = false
                                if marqueeStart == nil {
                                    marqueeStart = value.startLocation
                                }
                                marqueeCurrent = value.location
                                if let start = marqueeStart, let current = marqueeCurrent {
                                    let rect = MarqueeHelper.calculateRect(from: start, to: current)
                                    desktopManager.selectIconsInMarquee(marqueeRect: rect)
                                }
                            }
                            .onEnded { _ in
                                marqueeStart = nil
                                marqueeCurrent = nil
                            }
                    )
                    .desktopContextMenu(
                        desktopManager: desktopManager,
                        onArrange: { option in
                            desktopManager.arrangeIcons(by: option, desktopHeight: desktopGeo.size.height - 30)
                        },
                        onRefresh: {
                            desktopManager.refresh()
                        },
                        onNewFolder: {
                            desktopManager.createNewFolder()
                        },
                        onNewTextDocument: {
                            desktopManager.createNewTextDocument()
                        },
                        onProperties: {
                            windowManager.openWindow(appType: .systemProperties)
                        }
                    )

                // 2. Desktop Icons Grid
                ZStack(alignment: .topLeading) {
                    ForEach(desktopManager.icons) { item in
                        DesktopIconView(
                            item: item,
                            isSelected: desktopManager.isIconSelected(id: item.id),
                            onSelect: { multi in
                                desktopManager.selectIcon(id: item.id, exclusive: !multi)
                            },
                            onOpen: {
                                handleOpenDesktopItem(item)
                            },
                            onDragPosition: { newPos in
                                if let index = desktopManager.icons.firstIndex(where: { $0.id == item.id }) {
                                    desktopManager.icons[index].position = newPos
                                }
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                // 3. Marquee Selection Box Overlay
                if let start = marqueeStart, let current = marqueeCurrent {
                    let rect = MarqueeHelper.calculateRect(from: start, to: current)
                    MarqueeSelectionView(rect: rect)
                }

                // 4. Windows Layer
                ZStack(alignment: .topLeading) {
                    ForEach(windowManager.windows) { window in
                        if window.state != .minimized {
                            LunaWindowView(
                                window: window,
                                onClose: {
                                    windowManager.closeWindow(id: window.id)
                                },
                                onMinimize: {
                                    windowManager.minimizeWindow(id: window.id)
                                },
                                onToggleMaximize: {
                                    let bounds = CGRect(
                                        x: 0,
                                        y: 0,
                                        width: desktopGeo.size.width,
                                        height: desktopGeo.size.height - 30
                                    )
                                    windowManager.toggleMaximize(id: window.id, desktopBounds: bounds)
                                },
                                onFocus: {
                                    windowManager.focusWindow(id: window.id)
                                },
                                onDrag: { translation in
                                    let newRect = CGRect(
                                        x: window.rect.origin.x + translation.width,
                                        y: window.rect.origin.y + translation.height,
                                        width: window.rect.width,
                                        height: window.rect.height
                                    )
                                    windowManager.updateWindowRect(id: window.id, rect: newRect)
                                },
                                onResize: { direction, translation in
                                    handleWindowResize(window: window, direction: direction, translation: translation)
                                }
                            ) {
                                windowContentView(for: window)
                            }
                            .position(
                                x: window.rect.origin.x + window.rect.width / 2,
                                y: window.rect.origin.y + window.rect.height / 2
                            )
                            .zIndex(window.zIndex)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: desktopGeo.size.height - 30, alignment: .topLeading)

                // 5. Dismiss backdrops for Start Menu & Volume Popup
                if isStartMenuOpen || isVolumePopupOpen {
                    Color.black.opacity(0.001)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            isStartMenuOpen = false
                            isVolumePopupOpen = false
                        }
                        .zIndex(99990)
                }

                // 6. Start Menu Overlay
                if isStartMenuOpen {
                    StartMenuView(
                        windowManager: windowManager,
                        model: startMenuModel,
                        onClose: {
                            isStartMenuOpen = false
                        },
                        onTurnOff: {
                            isStartMenuOpen = false
                            isTurnOffDialogOpen = true
                        }
                    )
                    .offset(x: 0, y: -30)
                    .zIndex(99995)
                }

                // 7. Volume Popup Overlay
                if isVolumePopupOpen {
                    XPVolumePopup(
                        model: systemTrayModel,
                        onClose: {
                            isVolumePopupOpen = false
                        }
                    )
                    .offset(x: max(0, desktopGeo.size.width - 110), y: -30)
                    .zIndex(99995)
                }

                // 8. Taskbar (Bottom)
                TaskbarView(
                    windowManager: windowManager,
                    systemTrayModel: systemTrayModel,
                    isStartMenuOpen: isStartMenuOpen,
                    onToggleStartMenu: {
                        isVolumePopupOpen = false
                        isStartMenuOpen.toggle()
                        if isStartMenuOpen {
                            SoundManager.shared.play(.navigation)
                        }
                    },
                    onToggleVolume: {
                        isStartMenuOpen = false
                        isVolumePopupOpen.toggle()
                    },
                    onClockClick: {
                        windowManager.openWindow(appType: .systemProperties, title: "Date and Time Properties")
                    }
                )
                .frame(maxWidth: .infinity)
                .zIndex(99999)

                // 9. Alt-Tab Task Switcher HUD Overlay
                if hotkeyManager.isTaskSwitcherVisible {
                    TaskSwitcherHUDView(windowManager: windowManager, hotkeyManager: hotkeyManager)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .zIndex(99998)
                }

                // 10. Turn Off Computer Dialog Overlay
                if isTurnOffDialogOpen {
                    TurnOffDialogView(
                        windowManager: windowManager,
                        onStandBy: {
                            windowManager.minimizeAll()
                        },
                        onTurnOff: {
                            #if os(macOS)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                NSApplication.shared.terminate(nil)
                            }
                            #endif
                        },
                        onRestart: {
                            // Reset windows and play startup chime
                            for win in windowManager.windows {
                                windowManager.closeWindow(id: win.id)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                SoundManager.shared.play(.startup)
                            }
                        },
                        onDismiss: {
                            isTurnOffDialogOpen = false
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(100000)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                SoundManager.shared.play(.startup)
                hotkeyManager.startMonitoring(
                    windowManager: windowManager,
                    onToggleStartMenu: {
                        isVolumePopupOpen = false
                        isStartMenuOpen.toggle()
                        if isStartMenuOpen {
                            SoundManager.shared.play(.navigation)
                        }
                    },
                    onToggleShowDesktop: {
                        windowManager.toggleShowDesktop()
                    },
                    onToggleFullscreen: {
                        #if os(macOS)
                        if let window = NSApplication.shared.windows.first {
                            window.toggleFullScreen(nil)
                        }
                        #endif
                    }
                )
            }
        }
    }

    private func handleOpenDesktopItem(_ item: DesktopIconItem) {
        SoundManager.shared.play(.navigation)
        if let appType = item.appType {
            windowManager.openWindow(appType: appType, title: item.title, icon: item.iconName)
        } else if let fileURL = item.fileURL {
            #if os(macOS)
            NSWorkspace.shared.open(fileURL)
            #endif
        }
    }

    private func handleWindowResize(window: XPWindowInstance, direction: ResizeDirection, translation: CGSize) {
        var newRect = window.rect
        switch direction {
        case .right:
            newRect.size.width = max(window.minSize.width, window.rect.width + translation.width)
        case .bottom:
            newRect.size.height = max(window.minSize.height, window.rect.height + translation.height)
        case .bottomRight:
            newRect.size.width = max(window.minSize.width, window.rect.width + translation.width)
            newRect.size.height = max(window.minSize.height, window.rect.height + translation.height)
        case .left:
            let newWidth = max(window.minSize.width, window.rect.width - translation.width)
            let diff = newWidth - window.rect.width
            newRect.origin.x = window.rect.origin.x - diff
            newRect.size.width = newWidth
        case .top:
            let newHeight = max(window.minSize.height, window.rect.height - translation.height)
            let diff = newHeight - window.rect.height
            newRect.origin.y = window.rect.origin.y - diff
            newRect.size.height = newHeight
        case .topLeft:
            let newWidth = max(window.minSize.width, window.rect.width - translation.width)
            let diffX = newWidth - window.rect.width
            let newHeight = max(window.minSize.height, window.rect.height - translation.height)
            let diffY = newHeight - window.rect.height
            newRect.origin.x = window.rect.origin.x - diffX
            newRect.origin.y = window.rect.origin.y - diffY
            newRect.size.width = newWidth
            newRect.size.height = newHeight
        case .topRight:
            newRect.size.width = max(window.minSize.width, window.rect.width + translation.width)
            let newHeight = max(window.minSize.height, window.rect.height - translation.height)
            let diffY = newHeight - window.rect.height
            newRect.origin.y = window.rect.origin.y - diffY
            newRect.size.height = newHeight
        case .bottomLeft:
            let newWidth = max(window.minSize.width, window.rect.width - translation.width)
            let diffX = newWidth - window.rect.width
            newRect.origin.x = window.rect.origin.x - diffX
            newRect.size.width = newWidth
            newRect.size.height = max(window.minSize.height, window.rect.height + translation.height)
        }
        windowManager.updateWindowRect(id: window.id, rect: newRect)
    }

    @ViewBuilder
    private func windowContentView(for window: XPWindowInstance) -> some View {
        switch window.appType {
        case .explorer(let path):
            ExplorerWindowView(initialPath: path, windowManager: windowManager, window: window)
        case .notepad(let fileURL):
            NotepadView(fileURL: fileURL, windowManager: windowManager, window: window)
        case .cmd:
            CmdView(windowManager: windowManager, window: window)
        case .calculator:
            CalculatorView(windowManager: windowManager, window: window)
        case .minesweeper:
            MinesweeperView(windowManager: windowManager, window: window)
        case .paint:
            PaintView(windowManager: windowManager, window: window)
        case .controlPanel:
            ControlPanelView(windowManager: windowManager, window: window)
        case .systemProperties:
            SystemPropertiesView(windowManager: windowManager, window: window)
        case .runDialog:
            RunDialogView(windowManager: windowManager, window: window)
        }
    }
}
