import SwiftUI
#if os(macOS)
import AppKit
#endif

public enum ResizeDirection: CaseIterable, Equatable, Hashable {
    case top
    case bottom
    case left
    case right
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

#if os(macOS)
extension View {
    @ViewBuilder
    func resizeCursor(for direction: ResizeDirection) -> some View {
        self.onHover { hovering in
            if hovering {
                switch direction {
                case .top, .bottom:
                    NSCursor.resizeUpDown.push()
                case .left, .right:
                    NSCursor.resizeLeftRight.push()
                case .topLeft, .bottomRight, .topRight, .bottomLeft:
                    NSCursor.crosshair.push()
                }
            } else {
                NSCursor.pop()
            }
        }
    }
}
#endif

public struct TopRoundedRectangle: InsettableShape {
    public var radius: CGFloat = 8
    public var insetAmount: CGFloat = 0

    public init(radius: CGFloat = 8) {
        self.radius = radius
        self.insetAmount = 0
    }

    private init(radius: CGFloat, insetAmount: CGFloat) {
        self.radius = radius
        self.insetAmount = insetAmount
    }

    public func inset(by amount: CGFloat) -> TopRoundedRectangle {
        var shape = self
        shape.insetAmount += amount
        return shape
    }

    public func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        var path = Path()
        let r = max(0, min(radius - insetAmount, min(insetRect.width / 2, insetRect.height / 2)))

        path.move(to: CGPoint(x: insetRect.minX, y: insetRect.maxY))
        path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.minY + r))
        if r > 0 {
            path.addArc(
                center: CGPoint(x: insetRect.minX + r, y: insetRect.minY + r),
                radius: r,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false
            )
        } else {
            path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.minY))
        }
        path.addLine(to: CGPoint(x: insetRect.maxX - r, y: insetRect.minY))
        if r > 0 {
            path.addArc(
                center: CGPoint(x: insetRect.maxX - r, y: insetRect.minY + r),
                radius: r,
                startAngle: .degrees(270),
                endAngle: .degrees(0),
                clockwise: false
            )
        } else {
            path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.minY))
        }
        path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY))
        path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.maxY))
        path.closeSubpath()
        return path
    }
}

public struct LunaWindowView<Content: View>: View {
    public let window: XPWindowInstance
    public var onClose: (() -> Void)?
    public var onMinimize: (() -> Void)?
    public var onToggleMaximize: (() -> Void)?
    public var onFocus: (() -> Void)?
    public var onDrag: ((CGSize) -> Void)?
    public var onResize: ((ResizeDirection, CGSize) -> Void)?
    @ViewBuilder public let content: () -> Content

