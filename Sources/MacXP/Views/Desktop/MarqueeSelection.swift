import SwiftUI

public struct MarqueeHelper {
    public static func calculateRect(from start: CGPoint, to current: CGPoint) -> CGRect {
        let minX = min(start.x, current.x)
        let minY = min(start.y, current.y)
        let width = abs(current.x - start.x)
        let height = abs(current.y - start.y)
        return CGRect(x: minX, y: minY, width: width, height: height)
    }
}

public struct MarqueeSelectionView: View {
    public let rect: CGRect

    public init(rect: CGRect) {
        self.rect = rect
    }

    public var body: some View {
        Rectangle()
            .fill(Color(red: 0.19, green: 0.42, blue: 0.77).opacity(0.35)) // #316ac5 semi-transparent
            .overlay(
                Rectangle()
                    .strokeBorder(
                        Color(red: 0.19, green: 0.42, blue: 0.77),
                        lineWidth: 1
                    )
            )
            .frame(width: max(0, rect.width), height: max(0, rect.height))
            .position(
                x: rect.origin.x + rect.width / 2,
                y: rect.origin.y + rect.height / 2
            )
            .allowsHitTesting(false)
    }
}
