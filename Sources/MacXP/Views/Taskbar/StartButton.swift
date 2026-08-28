import SwiftUI

public struct StartButtonShape: InsettableShape {
    public var insetAmount: CGFloat = 0

    public init(insetAmount: CGFloat = 0) {
        self.insetAmount = insetAmount
    }

    public func inset(by amount: CGFloat) -> StartButtonShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }

    public func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        var path = Path()
        let r: CGFloat = max(0, insetRect.height / 2)
        path.move(to: CGPoint(x: insetRect.minX, y: insetRect.minY))
        path.addLine(to: CGPoint(x: max(insetRect.minX, insetRect.maxX - r), y: insetRect.minY))
        if r > 0 {
            path.addArc(
                center: CGPoint(x: max(insetRect.minX, insetRect.maxX - r), y: insetRect.minY + r),
                radius: r,
                startAngle: .degrees(270),
                endAngle: .degrees(90),
                clockwise: false
            )
        }
        path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.maxY))
        path.closeSubpath()
        return path
    }
}

public struct XPFlagIcon: View {
    public var size: CGFloat = 16

    public init(size: CGFloat = 16) {
        self.size = size
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 1.5) {
                HStack(spacing: 1.5) {
                    // Red pane (top-left)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(red: 0.93, green: 0.28, blue: 0.16))
                        .frame(width: size * 0.45, height: size * 0.45)
                    // Green pane (top-right)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(red: 0.44, green: 0.74, blue: 0.16))
                        .frame(width: size * 0.45, height: size * 0.45)
                }
                HStack(spacing: 1.5) {
                    // Blue pane (bottom-left)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(red: 0.05, green: 0.58, blue: 0.91))
                        .frame(width: size * 0.45, height: size * 0.45)
                    // Yellow pane (bottom-right)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(red: 0.98, green: 0.76, blue: 0.13))
                        .frame(width: size * 0.45, height: size * 0.45)
                }
            }
            .rotationEffect(.degrees(-8))
            .shadow(color: Color.black.opacity(0.4), radius: 1, x: 0.5, y: 0.5)
        }
        .frame(width: size, height: size)
    }
}

public struct StartButton: View {
    public let isOpen: Bool
    public let action: () -> Void

    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false

    public init(isOpen: Bool, action: @escaping () -> Void) {
        self.isOpen = isOpen
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                XPFlagIcon(size: 18)
                    .padding(.leading, 6)

                Text("start")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .italic()
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.8), radius: 1.5, x: 1, y: 1)

                Spacer()
            }
            .frame(width: 104, height: 30)
            .background(backgroundGradient)
            .clipShape(StartButtonShape())
            .overlay(
                StartButtonShape()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color(red: 0.08, green: 0.32, blue: 0.08)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .overlay(
                VStack {
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isOpen || isPressed ? 0.05 : 0.45),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 14)
                    Spacer()
                }
                .clipShape(StartButtonShape())
            )
            .shadow(
                color: Color.black.opacity(isOpen || isPressed ? 0.0 : 0.3),
                radius: 2,
                x: 1,
                y: 1
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var backgroundGradient: LinearGradient {
        if isOpen || isPressed {
            return LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.38, blue: 0.12),
                    Color(red: 0.18, green: 0.50, blue: 0.18),
                    Color(red: 0.15, green: 0.44, blue: 0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else if isHovered {
            return LinearGradient(
                colors: [
                    Color(red: 0.35, green: 0.78, blue: 0.35),
                    Color(red: 0.28, green: 0.70, blue: 0.28),
                    Color(red: 0.20, green: 0.58, blue: 0.20)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.24, green: 0.65, blue: 0.24), // #3da63d
                    Color(red: 0.22, green: 0.58, blue: 0.22), // #389438
                    Color(red: 0.14, green: 0.45, blue: 0.14)  // #247324
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}
