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
            StartMenuItem(title: "Paint", iconName: "paintbrush.fill", action: { wm in wm.openWindow(appType: .paint) }),
            StartMenuItem(title: "Windows Explorer", iconName: "folder.fill", action: { wm in wm.openWindow(appType: .explorer(path: "/")) }),
            StartMenuItem(title: "Control Panel", iconName: "gearshape.fill", action: { wm in wm.openWindow(appType: .controlPanel) }),
            StartMenuItem(title: "System Properties", iconName: "info.circle.fill", action: { wm in wm.openWindow(appType: .systemProperties) })
        ]
    }
}

public struct StartMenuView: View {
    @ObservedObject public var windowManager: WindowManager
    @ObservedObject public var model: StartMenuModel
    public var onClose: () -> Void
    public var onTurnOff: (() -> Void)?

    @State private var hoveredItemID: UUID? = nil
    @State private var isAllProgramsOpen: Bool = false

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
                Image(systemName: item.iconName)
                    .font(.system(size: isLeftColumn ? 18 : 15))
                    .foregroundColor(
                        isHovered ? .white :
                            (isLeftColumn ? Color(red: 0.15, green: 0.45, blue: 0.85) : Color(red: 0.05, green: 0.25, blue: 0.65))
                    )
                    .frame(width: 24, height: 24)

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
        VStack(alignment: .leading, spacing: 0) {
            ForEach(model.allPrograms) { program in
                menuItemRow(item: program, isLeftColumn: true)
            }
        }
        .frame(width: 180)
        .padding(.vertical, 4)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .strokeBorder(Color(red: 0.00, green: 0.20, blue: 0.70), lineWidth: 1)
        )
    }
}
