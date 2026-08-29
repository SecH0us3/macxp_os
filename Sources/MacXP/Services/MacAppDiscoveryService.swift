import Foundation
#if os(macOS)
import AppKit
#endif

public enum MacAppCategory: String, CaseIterable, Identifiable, Comparable {
    case internet = "Internet & Communication"
    case developer = "Developer Tools"
    case productivity = "Productivity & Office"
    case media = "Media & Entertainment"
    case graphics = "Graphics & Design"
    case utilities = "Accessories & Utilities"
    case games = "Games"
    case system = "System Tools"
    case other = "Other Applications"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .internet: return "globe"
        case .developer: return "chevron.left.forwardslash.chevron.right"
        case .productivity: return "doc.text.fill"
        case .media: return "play.rectangle.fill"
        case .graphics: return "paintbrush.fill"
        case .utilities: return "wrench.and.screwdriver.fill"
        case .games: return "gamecontroller.fill"
        case .system: return "gearshape.2.fill"
        case .other: return "app.fill"
        }
    }

    public static func < (lhs: MacAppCategory, rhs: MacAppCategory) -> Bool {
        let order: [MacAppCategory] = [
            .internet,
            .developer,
            .productivity,
            .media,
            .graphics,
            .utilities,
            .games,
            .system,
            .other
        ]
        let lIdx = order.firstIndex(of: lhs) ?? 99
        let rIdx = order.firstIndex(of: rhs) ?? 99
        return lIdx < rIdx
    }
}

public struct DiscoveredMacApp: Identifiable, Equatable {
    public let id: UUID
    public let name: String
    public let url: URL
    public let bundleIdentifier: String?
    public let category: MacAppCategory
    public let iconName: String

    public init(
        id: UUID = UUID(),
        name: String,
        url: URL,
        bundleIdentifier: String? = nil,
        category: MacAppCategory,
        iconName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.bundleIdentifier = bundleIdentifier
        self.category = category
        self.iconName = iconName ?? category.iconName
    }
}

public class MacAppDiscoveryService: ObservableObject {
    public static let shared = MacAppDiscoveryService()

    @Published public var allApps: [DiscoveredMacApp] = []
    @Published public var categorizedApps: [MacAppCategory: [DiscoveredMacApp]] = [:]

    public var categoriesWithApps: [MacAppCategory] {
        MacAppCategory.allCases.filter { !(categorizedApps[$0]?.isEmpty ?? true) }
    }

    public init() {
        discoverInstalledApps()
    }

    public func apps(for category: MacAppCategory) -> [DiscoveredMacApp] {
        categorizedApps[category] ?? []
    }

    public func discoverInstalledApps() {
        var foundApps: [DiscoveredMacApp] = []
        var seenNames = Set<String>()

        let directoriesToScan: [URL] = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            URL(fileURLWithPath: "/System/Applications/Utilities"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]

        let fm = FileManager.default

        for dir in directoriesToScan {
            guard let contents = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
                continue
            }

            for item in contents {
                if item.pathExtension == "app" {
                    let appName = item.deletingPathExtension().lastPathComponent
                    if seenNames.contains(appName) || appName.hasPrefix(".") {
                        continue
                    }
                    seenNames.insert(appName)

                    let (bundleId, lsCategory) = extractAppMetadata(appURL: item)
                    let category = categorize(name: appName, bundleId: bundleId, lsCategory: lsCategory)
                    let iconName = iconForApp(name: appName, category: category)

                    foundApps.append(
                        DiscoveredMacApp(
                            name: appName,
                            url: item,
                            bundleIdentifier: bundleId,
                            category: category,
                            iconName: iconName
                        )
                    )
                }
            }
        }

        // Sort alphabetically
        foundApps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        // Group by category
        var grouped: [MacAppCategory: [DiscoveredMacApp]] = [:]
        for app in foundApps {
            grouped[app.category, default: []].append(app)
        }

