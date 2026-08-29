import SwiftUI

public struct DisplayPropertiesView: View {
    @ObservedObject public var screenSaverManager = ScreenSaverManager.shared
    public var onClose: (() -> Void)?

    @State private var selectedTab: Int = 2 // Screen Saver tab by default
    @State private var isShowingSettingsModal: Bool = false

    public init(onClose: (() -> Void)? = nil) {
        self.onClose = onClose
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Tab Header
                HStack(spacing: 2) {
                    tabButton(title: "Themes", index: 0)
                    tabButton(title: "Desktop", index: 1)
                    tabButton(title: "Screen Saver", index: 2)
                    tabButton(title: "Appearance", index: 3)
                    tabButton(title: "Settings", index: 4)
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.top, 6)

                // Tab Content Pane
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(red: 0.94, green: 0.94, blue: 0.94))
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.gray.opacity(0.6), lineWidth: 1))

                    Group {
                        switch selectedTab {
                        case 0:
                            themesTab
                        case 1:
                            desktopTab
                        case 2:
                            screenSaverTab
                        case 3:
                            appearanceTab
                        case 4:
                            settingsTab
                        default:
                            screenSaverTab
                        }
                    }
                    .padding(14)
                }
                .padding(.horizontal, 8)
                .padding(.top, -1)

                // Bottom Buttons (OK / Cancel / Apply)
                HStack(spacing: 8) {
                    Spacer()
                    classicButton(title: "OK", isBold: true) {
                        onClose?()
                    }
                    classicButton(title: "Cancel") {
                        onClose?()
                    }
                    classicButton(title: "Apply") {
                        // Applied immediately
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }
            .background(Color(red: 0.93, green: 0.93, blue: 0.93))

            // Settings Modal
            if isShowingSettingsModal {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isShowingSettingsModal = false
                    }

                ScreenSaverSettingsDialog(type: screenSaverManager.selectedType) {
                    isShowingSettingsModal = false
                }
            }
        }
    }

    // MARK: - Screen Saver Tab
    private var screenSaverTab: some View {
        VStack(spacing: 12) {
            // CRT Monitor Preview Graphic
            ZStack {
                // Monitor Bezel Frame
                VStack(spacing: 0) {
                    // Monitor CRT Frame
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(
                                colors: [Color(red: 0.78, green: 0.78, blue: 0.80), Color(red: 0.65, green: 0.65, blue: 0.68)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 170, height: 125)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray, lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.2), radius: 2, x: 1, y: 1)

                        // CRT Screen Inset Viewport
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.black)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black, lineWidth: 2))

                            AnyScreenSaverView(
                                type: screenSaverManager.selectedType,
                                starfieldSettings: screenSaverManager.starfieldSettings,
                                pipesSettings: screenSaverManager.pipesSettings,
                                mystifySettings: screenSaverManager.mystifySettings,
                                xp3DLogoSettings: screenSaverManager.xp3DLogoSettings,
                                isMiniPreview: true
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .frame(width: 140, height: 95)

                        // Power LED Indicator
                        Circle()
                            .fill(screenSaverManager.selectedType != .none ? Color.green : Color.orange)
                            .frame(width: 4, height: 4)
                            .offset(x: 60, y: 55)
                    }

                    // Monitor Stand Base
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(red: 0.62, green: 0.62, blue: 0.65))
                            .frame(width: 32, height: 10)
                        Ellipse()
                            .fill(Color(red: 0.70, green: 0.70, blue: 0.74))
                            .frame(width: 75, height: 12)
                    }
                }
            }
            .frame(height: 150)

            // Screen Saver Controls Box
            VStack(alignment: .leading, spacing: 10) {
                Text("Screen saver")
                    .font(.system(size: 11, weight: .bold))

                HStack(spacing: 8) {
                    Picker("", selection: $screenSaverManager.selectedType) {
                        ForEach(ScreenSaverType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 180)

                    classicButton(title: "Settings...", isEnabled: screenSaverManager.selectedType.hasSettings) {
                        isShowingSettingsModal = true
                    }

                    classicButton(title: "Preview", isEnabled: screenSaverManager.selectedType != .none) {
                        screenSaverManager.triggerFullScreenPreview()
                    }
                }

                HStack(spacing: 6) {
                    Text("Wait:")
                        .font(.system(size: 11))
                    
                    Stepper(value: $screenSaverManager.waitMinutes, in: 1...99) {
                        Text("\(screenSaverManager.waitMinutes)")
                            .font(.system(size: 11))
                            .frame(width: 25)
                    }
                    .frame(width: 90)

                    Text("minutes")
                        .font(.system(size: 11))
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 3).stroke(Color.gray.opacity(0.5), lineWidth: 1))

            Spacer()
        }
    }

    // MARK: - Other Tabs
    private var themesTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("A theme is a background plus a set of sounds, icons, and other elements to help you personalize your computer with one click.")
                .font(.system(size: 11))
                .foregroundColor(.black)
            
            Text("Theme:")
                .font(.system(size: 11, weight: .bold))
            Text("Windows XP (Modified)")
                .font(.system(size: 12))
                .padding(6)
                .background(Color.white)
                .overlay(Rectangle().stroke(Color.gray, lineWidth: 1))
            Spacer()
        }
    }

    private var desktopTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Background:")
                .font(.system(size: 11, weight: .bold))
            let wallpapers = ["Bliss (Windows XP Standard)", "Solid Blue", "Autumn", "Azul"]
            VStack(spacing: 0) {
                ForEach(wallpapers, id: \.self) { wp in
                    let isSel = DesktopManager.shared.selectedWallpaper == wp
                    HStack {
                        Image(systemName: "photo")
                            .font(.system(size: 11))
                            .foregroundColor(isSel ? .white : .blue)
                        Text(wp)
                            .font(.system(size: 11))
                            .foregroundColor(isSel ? .white : .black)
                        Spacer()
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(isSel ? Color(red: 0.19, green: 0.42, blue: 0.77) : Color.white)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        DesktopManager.shared.selectedWallpaper = wp
                        SoundManager.shared.play(.navigation)
                    }
                }
            }
            .frame(height: 140, alignment: .top)
            .background(Color.white)
            .overlay(Rectangle().stroke(Color.gray, lineWidth: 1))
            Spacer()
        }
    }

    private var appearanceTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Windows and buttons:")
                .font(.system(size: 11, weight: .bold))
            Text("Windows XP style")
                .font(.system(size: 11))
            
            Text("Color scheme:")
                .font(.system(size: 11, weight: .bold))
            Text("Default (blue)")
                .font(.system(size: 11))
            Spacer()
        }
    }

    private var settingsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Display:")
                .font(.system(size: 11, weight: .bold))
            Text("Default Monitor on Apple Silicon")
                .font(.system(size: 11))
            Text("Color quality:")
                .font(.system(size: 11, weight: .bold))
            Text("Highest (32 bit)")
                .font(.system(size: 11))
            Spacer()
        }
    }

    // MARK: - UI Components
    private func tabButton(title: String, index: Int) -> some View {
        let isSelected = selectedTab == index
        return Button(action: {
            selectedTab = index
        }) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                .foregroundColor(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    isSelected ?
                        Color(red: 0.94, green: 0.94, blue: 0.94) :
                        Color(red: 0.88, green: 0.88, blue: 0.88)
                )
                .clipShape(TopRoundedRectangle(radius: 4))
                .overlay(
                    TopRoundedRectangle(radius: 4)
                        .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func classicButton(title: String, isBold: Bool = false, isEnabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isBold ? .bold : .regular))
                .foregroundColor(isEnabled ? .black : Color.gray)
                .frame(minWidth: 72, minHeight: 22)
                .background(Color(red: 0.92, green: 0.92, blue: 0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.gray, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
    }
}
