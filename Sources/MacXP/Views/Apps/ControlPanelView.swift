import SwiftUI

public struct ControlCategoryItem: Identifiable {
    public let id = UUID()
    public var title: String
    public var description: String
    public var iconName: String
    public var action: (WindowManager) -> Void
}

public struct ControlPanelView: View {
    @ObservedObject public var windowManager: WindowManager
    public var window: XPWindowInstance
    
    @State private var isClassicView: Bool = false
    
    public init(windowManager: WindowManager, window: XPWindowInstance) {
        self.windowManager = windowManager
        self.window = window
    }
    
    private var categories: [ControlCategoryItem] {
        [
            ControlCategoryItem(
                title: "Appearance and Themes",
                description: "Change the appearance of desktop items, apply a theme or screen saver, or customize the Start menu and taskbar.",
                iconName: "paintbrush.fill",
                action: { wm in wm.openWindow(appType: .displayProperties) }
            ),
            ControlCategoryItem(
                title: "Network and Internet Connections",
                description: "Connect to the Internet, set up a home or small office network, or change settings for your network connections.",
                iconName: "network",
                action: { wm in wm.openWindow(appType: .cmd) }
            ),
            ControlCategoryItem(
                title: "Add or Remove Programs",
                description: "Install or remove programs and Windows components.",
                iconName: "square.grid.3x3.topleft.filled",
                action: { wm in wm.openWindow(appType: .explorer(path: "/Applications"), title: "Applications") }
            ),
            ControlCategoryItem(
                title: "Sounds, Speech, and Audio Devices",
                description: "Change the sound scheme for your computer, or configure settings for your speakers and recording devices.",
                iconName: "speaker.wave.3.fill",
                action: { wm in wm.openWindow(appType: .systemProperties, title: "Sound Properties") }
            ),
            ControlCategoryItem(
                title: "Performance and Maintenance",
                description: "View information about your computer's hardware, free up hard disk space, or arrange items on your hard disk.",
                iconName: "speedometer",
                action: { wm in wm.openWindow(appType: .systemProperties) }
            ),
            ControlCategoryItem(
                title: "Printers and Other Hardware",
                description: "Set up and manage printers, faxes, scanners, cameras, mouse, keyboard, game controllers, and other devices.",
                iconName: "printer.fill",
                action: { wm in wm.openWindow(appType: .systemProperties, title: "Hardware Properties") }
            ),
            ControlCategoryItem(
                title: "User Accounts",
                description: "Change user account settings and passwords for people who share this computer.",
                iconName: "person.2.fill",
                action: { wm in wm.openWindow(appType: .systemProperties, title: "User Accounts") }
            ),
            ControlCategoryItem(
                title: "Date, Time, Language, and Regional Options",
                description: "Change the date, time, and time zone for your computer, or choose languages and regional formats.",
                iconName: "calendar.badge.clock",
                action: { wm in wm.openWindow(appType: .systemProperties, title: "Date and Time Properties") }
            ),
            ControlCategoryItem(
                title: "Accessibility Options",
                description: "Adjust your computer settings for vision, hearing, and mobility.",
                iconName: "figure.roll",
                action: { wm in wm.openWindow(appType: .systemProperties, title: "Accessibility Options") }
            ),
            ControlCategoryItem(
                title: "Security Center",
                description: "Take control of your computer's security settings and monitor protection status.",
                iconName: "shield.fill",
                action: { wm in wm.openWindow(appType: .systemProperties, title: "Windows Security Center") }
            )
        ]
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            // Left XP Sidebar
            sidebarView
                .frame(width: 190)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.44, green: 0.58, blue: 0.88),
                            Color(red: 0.25, green: 0.40, blue: 0.75)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            Divider()
            
            // Right Main Content Area
            ScrollView {
                if isClassicView {
                    classicGridView
                } else {
                    categoryListView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Sidebar
    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Task Section 1: Control Panel
            VStack(alignment: .leading, spacing: 4) {
                sidebarSectionHeader(title: "Control Panel")
                
                Button(action: {
                    isClassicView.toggle()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isClassicView ? "list.bullet" : "square.grid.2x2")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.15, green: 0.45, blue: 0.85))
                        Text(isClassicView ? "Switch to Category View" : "Switch to Classic View")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.05, green: 0.25, blue: 0.65))
                            .underline()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .padding(.horizontal, 8)
            .padding(.top, 8)
            
            // Task Section 2: See Also
            VStack(alignment: .leading, spacing: 4) {
                sidebarSectionHeader(title: "See Also")
                
                sidebarLink(title: "Windows Update", icon: "arrow.triangle.2.circlepath") {
                    windowManager.openWindow(appType: .systemProperties, title: "Windows Update")
                }
                sidebarLink(title: "Help and Support", icon: "questionmark.circle.fill") {
                    windowManager.openWindow(appType: .systemProperties, title: "Help and Support Center")
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .padding(.horizontal, 8)
            
            Spacer()
        }
    }
    
    private func sidebarSectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(red: 0.05, green: 0.20, blue: 0.55))
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            LinearGradient(
                colors: [Color.white, Color(red: 0.85, green: 0.90, blue: 0.98)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func sidebarLink(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.15, green: 0.45, blue: 0.85))
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.05, green: 0.25, blue: 0.65))
                    .underline()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Category View
    private var categoryListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pick a category")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(red: 0.05, green: 0.20, blue: 0.55))
                .padding(.horizontal, 16)
                .padding(.top, 12)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(categories) { category in
                    Button(action: {
                        category.action(windowManager)
                    }) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: category.iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 28, height: 28)
                                .foregroundColor(Color(red: 0.15, green: 0.45, blue: 0.85))
                                .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(category.title)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color(red: 0.05, green: 0.25, blue: 0.65))
                                    .underline()
                                    .multilineTextAlignment(.leading)
                                
                                Text(category.description)
                                    .font(.system(size: 10))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                        }
                        .padding(6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Classic View
    private var classicGridView: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 12) {
            ForEach(categories) { category in
                Button(action: {
                    category.action(windowManager)
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: category.iconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .foregroundColor(Color(red: 0.15, green: 0.45, blue: 0.85))
                        
                        Text(category.title)
                            .font(.system(size: 11))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(width: 80, height: 75)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
    }
}
