import SwiftUI

public struct TitleBarButton: View {
    public enum ButtonType: Equatable {
        case minimize
        case maximize
        case restore
        case close
    }

    public let type: ButtonType
    public var isWindowFocused: Bool
    public var action: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    public init(
        type: ButtonType,
        isWindowFocused: Bool = true,
        action: @escaping () -> Void
    ) {
        self.type = type
        self.isWindowFocused = isWindowFocused
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                // Button background with authentic Luna bevel and gradients
                RoundedRectangle(cornerRadius: 3)
                    .fill(backgroundGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(borderColor, lineWidth: 1)
                    )
                    // Top glossy shine highlight
                    .overlay(
                        VStack {
                            LinearGradient(
                                colors: [Color.white.opacity(isHovered ? 0.6 : 0.4), Color.white.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 9)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                            .padding(.top, 1)
                            .padding(.horizontal, 1)
                            Spacer()
                        }
                    )
                    .frame(width: 21, height: 21)

                // Button glyph
                glyphView
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    @ViewBuilder
    private var glyphView: some View {
        switch type {
        case .close:
            // XP Close "X"
            Text("✕")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.4), radius: 0.5, x: 0.5, y: 0.5)

        case .minimize:
            // XP Minimize "_"
            Rectangle()
                .fill(Color.white)
                .frame(width: 8, height: 2)
                .offset(y: 4)
                .shadow(color: Color.black.opacity(0.3), radius: 0.5, x: 0.5, y: 0.5)

        case .maximize:
            // XP Maximize single square with heavy top border
            ZStack(alignment: .top) {
                Rectangle()
                    .strokeBorder(Color.white, lineWidth: 1.5)
                    .frame(width: 10, height: 9)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 10, height: 2.5)
            }
            .shadow(color: Color.black.opacity(0.3), radius: 0.5, x: 0.5, y: 0.5)

        case .restore:
            // XP Restore two cascading overlapping squares
            ZStack {
                // Top-right background square
                ZStack(alignment: .top) {
                    Rectangle()
                        .strokeBorder(Color.white, lineWidth: 1.2)
                        .frame(width: 8, height: 7)
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 8, height: 2)
                }
                .offset(x: 2, y: -2)

                // Bottom-left foreground square
                ZStack(alignment: .top) {
                    Rectangle()
                        .fill(backgroundBaseColor)
                        .frame(width: 8, height: 7)
                    Rectangle()
                        .strokeBorder(Color.white, lineWidth: 1.2)
                        .frame(width: 8, height: 7)
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 8, height: 2)
                }
                .offset(x: -2, y: 2)
            }
            .shadow(color: Color.black.opacity(0.3), radius: 0.5, x: 0.5, y: 0.5)
        }
    }

    private var backgroundBaseColor: Color {
        if type == .close {
            return isWindowFocused ? Color(red: 0.88, green: 0.26, blue: 0.13) : Color(red: 0.68, green: 0.44, blue: 0.41)
        } else {
            return isWindowFocused ? Color(red: 0.12, green: 0.36, blue: 0.77) : Color(red: 0.43, green: 0.55, blue: 0.77)
        }
    }

    private var backgroundGradient: LinearGradient {
        if type == .close {
            if !isWindowFocused {
                return LinearGradient(
                    colors: [Color(red: 0.72, green: 0.48, blue: 0.45), Color(red: 0.58, green: 0.35, blue: 0.32)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            if isPressed {
                return LinearGradient(
                    colors: [Color(red: 0.65, green: 0.13, blue: 0.05), Color(red: 0.50, green: 0.08, blue: 0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else if isHovered {
                return LinearGradient(
                    colors: [Color(red: 0.98, green: 0.40, blue: 0.28), Color(red: 0.90, green: 0.22, blue: 0.10)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.88, green: 0.30, blue: 0.18), Color(red: 0.76, green: 0.18, blue: 0.08)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        } else {
            if !isWindowFocused {
                return LinearGradient(
                    colors: [Color(red: 0.56, green: 0.67, blue: 0.86), Color(red: 0.43, green: 0.55, blue: 0.77)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            if isPressed {
                return LinearGradient(
                    colors: [Color(red: 0.07, green: 0.26, blue: 0.58), Color(red: 0.04, green: 0.17, blue: 0.42)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else if isHovered {
                return LinearGradient(
                    colors: [Color(red: 0.42, green: 0.65, blue: 0.98), Color(red: 0.20, green: 0.48, blue: 0.88)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                return LinearGradient(
                    colors: [Color(red: 0.28, green: 0.52, blue: 0.90), Color(red: 0.12, green: 0.36, blue: 0.77)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private var borderColor: Color {
        if type == .close {
            return isWindowFocused ? Color(red: 0.95, green: 0.60, blue: 0.55) : Color(red: 0.80, green: 0.65, blue: 0.62)
        } else {
            return isWindowFocused ? Color(red: 0.65, green: 0.80, blue: 1.0) : Color(red: 0.70, green: 0.78, blue: 0.90)
        }
    }
}
