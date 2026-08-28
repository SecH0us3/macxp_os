import SwiftUI

public enum ExplorerViewMode: String, CaseIterable, Identifiable {
    case thumbnails = "Thumbnails"
    case tiles = "Tiles"
    case icons = "Icons"
    case list = "List"
    case details = "Details"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .thumbnails: return "square.grid.2x2.fill"
        case .tiles: return "square.grid.3x3.fill"
        case .icons: return "square.grid.3x2.fill"
        case .list: return "list.bullet"
        case .details: return "list.bullet.rectangle.portrait"
        }
    }
}

public struct ExplorerToolbar: View {
    public var canGoBack: Bool
    public var canGoForward: Bool
    public var canGoUp: Bool
    public var isFoldersActive: Bool
    public var isSearchActive: Bool
    public var currentViewMode: ExplorerViewMode

    public var onBack: () -> Void
    public var onForward: () -> Void
    public var onUp: () -> Void
    public var onSearch: () -> Void
    public var onToggleFolders: () -> Void
    public var onSelectViewMode: (ExplorerViewMode) -> Void

    @State private var isViewMenuOpen: Bool = false

    public init(
        canGoBack: Bool,
        canGoForward: Bool,
        canGoUp: Bool,
        isFoldersActive: Bool = false,
        isSearchActive: Bool = false,
        currentViewMode: ExplorerViewMode = .icons,
        onBack: @escaping () -> Void,
        onForward: @escaping () -> Void,
        onUp: @escaping () -> Void,
        onSearch: @escaping () -> Void,
        onToggleFolders: @escaping () -> Void,
        onSelectViewMode: @escaping (ExplorerViewMode) -> Void
    ) {
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
        self.canGoUp = canGoUp
        self.isFoldersActive = isFoldersActive
        self.isSearchActive = isSearchActive
        self.currentViewMode = currentViewMode
        self.onBack = onBack
        self.onForward = onForward
        self.onUp = onUp
        self.onSearch = onSearch
        self.onToggleFolders = onToggleFolders
        self.onSelectViewMode = onSelectViewMode
    }

    public var body: some View {
        HStack(spacing: 2) {
            // Back Button
            XPToolbarButton(
                title: "Back",
                iconName: "arrow.left.circle.fill",
                iconColor: canGoBack ? Color(red: 0.18, green: 0.68, blue: 0.28) : Color.gray.opacity(0.5),
                isEnabled: canGoBack,
                action: onBack
            )

            // Forward Button
            XPToolbarButton(
                title: "",
                iconName: "arrow.right.circle.fill",
                iconColor: canGoForward ? Color(red: 0.18, green: 0.68, blue: 0.28) : Color.gray.opacity(0.5),
                isEnabled: canGoForward,
                action: onForward
            )

            // Up Button
            XPToolbarButton(
                title: "",
                iconName: "arrow.turn.left.up",
                iconColor: canGoUp ? Color(red: 0.20, green: 0.50, blue: 0.85) : Color.gray.opacity(0.5),
                isEnabled: canGoUp,
                action: onUp
            )

            toolbarSeparator

            // Search Button
            XPToolbarButton(
                title: "Search",
                iconName: "magnifyingglass",
                iconColor: Color(red: 0.85, green: 0.60, blue: 0.15),
                isActive: isSearchActive,
                action: onSearch
            )

            // Folders Button
            XPToolbarButton(
                title: "Folders",
                iconName: "folder.fill",
                iconColor: Color(red: 0.95, green: 0.78, blue: 0.20),
                isActive: isFoldersActive,
                action: onToggleFolders
            )

            toolbarSeparator

            // Views Dropdown Button
            Menu {
                ForEach(ExplorerViewMode.allCases) { mode in
                    Button(action: {
                        onSelectViewMode(mode)
                    }) {
                        HStack {
                            if currentViewMode == mode {
                                Image(systemName: "checkmark")
                            }
                            Text(mode.rawValue)
                        }
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: currentViewMode.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.20, green: 0.40, blue: 0.80))
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 7))
                        .foregroundColor(Color.black.opacity(0.7))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .frame(width: 48, height: 28)

            Spacer()

            // Windows XP Logo Watermark (Right corner)
            windowsXPFlagLogo
                .padding(.trailing, 6)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .frame(height: 38)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.95, blue: 0.93),
                    Color(red: 0.90, green: 0.89, blue: 0.86)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            VStack {
                Spacer()
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(red: 0.80, green: 0.78, blue: 0.75))
            }
        )
    }

    private var toolbarSeparator: some View {
        HStack(spacing: 0) {
            Rectangle()
                .frame(width: 1, height: 22)
                .foregroundColor(Color(red: 0.75, green: 0.75, blue: 0.75))
            Rectangle()
                .frame(width: 1, height: 22)
                .foregroundColor(Color.white)
        }
        .padding(.horizontal, 3)
    }

    private var windowsXPFlagLogo: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.90, green: 0.92, blue: 0.96)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 26)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(Color(red: 0.70, green: 0.75, blue: 0.85), lineWidth: 1)
                )

            // 4 colored tiles
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    Rectangle().fill(Color(red: 0.93, green: 0.32, blue: 0.18)).frame(width: 8, height: 8) // Red
                    Rectangle().fill(Color(red: 0.38, green: 0.72, blue: 0.22)).frame(width: 8, height: 8) // Green
                }
                HStack(spacing: 2) {
                    Rectangle().fill(Color(red: 0.18, green: 0.54, blue: 0.92)).frame(width: 8, height: 8) // Blue
                    Rectangle().fill(Color(red: 0.98, green: 0.76, blue: 0.12)).frame(width: 8, height: 8) // Yellow
                }
            }
        }
    }
}

public struct XPToolbarButton: View {
    public let title: String
    public let iconName: String
    public let iconColor: Color
    public var isEnabled: Bool = true
    public var isActive: Bool = false
    public let action: () -> Void

    @State private var isHovered: Bool = false

    public init(
        title: String,
        iconName: String,
        iconColor: Color,
        isEnabled: Bool = true,
        isActive: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.iconName = iconName
        self.iconColor = iconColor
        self.isEnabled = isEnabled
        self.isActive = isActive
        self.action = action
    }

    public var body: some View {
        Button(action: {
            if isEnabled {
                action()
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundColor(isEnabled ? iconColor : Color.gray.opacity(0.4))

                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(isEnabled ? Color.black : Color.gray.opacity(0.5))
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                Group {
                    if isActive {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 0.85, green: 0.90, blue: 0.98))
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(Color(red: 0.20, green: 0.45, blue: 0.85), lineWidth: 1)
                            )
                    } else if isHovered && isEnabled {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 0.92, green: 0.95, blue: 1.0))
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(Color(red: 0.40, green: 0.60, blue: 0.90), lineWidth: 1)
                            )
                    } else {
                        Color.clear
                    }
                }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
