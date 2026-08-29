import SwiftUI
#if os(macOS)
import AppKit
#endif

public struct IEIconView: View {
    public let size: CGFloat

    public init(size: CGFloat = 32) {
        self.size = size
    }

    public var body: some View {
        #if os(macOS)
        if let icon = XPAssetProvider.loadIEIcon() {
            Image(nsImage: icon)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            fallbackSymbol
        }
        #else
        fallbackSymbol
        #endif
    }

    private var fallbackSymbol: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.20, green: 0.60, blue: 0.95), Color(red: 0.05, green: 0.35, blue: 0.80)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.85, height: size * 0.85)

            Text("e")
                .font(.system(size: size * 0.75, weight: .black, design: .serif))
                .italic()
                .foregroundColor(.white)
                .offset(x: -size * 0.04, y: -size * 0.04)

            // Signature Golden Halo Ring
            Ellipse()
                .stroke(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.85, blue: 0.20), Color(red: 0.85, green: 0.60, blue: 0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(1.5, size * 0.07)
                )
                .frame(width: size * 1.05, height: size * 0.45)
                .rotationEffect(.degrees(-35))
        }
        .frame(width: size, height: size)
    }
}
