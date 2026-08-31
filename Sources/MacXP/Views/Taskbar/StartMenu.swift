import SwiftUI

public struct StartMenuItem: Identifiable {
    public let id: UUID
    public var title: String
    public var subtitle: String?
    public var iconName: String
    public var isBold: Bool
    public var action: (WindowManager) -> Void

    public init(
        id: UUID = UUID(),
        title: String,
        subtitle: String? = nil,
        iconName: String,
        isBold: Bool = false,
        action: @escaping (WindowManager) -> Void
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.isBold = isBold
        self.action = action
    }
}

public class StartMenuModel: ObservableObject {
    @Published public var userName: String
    @Published public var pinnedItems: [StartMenuItem] = []
    @Published public var recentItems: [StartMenuItem] = []
    @Published public var systemShortcuts: [StartMenuItem] = []
    @Published public var allPrograms: [StartMenuItem] = []

    public init(userName: String? = nil) {
        #if os(macOS)
        let full = NSFullUserName()
        let short = NSUserName()
        self.userName = userName ?? (!full.isEmpty ? full : (!short.isEmpty ? short : "Administrator"))
        #else
        self.userName = userName ?? "Administrator"
        #endif

        setupDefaultItems()
    }

    private func setupDefaultItems() {
        pinnedItems = [
            StartMenuItem(
                title: "Internet",
                subtitle: "Internet Explorer",
                iconName: "globe",
                isBold: true,
                action: { wm in
                    wm.openWindow(appType: .internetExplorer(url: "https://www.google.com"), title: "Internet Explorer", icon: "globe")
                }
            ),
            StartMenuItem(
                title: "E-mail",
                subtitle: "Outlook Express",
                iconName: "envelope.fill",
                isBold: true,
                action: { wm in
                    wm.openWindow(appType: .notepad(fileURL: nil), title: "Outlook Express", icon: "envelope.fill")
                }
            ),
            StartMenuItem(
                title: "Windows Media Player",
                subtitle: "Play Music & Videos",
                iconName: "play.rectangle.fill",
                isBold: true,
                action: { wm in
                    wm.openWindow(appType: .mediaPlayer(fileURL: nil), title: "Windows Media Player", icon: "play.rectangle.fill")
                }
            )
        ]

        recentItems = [
            StartMenuItem(
                title: "Notepad",
                iconName: "doc.text.fill",
                action: { wm in wm.openWindow(appType: .notepad(fileURL: nil)) }
            ),
            StartMenuItem(
                title: "Command Prompt",
                iconName: "terminal.fill",
                action: { wm in wm.openWindow(appType: .cmd) }
            ),
            StartMenuItem(
                title: "Calculator",
                iconName: "plus.forwardslash.minus",
                action: { wm in wm.openWindow(appType: .calculator) }
            ),
            StartMenuItem(
                title: "Minesweeper",
                iconName: "flag.fill",
                action: { wm in wm.openWindow(appType: .minesweeper) }
            ),
            StartMenuItem(
                title: "Paint",
                iconName: "paintbrush.fill",
                action: { wm in wm.openWindow(appType: .paint) }
            ),
            StartMenuItem(
                title: "Macromedia Flash Player",
                iconName: "flame.fill",
                action: { wm in wm.openWindow(appType: .flashPlayer()) }
            )
        ]

        #if os(macOS)
        let homeDir = NSHomeDirectory()
        let docsPath = (homeDir as NSString).appendingPathComponent("Documents")
        let picsPath = (homeDir as NSString).appendingPathComponent("Pictures")
        let musicPath = (homeDir as NSString).appendingPathComponent("Music")
        #else
        let docsPath = "/Documents"
        let picsPath = "/Pictures"
        let musicPath = "/Music"
        #endif

        systemShortcuts = [
            StartMenuItem(
                title: "My Documents",
                iconName: "folder.fill",
                isBold: true,
                action: { wm in wm.openWindow(appType: .explorer(path: docsPath), title: "My Documents") }
            ),
            StartMenuItem(
                title: "My Pictures",
                iconName: "photo.fill",
                isBold: true,
                action: { wm in wm.openWindow(appType: .explorer(path: picsPath), title: "My Pictures") }
            ),
            StartMenuItem(
                title: "My Music",
                iconName: "music.note",
                isBold: true,
                action: { wm in wm.openWindow(appType: .explorer(path: musicPath), title: "My Music") }
            ),
            StartMenuItem(
                title: "My Computer",
                iconName: "desktopcomputer",
                isBold: true,
                action: { wm in wm.openWindow(appType: .explorer(path: "/"), title: "My Computer") }
            ),
            StartMenuItem(
                title: "Control Panel",
                iconName: "gearshape.fill",
                isBold: false,
                action: { wm in wm.openWindow(appType: .controlPanel) }
            ),
            StartMenuItem(
                title: "System Properties",
                iconName: "info.circle.fill",
                isBold: false,
                action: { wm in wm.openWindow(appType: .systemProperties) }
            ),
            StartMenuItem(
                title: "Search",
                iconName: "magnifyingglass",
                isBold: false,
                action: { wm in wm.openWindow(appType: .explorer(path: "/"), title: "Search Results") }
            ),
            StartMenuItem(
                title: "Run...",
                iconName: "play.fill",
                isBold: false,
                action: { wm in wm.openWindow(appType: .runDialog) }
            )
        ]

        allPrograms = [
            StartMenuItem(title: "Command Prompt", iconName: "terminal.fill", action: { wm in wm.openWindow(appType: .cmd) }),
            StartMenuItem(title: "Notepad", iconName: "doc.text.fill", action: { wm in wm.openWindow(appType: .notepad(fileURL: nil)) }),
            StartMenuItem(title: "Calculator", iconName: "plus.forwardslash.minus", action: { wm in wm.openWindow(appType: .calculator) }),
            StartMenuItem(title: "Minesweeper", iconName: "flag.fill", action: { wm in wm.openWindow(appType: .minesweeper) }),
            StartMenuItem(title: "3D Pinball", iconName: "circle.circle.fill", action: { wm in wm.openWindow(appType: .pinball) }),
            StartMenuItem(title: "Solitaire", iconName: "suit.spade.fill", action: { wm in wm.openWindow(appType: .solitaire) }),
            StartMenuItem(title: "Paint", iconName: "paintbrush.fill", action: { wm in wm.openWindow(appType: .paint) }),
            StartMenuItem(title: "Macromedia Flash Player", iconName: "flame.fill", action: { wm in wm.openWindow(appType: .flashPlayer()) }),
            StartMenuItem(title: "Windows Explorer", iconName: "folder.fill", action: { wm in wm.openWindow(appType: .explorer(path: "/")) }),
            StartMenuItem(title: "Windows Media Player", iconName: "play.rectangle.fill", action: { wm in wm.openWindow(appType: .mediaPlayer(fileURL: nil)) }),
            StartMenuItem(title: "Control Panel", iconName: "gearshape.fill", action: { wm in wm.openWindow(appType: .controlPanel) }),
            StartMenuItem(title: "System Properties", iconName: "info.circle.fill", action: { wm in wm.openWindow(appType: .systemProperties) })
        ]
    }
}

