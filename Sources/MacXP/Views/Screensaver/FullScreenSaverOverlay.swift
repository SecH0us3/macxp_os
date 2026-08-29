import SwiftUI

public struct FullScreenSaverOverlay: View {
    @ObservedObject public var manager = ScreenSaverManager.shared

    public init() {}

    public var body: some View {
        ZStack {
            AnyScreenSaverView(
                type: manager.effectiveType,
                starfieldSettings: manager.starfieldSettings,
                pipesSettings: manager.pipesSettings,
                mystifySettings: manager.mystifySettings,
                xp3DLogoSettings: manager.xp3DLogoSettings,
                isMiniPreview: false
            )
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                manager.dismissScreenSaver()
            }
            .onHover { _ in
                // Handled via event monitor
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
