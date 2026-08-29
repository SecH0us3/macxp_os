import SwiftUI

public enum QuickLaunchAction {
    case showDesktop
    case openExplorer
    case openCmd
}

public struct TaskbarHelper {
    public static func handleTabClick(windowID: UUID, windowManager: WindowManager) {
        guard let window = windowManager.window(for: windowID) else { return }
        
        if window.isFocused && window.state != .minimized {
            windowManager.minimizeWindow(id: windowID)
        } else {
            windowManager.focusWindow(id: windowID)
        }
    }
    
    public static func handleQuickLaunch(action: QuickLaunchAction, windowManager: WindowManager) {
        switch action {
        case .showDesktop:
            windowManager.toggleShowDesktop()
        case .openExplorer:
            windowManager.openWindow(appType: .explorer(path: "/"))
        case .openCmd:
            windowManager.openWindow(appType: .cmd)
        }
    }
}

public struct TaskbarWindowTab: View {
    public let window: XPWindowInstance
    public let onClick: () -> Void
    public var onClose: (() -> Void)?
    public var onMinimize: (() -> Void)?
    public var onMaximize: (() -> Void)?
    public var onRestore: (() -> Void)?

    @State private var isHovered: Bool = false

    private var isActive: Bool {
        window.isFocused && window.state != .minimized
    }

    public var body: some View {
        Button(action: onClick) {
            HStack(spacing: 5) {
                if !window.icon.isEmpty {
                    Image(systemName: window.icon)
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                }

                Text(window.title)
                    .font(.system(size: 11, weight: isActive ? .bold : .regular))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 6)
            .frame(minWidth: 60, maxWidth: 160, maxHeight: 24)
            .background(tabBackground)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(
                        isActive ?
                            Color(red: 0.06, green: 0.20, blue: 0.55) :
                            Color(red: 0.15, green: 0.40, blue: 0.85),
                        lineWidth: 1
                    )
            )
            .overlay(
                VStack {
                    if !isActive {
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 10)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    Spacer()
                }
            )
            .shadow(color: Color.black.opacity(isActive ? 0.0 : 0.2), radius: 1, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .focusable(false)
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            if window.state == .minimized || window.state == .maximized {
                Button("Restore") { onRestore?() }
            }
            if window.state != .minimized {
                Button("Minimize") { onMinimize?() }
            }
            if window.state != .maximized {
                Button("Maximize") { onMaximize?() }
            }
            Divider()
            Button("Close") { onClose?() }
        }
    }

    private var tabBackground: some View {
        Group {
            if isActive {
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.26, blue: 0.65), // #1941a5
                        Color(red: 0.12, green: 0.32, blue: 0.76),
                        Color(red: 0.08, green: 0.24, blue: 0.60)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else if isHovered {
                LinearGradient(
                    colors: [
                        Color(red: 0.32, green: 0.62, blue: 0.98),
                        Color(red: 0.22, green: 0.48, blue: 0.88),
                        Color(red: 0.16, green: 0.38, blue: 0.78)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.24, green: 0.50, blue: 0.93), // #3c80ed
                        Color(red: 0.18, green: 0.40, blue: 0.85),
                        Color(red: 0.13, green: 0.35, blue: 0.81)  // #2258cf
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
}

public struct TaskbarView: View {
    @ObservedObject public var windowManager: WindowManager
    @ObservedObject public var systemTrayModel: SystemTrayModel
    public let isStartMenuOpen: Bool
    public let onToggleStartMenu: () -> Void
    public let onToggleVolume: () -> Void
    public var onClockClick: (() -> Void)?

    public init(
        windowManager: WindowManager,
        systemTrayModel: SystemTrayModel,
        isStartMenuOpen: Bool,
        onToggleStartMenu: @escaping () -> Void,
        onToggleVolume: @escaping () -> Void,
        onClockClick: (() -> Void)? = nil
    ) {
        self.windowManager = windowManager
        self.systemTrayModel = systemTrayModel
        self.isStartMenuOpen = isStartMenuOpen
        self.onToggleStartMenu = onToggleStartMenu
        self.onToggleVolume = onToggleVolume
        self.onClockClick = onClockClick
    }

    public var body: some View {
        HStack(spacing: 4) {
            // Start Button
            StartButton(isOpen: isStartMenuOpen, action: onToggleStartMenu)

            // Quick Launch Divider
            quickLaunchDivider

            // Quick Launch Toolbar
            HStack(spacing: 4) {
                // Show Desktop
                Button(action: {
                    TaskbarHelper.handleQuickLaunch(action: .showDesktop, windowManager: windowManager)
                }) {
                    Image(systemName: "rectangle.on.rectangle")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                        .frame(width: 18, height: 20)
                }
                .buttonStyle(PlainButtonStyle())
                .focusable(false)
                .help("Show Desktop")

                // Explorer
                Button(action: {
                    TaskbarHelper.handleQuickLaunch(action: .openExplorer, windowManager: windowManager)
                }) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.98, green: 0.80, blue: 0.20))
                        .frame(width: 18, height: 20)
                }
                .buttonStyle(PlainButtonStyle())
                .focusable(false)
                .help("Windows Explorer")

                // Command Prompt
                Button(action: {
                    TaskbarHelper.handleQuickLaunch(action: .openCmd, windowManager: windowManager)
                }) {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                        .frame(width: 18, height: 20)
                }
                .buttonStyle(PlainButtonStyle())
                .focusable(false)
                .help("Command Prompt")
            }
            .padding(.trailing, 2)

            // Quick Launch Divider
            quickLaunchDivider

            // Window Tabs List
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    ForEach(windowManager.windows) { window in
                        TaskbarWindowTab(
                            window: window,
                            onClick: {
                                TaskbarHelper.handleTabClick(windowID: window.id, windowManager: windowManager)
                            },
                            onClose: {
                                windowManager.closeWindow(id: window.id)
                            },
                            onMinimize: {
                                windowManager.minimizeWindow(id: window.id)
                            },
                            onMaximize: {
                                windowManager.toggleMaximize(id: window.id)
                            },
                            onRestore: {
                                if window.state == .minimized {
                                    windowManager.focusWindow(id: window.id)
                                } else if window.state == .maximized {
                                    windowManager.toggleMaximize(id: window.id)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 2)
            }

            Spacer(minLength: 0)

            // System Tray
            SystemTrayView(
                model: systemTrayModel,
                onToggleVolume: onToggleVolume,
                onClockClick: onClockClick
            )
        }
        .frame(height: 30)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.14, green: 0.37, blue: 0.84), // #245edb
                    Color(red: 0.25, green: 0.55, blue: 0.95), // #3f8cf3
                    Color(red: 0.14, green: 0.37, blue: 0.84)  // #245edb
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            VStack {
                Rectangle()
                    .fill(Color(red: 0.33, green: 0.60, blue: 0.99)) // Top bright stripe #539afc
                    .frame(height: 1)
                Spacer()
            }
        )
    }

    private var quickLaunchDivider: some View {
        HStack(spacing: 1) {
            Rectangle()
                .fill(Color(red: 0.11, green: 0.29, blue: 0.71))
                .frame(width: 1, height: 20)
            Rectangle()
                .fill(Color(red: 0.35, green: 0.62, blue: 0.98))
                .frame(width: 1, height: 20)
        }
        .padding(.horizontal, 2)
    }
}