public enum AllProgramsCategoryKey: Equatable, Hashable {
    case accessories
    case games
    case macCategory(MacAppCategory)
    case allMacApps
}

public struct StartMenuView: View {
    @ObservedObject public var windowManager: WindowManager
    @ObservedObject public var model: StartMenuModel
    public var onClose: () -> Void
    public var onTurnOff: (() -> Void)?

    @State private var hoveredItemID: UUID? = nil
    @State private var hoveredAppID: UUID? = nil
    @State private var isAllProgramsOpen: Bool = false
    @State private var activeFlyout: AllProgramsCategoryKey? = nil
    @ObservedObject private var appDiscovery = MacAppDiscoveryService.shared

    public init(
        windowManager: WindowManager,
        model: StartMenuModel,
        onClose: @escaping () -> Void,
        onTurnOff: (() -> Void)? = nil
    ) {
        self.windowManager = windowManager
        self.model = model
        self.onClose = onClose
        self.onTurnOff = onTurnOff
    }

    public var body: some View {
        ZStack(alignment: .bottomLeading) {
            VStack(spacing: 0) {
                // Header (User Banner)
                headerView

                // 2-Column Main Body
                HStack(spacing: 0) {
                    // Left Column (White) - Pinned & Recent
                    leftColumnView
                        .frame(width: 200)
                        .background(Color.white)

                    // Right Column (Luna Blue tint) - System shortcuts
                    rightColumnView
                        .frame(width: 180)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.83, green: 0.90, blue: 0.98),
                                    Color(red: 0.78, green: 0.87, blue: 0.97)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            Rectangle()
                                .frame(width: 1)
                                .foregroundColor(Color(red: 0.58, green: 0.74, blue: 0.93)),
                            alignment: .leading
                        )
                }
                .frame(height: 380)

                // Footer (Log Off & Turn Off)
                footerView
            }
            .frame(width: 380)
            .background(Color.white)
            .clipShape(TopRoundedRectangle(radius: 6))
            .overlay(
                TopRoundedRectangle(radius: 6)
                    .strokeBorder(
                        Color(red: 0.00, green: 0.20, blue: 0.70),
                        lineWidth: 1
                    )
            )

