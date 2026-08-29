import SwiftUI

public struct AnyScreenSaverView: View {
    public var type: ScreenSaverType
    public var starfieldSettings: StarfieldSettings
    public var pipesSettings: Pipes3DSettings
    public var mystifySettings: MystifySettings
    public var xp3DLogoSettings: XP3DLogoSettings
    public var isMiniPreview: Bool

    public init(
        type: ScreenSaverType,
        starfieldSettings: StarfieldSettings = StarfieldSettings(),
        pipesSettings: Pipes3DSettings = Pipes3DSettings(),
        mystifySettings: MystifySettings = MystifySettings(),
        xp3DLogoSettings: XP3DLogoSettings = XP3DLogoSettings(),
        isMiniPreview: Bool = false
    ) {
        self.type = type
        self.starfieldSettings = starfieldSettings
        self.pipesSettings = pipesSettings
        self.mystifySettings = mystifySettings
        self.xp3DLogoSettings = xp3DLogoSettings
        self.isMiniPreview = isMiniPreview
    }

    public var body: some View {
        switch type {
        case .none:
            Color.black
        case .starfield:
            StarfieldScreenSaverView(settings: starfieldSettings, isMiniPreview: isMiniPreview)
        case .pipes3D:
            Pipes3DScreenSaverView(settings: pipesSettings, isMiniPreview: isMiniPreview)
        case .mystify:
            MystifyScreenSaverView(settings: mystifySettings, isMiniPreview: isMiniPreview)
        case .xp3DLogo:
            XP3DLogoScreenSaverView(settings: xp3DLogoSettings, isMiniPreview: isMiniPreview)
        case .blank:
            BlankScreenSaverView()
        }
    }
}
