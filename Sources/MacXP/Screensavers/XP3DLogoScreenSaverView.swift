import SwiftUI

public struct XP3DLogoScreenSaverView: View {
    public var settings: XP3DLogoSettings
    public var isMiniPreview: Bool

    @State private var state: XP3DLogoState
    @State private var lastDate: Date = Date()

    public init(settings: XP3DLogoSettings = XP3DLogoSettings(), isMiniPreview: Bool = false) {
        self.settings = settings
        self.isMiniPreview = isMiniPreview
        let bounds = isMiniPreview ? CGSize(width: 200, height: 150) : CGSize(width: 1200, height: 800)
        let adjustedSettings = isMiniPreview ? XP3DLogoSettings(speed: settings.speed, logoSize: 50.0) : settings
        self._state = State(initialValue: XP3DLogoState(settings: adjustedSettings, bounds: bounds))
    }

    public var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                ZStack {
                    Color.black.ignoresSafeArea()

                    // Shaded 3D Windows Flag Emblem
                    XPFlagIcon(size: CGFloat(isMiniPreview ? 50.0 : settings.logoSize))
                        .rotation3DEffect(.degrees(state.rotationAngle), axis: (x: 0.2, y: 1.0, z: 0.1))
                        .shadow(color: Color.blue.opacity(0.4), radius: 15, x: 5, y: 5)
                        .position(state.position)
                }
                .onChange(of: timeline.date) { newDate in
                    let dt = min(0.1, newDate.timeIntervalSince(lastDate))
                    lastDate = newDate
                    state.update(deltaTime: dt > 0 ? dt : 0.016, bounds: geo.size)
                }
            }
        }
        .background(Color.black)
    }
}