            // All Programs Flyout
            if isAllProgramsOpen {
                allProgramsFlyout
                    .offset(x: 200, y: -42)
                    .zIndex(100)
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 10) {
            // User Avatar Box with XP style border
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color(red: 0.9, green: 0.9, blue: 0.95)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 42, height: 42)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color(red: 0.85, green: 0.75, blue: 0.40), lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 2, x: 1, y: 1)

                Image(systemName: "person.crop.square.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                    .foregroundColor(Color(red: 0.15, green: 0.45, blue: 0.85))
            }
            .padding(.leading, 8)

            Text(model.userName)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.7), radius: 1.5, x: 1, y: 1)

            Spacer()
        }
        .frame(height: 56)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.00, green: 0.33, blue: 0.92), // #0055ea
                    Color(red: 0.04, green: 0.39, blue: 0.86), // #0a64dc
                    Color(red: 0.11, green: 0.50, blue: 0.93)  // #1c7fed
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            VStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.4), Color.white.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 16)
                Spacer()
            }
        )
    }

    // MARK: - Left Column
    private var leftColumnView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Pinned items
            ForEach(model.pinnedItems) { item in
                menuItemRow(item: item, isLeftColumn: true)
            }

            Divider()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)

            // Recent items
            ForEach(model.recentItems) { item in
                menuItemRow(item: item, isLeftColumn: true)
            }

            Spacer()

            Divider()
                .padding(.horizontal, 8)

            // All Programs button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isAllProgramsOpen.toggle()
                    if !isAllProgramsOpen {
                        activeFlyout = nil
                    }
                }
            }) {
                HStack {
                    Spacer()
                    Text("All Programs")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.black)
                    Image(systemName: "play.fill")
                        .font(.system(size: 8))
                        .foregroundColor(Color(red: 0.15, green: 0.65, blue: 0.15))
                    Spacer()
                }
                .frame(height: 28)
                .background(
                    isAllProgramsOpen ?
                        Color(red: 0.19, green: 0.42, blue: 0.77).opacity(0.2) :
                        Color.clear
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.bottom, 6)
        }
        .padding(.top, 6)
    }

    // MARK: - Right Column
    private var rightColumnView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(model.systemShortcuts) { item in
                menuItemRow(item: item, isLeftColumn: false)
            }
            Spacer()
        }
        .padding(.top, 6)
    }

    // MARK: - Menu Item Row
    private func menuItemRow(item: StartMenuItem, isLeftColumn: Bool) -> some View {
        let isHovered = (hoveredItemID == item.id)

        return Button(action: {
            SoundManager.shared.play(.navigation)
            item.action(windowManager)
            onClose()
        }) {
            HStack(spacing: 8) {
                #if os(macOS)
                if item.title == "Internet" || item.subtitle == "Internet Explorer" {
                    IEIconView(size: isLeftColumn ? 22 : 18)
                        .frame(width: 24, height: 24)
                } else if item.title == "My Computer" || item.iconName == "desktopcomputer" {
                    if let icon = XPAssetProvider.loadMyComputerIcon() {
                        Image(nsImage: icon)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: isLeftColumn ? 22 : 18, height: isLeftColumn ? 22 : 18)
                    } else {
                        menuItemFallbackIcon(item: item, isLeftColumn: isLeftColumn, isHovered: isHovered)
                    }
                } else if item.title == "My Documents" {
                    if let icon = XPAssetProvider.loadMyDocumentsIcon() {
                        Image(nsImage: icon)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: isLeftColumn ? 22 : 18, height: isLeftColumn ? 22 : 18)
                    } else {
                        menuItemFallbackIcon(item: item, isLeftColumn: isLeftColumn, isHovered: isHovered)
                    }
                } else if item.title == "Control Panel" {
                    if let icon = XPAssetProvider.loadControlPanelIcon() {
                        Image(nsImage: icon)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: isLeftColumn ? 22 : 18, height: isLeftColumn ? 22 : 18)
                    } else {
                        menuItemFallbackIcon(item: item, isLeftColumn: isLeftColumn, isHovered: isHovered)
                    }
                } else if item.title == "Search" {
                    if let icon = XPAssetProvider.loadIcon(named: "search") {
                        Image(nsImage: icon)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: isLeftColumn ? 22 : 18, height: isLeftColumn ? 22 : 18)
                    } else {
                        menuItemFallbackIcon(item: item, isLeftColumn: isLeftColumn, isHovered: isHovered)
                    }
                } else if item.title == "Help and Support" {
                    if let icon = XPAssetProvider.loadIcon(named: "help") {
                        Image(nsImage: icon)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: isLeftColumn ? 22 : 18, height: isLeftColumn ? 22 : 18)
                    } else {
                        menuItemFallbackIcon(item: item, isLeftColumn: isLeftColumn, isHovered: isHovered)
                    }
                } else if item.title == "Run..." {
                    if let icon = XPAssetProvider.loadIcon(named: "cmd") {
                        Image(nsImage: icon)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: isLeftColumn ? 22 : 18, height: isLeftColumn ? 22 : 18)
                    } else {
                        menuItemFallbackIcon(item: item, isLeftColumn: isLeftColumn, isHovered: isHovered)
                    }
                } else if item.title == "Macromedia Flash Player" || item.title.contains("Flash") {
                    if let icon = XPAssetProvider.loadFlashIcon() {
                        Image(nsImage: icon)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: isLeftColumn ? 22 : 18, height: isLeftColumn ? 22 : 18)
                    } else {
                        menuItemFallbackIcon(item: item, isLeftColumn: isLeftColumn, isHovered: isHovered)
                    }
                } else {
                    menuItemFallbackIcon(item: item, isLeftColumn: isLeftColumn, isHovered: isHovered)
                }
                #else
                menuItemFallbackIcon(item: item, isLeftColumn: isLeftColumn, isHovered: isHovered)
                #endif

                VStack(alignment: .leading, spacing: 1) {
                    Text(item.title)
                        .font(.system(size: 12, weight: item.isBold ? .bold : .regular))
                        .foregroundColor(isHovered ? .white : (isLeftColumn ? .black : Color(red: 0.05, green: 0.15, blue: 0.40)))
                        .lineLimit(1)

                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.system(size: 10))
                            .foregroundColor(isHovered ? Color.white.opacity(0.85) : Color.gray)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, isLeftColumn ? 4 : 3)
            .background(
                isHovered ?
                    Color(red: 0.19, green: 0.42, blue: 0.77) : // Luna Selection Blue #316ac5
                    Color.clear
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            if hovering {
                hoveredItemID = item.id
            } else if hoveredItemID == item.id {
                hoveredItemID = nil
            }
        }
    }

    private func menuItemFallbackIcon(item: StartMenuItem, isLeftColumn: Bool, isHovered: Bool) -> some View {
        Image(systemName: item.iconName)
            .font(.system(size: isLeftColumn ? 18 : 15))
            .foregroundColor(
                isHovered ? .white :
                    (isLeftColumn ? Color(red: 0.15, green: 0.45, blue: 0.85) : Color(red: 0.05, green: 0.25, blue: 0.65))
            )
            .frame(width: 24, height: 24)
    }

    // MARK: - Footer
    private var footerView: some View {
        HStack(spacing: 12) {
            Spacer()

            // Log Off button
            Button(action: {
                onClose()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 0.98, green: 0.76, blue: 0.13))
                    Text("Log Off")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Turn Off Computer button
            Button(action: {
                onClose()
                if let onTurnOff = onTurnOff {
                    onTurnOff()
                } else {
                    #if os(macOS)
                    NSApplication.shared.terminate(nil)
                    #endif
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "power.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.93, green: 0.28, blue: 0.16))
                    Text("Turn Off Computer")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 10)
        }
        .frame(height: 42)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.35, blue: 0.82),
                    Color(red: 0.00, green: 0.22, blue: 0.65)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - All Programs Flyout
    private var allProgramsFlyout: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                // 1. Built-in XP Categories
                folderCategoryRow(
                    title: "Accessories",
                    iconName: "wrench.and.screwdriver.fill",
                    key: .accessories
                )
                folderCategoryRow(
                    title: "Games",
                    iconName: "gamecontroller.fill",
                    key: .games
                )

                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.85))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)

                // 2. Discovered macOS Categories
                ForEach(appDiscovery.categoriesWithApps) { category in
                    folderCategoryRow(
                        title: category.rawValue,
                        iconName: category.iconName,
                        key: .macCategory(category)
                    )
                }

                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.85))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)

                // 3. All Installed Mac Applications
                folderCategoryRow(
                    title: "All Mac Applications",
                    iconName: "square.grid.2x2.fill",
                    key: .allMacApps
                )
            }
            .frame(width: 215)
            .padding(.vertical, 4)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(Color(red: 0.00, green: 0.20, blue: 0.70), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 6, x: 3, y: 3)

            // Secondary Submenu Flyout (to the right)
            if let flyoutKey = activeFlyout {
                categorySubmenuFlyout(key: flyoutKey)
                    .offset(x: 213, y: -60)
            }
        }
    }

    private func folderCategoryRow(title: String, iconName: String, key: AllProgramsCategoryKey) -> some View {
        let isActive = (activeFlyout == key)

        return Button(action: {
            activeFlyout = (activeFlyout == key ? nil : key)
        }) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 13))
                    .foregroundColor(isActive ? .white : Color(red: 0.15, green: 0.45, blue: 0.85))
                    .frame(width: 20, height: 20)

                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(isActive ? .white : .black)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "play.fill")
                    .font(.system(size: 7))
                    .foregroundColor(isActive ? .white : Color.gray)
            }
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(isActive ? Color(red: 0.19, green: 0.42, blue: 0.77) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            if hovering {
                activeFlyout = key
            }
        }
    }

    @ViewBuilder
    private func categorySubmenuFlyout(key: AllProgramsCategoryKey) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    switch key {
                    case .accessories:
                        xpAppRow(title: "Notepad", icon: "doc.text.fill") {
                            windowManager.openWindow(appType: .notepad(fileURL: nil))
                        }
                        xpAppRow(title: "Command Prompt", icon: "terminal.fill") {
                            windowManager.openWindow(appType: .cmd)
                        }
                        xpAppRow(title: "Calculator", icon: "plus.forwardslash.minus") {
                            windowManager.openWindow(appType: .calculator)
                        }
                        xpAppRow(title: "Paint", icon: "paintbrush.fill") {
                            windowManager.openWindow(appType: .paint)
                        }
                        xpAppRow(title: "Windows Explorer", icon: "folder.fill") {
                            windowManager.openWindow(appType: .explorer(path: "/"))
                        }
                        xpAppRow(title: "Internet Explorer", icon: "globe") {
                            windowManager.openWindow(appType: .internetExplorer())
                        }
                        xpAppRow(title: "Windows Media Player", icon: "play.rectangle.fill") {
                            windowManager.openWindow(appType: .mediaPlayer())
                        }
                    case .games:
                        xpAppRow(title: "3D Pinball for Windows", icon: "circle.circle.fill") {
                            windowManager.openWindow(appType: .pinball)
                        }
                        xpAppRow(title: "Solitaire", icon: "suit.spade.fill") {
                            windowManager.openWindow(appType: .solitaire)
                        }
                        xpAppRow(title: "Minesweeper", icon: "flag.fill") {
                            windowManager.openWindow(appType: .minesweeper)
                        }
                        xpAppRow(title: "Macromedia Flash Player", icon: "flame.fill") {
                            windowManager.openWindow(appType: .flashPlayer())
                        }
                        ForEach(appDiscovery.apps(for: .games)) { app in
                            macAppRow(app: app)
                        }
                    case .macCategory(let category):
                        let apps = appDiscovery.apps(for: category)
                        if apps.isEmpty {
                            Text("No applications found")
                                .font(.system(size: 10))
                                .foregroundColor(Color.gray)
                                .padding(8)
                        } else {
                            ForEach(apps) { app in
                                macAppRow(app: app)
                            }
                        }
                    case .allMacApps:
                        ForEach(appDiscovery.allApps) { app in
                            macAppRow(app: app)
                        }
                    }
                }
            }
            .frame(maxHeight: 340)
        }
        .frame(width: 220)
        .padding(.vertical, 4)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .strokeBorder(Color(red: 0.00, green: 0.20, blue: 0.70), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 6, x: 3, y: 3)
    }

    private func xpAppRow(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            SoundManager.shared.play(.navigation)
            action()
            onClose()
        }) {
            HStack(spacing: 8) {
                #if os(macOS)
                if title == "Internet Explorer" {
                    IEIconView(size: 18)
                        .frame(width: 20, height: 20)
                } else if title == "Windows Explorer" {
                    if let iconImg = XPAssetProvider.loadFolderIcon() {
                        Image(nsImage: iconImg)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    } else {
                        fallbackXpAppIcon(icon: icon)
                    }
                } else if title == "Notepad" {
                    if let iconImg = XPAssetProvider.loadIcon(named: "notepad") {
                        Image(nsImage: iconImg)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    } else {
                        fallbackXpAppIcon(icon: icon)
                    }
                } else if title == "Paint" {
                    if let iconImg = XPAssetProvider.loadIcon(named: "paint") {
                        Image(nsImage: iconImg)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    } else {
                        fallbackXpAppIcon(icon: icon)
                    }
                } else if title == "Calculator" {
                    if let iconImg = XPAssetProvider.loadIcon(named: "calculator") {
                        Image(nsImage: iconImg)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    } else {
                        fallbackXpAppIcon(icon: icon)
                    }
                } else if title == "Command Prompt" {
                    if let iconImg = XPAssetProvider.loadIcon(named: "cmd") {
                        Image(nsImage: iconImg)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    } else {
                        fallbackXpAppIcon(icon: icon)
                    }
                } else if title == "Minesweeper" {
                    if let iconImg = XPAssetProvider.loadIcon(named: "minesweeper") {
                        Image(nsImage: iconImg)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    } else {
                        fallbackXpAppIcon(icon: icon)
                    }
                } else if title == "Macromedia Flash Player" || title.contains("Flash") {
                    if let iconImg = XPAssetProvider.loadFlashIcon() {
                        Image(nsImage: iconImg)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                    } else {
                        fallbackXpAppIcon(icon: icon)
                    }
                } else {
                    fallbackXpAppIcon(icon: icon)
                }
                #else
                fallbackXpAppIcon(icon: icon)
                #endif

                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.black)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 8)
            .frame(height: 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func fallbackXpAppIcon(icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 13))
            .foregroundColor(Color(red: 0.15, green: 0.45, blue: 0.85))
            .frame(width: 20, height: 20)
    }

    private func macAppRow(app: DiscoveredMacApp) -> some View {
        let isHovered = (hoveredAppID == app.id)

        return Button(action: {
            SoundManager.shared.play(.navigation)
            appDiscovery.launchApp(app)
            onClose()
        }) {
            HStack(spacing: 8) {
                #if os(macOS)
                if FileManager.default.fileExists(atPath: app.url.path) {
                    let nsImage = ItemIconCache.shared.icon(forPath: app.url.path)
                    Image(nsImage: nsImage)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                } else {
                    Image(systemName: app.iconName)
                        .font(.system(size: 13))
                        .foregroundColor(isHovered ? .white : Color(red: 0.15, green: 0.45, blue: 0.85))
                        .frame(width: 18, height: 18)
                }
                #else
                Image(systemName: app.iconName)
                    .font(.system(size: 13))
                    .foregroundColor(isHovered ? .white : Color(red: 0.15, green: 0.45, blue: 0.85))
                    .frame(width: 18, height: 18)
                #endif

                Text(app.name)
                    .font(.system(size: 11))
                    .foregroundColor(isHovered ? .white : .black)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(isHovered ? Color(red: 0.19, green: 0.42, blue: 0.77) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            if hovering {
                hoveredAppID = app.id
            } else if hoveredAppID == app.id {
                hoveredAppID = nil
            }
        }
    }
}