        if Thread.isMainThread {
            self.allApps = foundApps
            self.categorizedApps = grouped
        } else {
            DispatchQueue.main.sync {
                self.allApps = foundApps
                self.categorizedApps = grouped
            }
        }
    }

    private func extractAppMetadata(appURL: URL) -> (bundleId: String?, lsCategory: String?) {
        let plistURL = appURL.appendingPathComponent("Contents/Info.plist")
        guard let data = try? Data(contentsOf: plistURL),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return (nil, nil)
        }

        let bundleId = dict["CFBundleIdentifier"] as? String
        let lsCategory = dict["LSApplicationCategoryType"] as? String
        return (bundleId, lsCategory)
    }

    public func categorize(name: String, bundleId: String?, lsCategory: String?) -> MacAppCategory {
        let lowerName = name.lowercased()
        let lowerId = (bundleId ?? "").lowercased()

        // 1. Exact / Special Known macOS & 3rd-Party Names
        if lowerName.contains("chrome") || lowerName.contains("safari") || lowerName.contains("firefox") ||
           lowerName.contains("telegram") || lowerName.contains("slack") || lowerName.contains("discord") ||
           lowerName.contains("whatsapp") || lowerName.contains("mail") || lowerName.contains("messages") ||
           lowerName.contains("zoom") || lowerName.contains("teams") || lowerName.contains("skype") ||
           lowerName.contains("edge") || lowerName.contains("brave") || lowerName.contains("arc") ||
           lowerName.contains("opera") || lowerName.contains("facetime") || lowerName.contains("thunderbird") {
            return .internet
        }

        if lowerName.contains("xcode") || lowerName.contains("code") || lowerName.contains("terminal") ||
           lowerName.contains("iterm") || lowerName.contains("sublime") || lowerName.contains("pycharm") ||
           lowerName.contains("webstorm") || lowerName.contains("intellij") || lowerName.contains("docker") ||
           lowerName.contains("postman") || lowerName.contains("cursor") || lowerName.contains("warp") ||
           lowerName.contains("ghostty") || lowerName.contains("sourcetree") || lowerName.contains("fork") ||
           lowerName.contains("git") || lowerName.contains("developer") || lowerName.contains("wireshark") {
            return .developer
        }

        if lowerName.contains("pages") || lowerName.contains("numbers") || lowerName.contains("keynote") ||
           lowerName.contains("notion") || lowerName.contains("obsidian") || lowerName.contains("word") ||
           lowerName.contains("excel") || lowerName.contains("powerpoint") || lowerName.contains("notes") ||
           lowerName.contains("reminders") || lowerName.contains("calendar") || lowerName.contains("bear") ||
           lowerName.contains("craft") || lowerName.contains("todoist") || lowerName.contains("things") ||
           lowerName.contains("office") || lowerName.contains("pdf") || lowerName.contains("acrobat") {
            return .productivity
        }

        if lowerName.contains("music") || lowerName.contains("spotify") || lowerName.contains("podcasts") ||
           lowerName.contains("vlc") || lowerName.contains("quicktime") || lowerName.contains("final cut") ||
           lowerName.contains("logic") || lowerName.contains("garageband") || lowerName.contains("iina") ||
           lowerName.contains("audacity") || lowerName.contains("tv") || lowerName.contains("sound") ||
           lowerName.contains("player") || lowerName.contains("video") || lowerName.contains("screenflow") {
            return .media
        }

        if lowerName.contains("paint") || lowerName.contains("photoshop") || lowerName.contains("figma") ||
           lowerName.contains("illustrator") || lowerName.contains("blender") || lowerName.contains("pixelmator") ||
           lowerName.contains("affinity") || lowerName.contains("canva") || lowerName.contains("sketch") ||
           lowerName.contains("gimp") || lowerName.contains("inkscape") || lowerName.contains("lightroom") {
            return .graphics
        }

        if lowerName.contains("chess") || lowerName.contains("steam") || lowerName.contains("epic") ||
           lowerName.contains("game") || lowerName.contains("minecraft") || lowerName.contains("roblox") ||
           lowerName.contains("gog") || lowerName.contains("arcade") {
            return .games
        }

        if lowerName.contains("settings") || lowerName.contains("preferences") || lowerName.contains("app store") ||
           lowerName.contains("font book") || lowerName.contains("migration") || lowerName.contains("time machine") ||
           lowerName.contains("installer") || lowerName.contains("system") {
            return .system
        }

        if lowerName.contains("activity monitor") || lowerName.contains("disk utility") || lowerName.contains("console") ||
           lowerName.contains("keychain") || lowerName.contains("archive") || lowerName.contains("preview") ||
           lowerName.contains("textedit") || lowerName.contains("finder") || lowerName.contains("calculator") ||
           lowerName.contains("utility") || lowerName.contains("cleaner") || lowerName.contains("screenshot") {
            return .utilities
        }

        // 2. LSApplicationCategoryType Plist checking
        if let cat = lsCategory?.lowercased() {
            if cat.contains("developer") { return .developer }
            if cat.contains("social") || cat.contains("news") || cat.contains("networking") { return .internet }
            if cat.contains("productivity") || cat.contains("business") || cat.contains("finance") || cat.contains("education") { return .productivity }
            if cat.contains("music") || cat.contains("video") || cat.contains("entertainment") || cat.contains("audio") { return .media }
            if cat.contains("graphics") || cat.contains("photography") || cat.contains("design") { return .graphics }
            if cat.contains("game") { return .games }
            if cat.contains("utilities") { return .utilities }
        }

        // 3. Bundle identifier matching
        if lowerId.contains("developer") || lowerId.contains("xcode") || lowerId.contains("terminal") { return .developer }
        if lowerId.contains("browser") || lowerId.contains("mail") || lowerId.contains("chat") { return .internet }
        if lowerId.contains("player") || lowerId.contains("music") { return .media }

        return .other
    }

    private func iconForApp(name: String, category: MacAppCategory) -> String {
        let lower = name.lowercased()
        if lower.contains("safari") || lower.contains("chrome") || lower.contains("firefox") { return "globe" }
        if lower.contains("telegram") || lower.contains("messages") || lower.contains("chat") { return "bubble.left.and.bubble.right.fill" }
        if lower.contains("mail") { return "envelope.fill" }
        if lower.contains("xcode") || lower.contains("code") { return "chevron.left.forwardslash.chevron.right" }
        if lower.contains("terminal") || lower.contains("iterm") { return "terminal.fill" }
        if lower.contains("music") || lower.contains("spotify") { return "music.note" }
        if lower.contains("video") || lower.contains("vlc") || lower.contains("quicktime") { return "play.rectangle.fill" }
        if lower.contains("figma") || lower.contains("photoshop") { return "paintbrush.fill" }
        if lower.contains("notes") || lower.contains("pages") || lower.contains("word") { return "doc.text.fill" }
        if lower.contains("calendar") { return "calendar" }
        if lower.contains("reminders") { return "list.bullet" }
        if lower.contains("settings") { return "gearshape.fill" }
        if lower.contains("app store") { return "bag.fill" }
        if lower.contains("steam") || lower.contains("game") { return "gamecontroller.fill" }
        return category.iconName
    }

    public func launchApp(_ app: DiscoveredMacApp) {
        #if os(macOS)
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: app.url, configuration: config, completionHandler: nil)
        #endif
    }
}
