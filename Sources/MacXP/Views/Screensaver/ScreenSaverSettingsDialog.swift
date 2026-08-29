import SwiftUI

public struct ScreenSaverSettingsDialog: View {
    @ObservedObject public var manager = ScreenSaverManager.shared
    public var type: ScreenSaverType
    public var onClose: () -> Void

    public init(type: ScreenSaverType, onClose: @escaping () -> Void) {
        self.type = type
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("\(type.title) Settings")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(Color(red: 0.85, green: 0.25, blue: 0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.0, green: 0.33, blue: 0.92), Color(red: 0.05, green: 0.20, blue: 0.65)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Content per screensaver type
            VStack(alignment: .leading, spacing: 10) {
                switch type {
                case .starfield:
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Warp Speed:")
                            .font(.system(size: 11, weight: .bold))
                        Slider(value: $manager.starfieldSettings.speed, in: 2.0...35.0, step: 1.0)
                        
                        Text("Star Count: \(manager.starfieldSettings.starCount)")
                            .font(.system(size: 11, weight: .bold))
                        Slider(value: Binding(
                            get: { Double(manager.starfieldSettings.starCount) },
                            set: { manager.starfieldSettings.starCount = Int($0) }
                        ), in: 100...2000, step: 50)

                        Toggle("Show Warp Velocity Trails", isOn: $manager.starfieldSettings.warpTrail)
                            .font(.system(size: 11))
                    }

                case .pipes3D:
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Number of Pipes: \(manager.pipesSettings.maxPipes)")
                            .font(.system(size: 11, weight: .bold))
                        Slider(value: Binding(
                            get: { Double(manager.pipesSettings.maxPipes) },
                            set: { manager.pipesSettings.maxPipes = Int($0) }
                        ), in: 1...8, step: 1)

                        Text("Joint Type:")
                            .font(.system(size: 11, weight: .bold))
                        Picker("Joint Type", selection: $manager.pipesSettings.jointType) {
                            ForEach(Pipes3DJointType.allCases) { jt in
                                Text(jt.title).tag(jt)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        Toggle("Smooth Cylinders", isOn: $manager.pipesSettings.isSmooth)
                            .font(.system(size: 11))
                    }

                case .mystify:
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Polygons: \(manager.mystifySettings.polygonCount)")
                            .font(.system(size: 11, weight: .bold))
                        Slider(value: Binding(
                            get: { Double(manager.mystifySettings.polygonCount) },
                            set: { manager.mystifySettings.polygonCount = Int($0) }
                        ), in: 1...6, step: 1)

                        Text("Lines per Polygon: \(manager.mystifySettings.lineCount)")
                            .font(.system(size: 11, weight: .bold))
                        Slider(value: Binding(
                            get: { Double(manager.mystifySettings.lineCount) },
                            set: { manager.mystifySettings.lineCount = Int($0) }
                        ), in: 4...25, step: 1)
                    }

                case .xp3DLogo:
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Motion Speed:")
                            .font(.system(size: 11, weight: .bold))
                        Slider(value: $manager.xp3DLogoSettings.speed, in: 0.5...2.5, step: 0.1)

                        Text("Logo Size: \(Int(manager.xp3DLogoSettings.logoSize))px")
                            .font(.system(size: 11, weight: .bold))
                        Slider(value: $manager.xp3DLogoSettings.logoSize, in: 60...200, step: 10)
                    }

                case .blank, .none:
                    Text("This screen saver has no options.")
                        .font(.system(size: 11))
                }
            }
            .padding(.horizontal, 14)

            Divider()

            // OK Button
            HStack {
                Spacer()
                Button("OK", action: onClose)
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 75, height: 22)
                    .background(Color(red: 0.92, green: 0.92, blue: 0.92))
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.gray, lineWidth: 1))
                    .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
        .frame(width: 320)
        .background(Color(red: 0.94, green: 0.94, blue: 0.94))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(red: 0.0, green: 0.2, blue: 0.7), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.35), radius: 10, x: 2, y: 2)
    }
}