    public init(
        window: XPWindowInstance,
        onClose: (() -> Void)? = nil,
        onMinimize: (() -> Void)? = nil,
        onToggleMaximize: (() -> Void)? = nil,
        onFocus: (() -> Void)? = nil,
        onDrag: ((CGSize) -> Void)? = nil,
        onResize: ((ResizeDirection, CGSize) -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.window = window
        self.onClose = onClose
        self.onMinimize = onMinimize
        self.onToggleMaximize = onToggleMaximize
        self.onFocus = onFocus
        self.onDrag = onDrag
        self.onResize = onResize
        self.content = content
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Title Bar
                titleBarView

                // Window Content Container
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
            }
            .frame(width: window.rect.width, height: window.rect.height)
            .clipShape(TopRoundedRectangle(radius: 8))
            .overlay(
                TopRoundedRectangle(radius: 8)
                    .strokeBorder(borderColor, lineWidth: 3)
            )

            // Resize Handles
            resizeHandlesOverlay
        }
        .frame(width: window.rect.width, height: window.rect.height)
        .shadow(
            color: Color.black.opacity(window.isFocused ? 0.35 : 0.18),
            radius: window.isFocused ? 10 : 4,
            x: 0,
            y: window.isFocused ? 4 : 2
        )
        .simultaneousGesture(
            TapGesture().onEnded {
                onFocus?()
            }
        )
    }

    // MARK: - Title Bar

    private var titleBarView: some View {
        HStack(spacing: 6) {
            // App Icon
            #if os(macOS)
            if case .internetExplorer = window.appType {
                IEIconView(size: 15)
            } else if window.title == "My Computer" || (window.appType == .explorer(path: "computer://")) || (window.appType == .explorer(path: "/")) {
                if let icon = XPAssetProvider.loadMyComputerIcon() {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                } else {
                    fallbackTitleIcon
                }
            } else if window.title == "Control Panel" || window.appType == .controlPanel {
                if let icon = XPAssetProvider.loadControlPanelIcon() {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                } else {
                    fallbackTitleIcon
                }
            } else if window.title == "System Properties" || window.appType == .systemProperties {
                if let icon = XPAssetProvider.loadIcon(named: "system_properties") ?? XPAssetProvider.loadMyComputerIcon() {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                } else {
                    fallbackTitleIcon
                }
            } else if case .explorer = window.appType {
                if let icon = XPAssetProvider.loadFolderIcon() {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                } else {
                    fallbackTitleIcon
                }
            } else if !window.icon.isEmpty {
                fallbackTitleIcon
            }
            #else
            fallbackTitleIcon
            #endif

            // Window Title
            Text(window.title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(window.isFocused ? 0.7 : 0.3), radius: 1, x: 1, y: 1)
                .lineLimit(1)

            Spacer()

            // Control Buttons
            HStack(spacing: 2) {
                TitleBarButton(type: .minimize, isWindowFocused: window.isFocused) {
                    onMinimize?()
                }

                TitleBarButton(
                    type: window.state == .maximized ? .restore : .maximize,
                    isWindowFocused: window.isFocused
                ) {
                    onToggleMaximize?()
                }

                TitleBarButton(type: .close, isWindowFocused: window.isFocused) {
                    onClose?()
                }
            }
            .padding(.trailing, 2)
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
        .background(titleBarGradient)
        .overlay(
            VStack {
                // Top glossy shine highlight
                LinearGradient(
                    colors: [
                        Color.white.opacity(window.isFocused ? 0.35 : 0.15),
                        Color.white.opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 14)
                Spacer()
            }
        )
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in
                    onFocus?()
                    onDrag?(value.translation)
                }
        )
        .onTapGesture(count: 2) {
            onToggleMaximize?()
        }
    }

    private var fallbackTitleIcon: some View {
        Group {
            if !window.icon.isEmpty {
                Image(systemName: window.icon)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0.5, y: 0.5)
            }
        }
    }

    // MARK: - Colors & Gradients

    private var titleBarGradient: LinearGradient {
        if window.isFocused {
            return LinearGradient(
                colors: [
                    Color(red: 0.000, green: 0.333, blue: 0.918), // #0055ea
                    Color(red: 0.039, green: 0.392, blue: 0.863), // #0a64dc
                    Color(red: 0.110, green: 0.498, blue: 0.929)  // #1c7fed
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.463, green: 0.608, blue: 0.875), // #769bdf
                    Color(red: 0.525, green: 0.655, blue: 0.914)  // #86a7e9
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var borderColor: Color {
        if window.isFocused {
            return Color(red: 0.000, green: 0.333, blue: 0.918) // Luna Blue #0055ea
        } else {
            return Color(red: 0.463, green: 0.608, blue: 0.875) // Slate Blue #769bdf
        }
    }

    // MARK: - Resize Handles

    @ViewBuilder
    private var resizeHandlesOverlay: some View {
        if window.state != .maximized {
            ZStack {
                // Top Edge Handle
                handleView(direction: .top)
                    .frame(height: 5)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, 10)

                // Bottom Edge Handle
                handleView(direction: .bottom)
                    .frame(height: 5)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .padding(.horizontal, 10)

                // Left Edge Handle
                handleView(direction: .left)
                    .frame(width: 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)

                // Right Edge Handle
                handleView(direction: .right)
                    .frame(width: 5)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.vertical, 10)

                // Corner Handles
                handleView(direction: .topLeft)
                    .frame(width: 10, height: 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                handleView(direction: .topRight)
                    .frame(width: 10, height: 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                handleView(direction: .bottomLeft)
                    .frame(width: 10, height: 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

                handleView(direction: .bottomRight)
                    .frame(width: 10, height: 10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
    }

    private func handleView(direction: ResizeDirection) -> some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        onFocus?()
                        onResize?(direction, value.translation)
                    }
            )
            #if os(macOS)
            .resizeCursor(for: direction)
            #endif
    }
}
