import XCTest
@testable import MacXP

final class MacAppDiscoveryTests: XCTestCase {

    func testCategorizationByPlistType() {
        let service = MacAppDiscoveryService()
        
        XCTAssertEqual(service.categorize(name: "CustomApp", bundleId: "com.custom", lsCategory: "public.app-category.developer-tools"), .developer)
        XCTAssertEqual(service.categorize(name: "CustomApp", bundleId: "com.custom", lsCategory: "public.app-category.social-networking"), .internet)
        XCTAssertEqual(service.categorize(name: "CustomApp", bundleId: "com.custom", lsCategory: "public.app-category.productivity"), .productivity)
        XCTAssertEqual(service.categorize(name: "CustomApp", bundleId: "com.custom", lsCategory: "public.app-category.music"), .media)
        XCTAssertEqual(service.categorize(name: "CustomApp", bundleId: "com.custom", lsCategory: "public.app-category.graphics-design"), .graphics)
        XCTAssertEqual(service.categorize(name: "CustomApp", bundleId: "com.custom", lsCategory: "public.app-category.games"), .games)
        XCTAssertEqual(service.categorize(name: "CustomApp", bundleId: "com.custom", lsCategory: "public.app-category.utilities"), .utilities)
    }

    func testCategorizationByNameAndBundleIDHeuristics() {
        let service = MacAppDiscoveryService()

        // Internet
        XCTAssertEqual(service.categorize(name: "Google Chrome", bundleId: "com.google.Chrome", lsCategory: nil), .internet)
        XCTAssertEqual(service.categorize(name: "Telegram", bundleId: "ru.keepcoder.Telegram", lsCategory: nil), .internet)
        XCTAssertEqual(service.categorize(name: "Safari", bundleId: "com.apple.Safari", lsCategory: nil), .internet)
        XCTAssertEqual(service.categorize(name: "Slack", bundleId: "com.tinyspeck.slackmacgap", lsCategory: nil), .internet)

        // Developer
        XCTAssertEqual(service.categorize(name: "Visual Studio Code", bundleId: "com.microsoft.VSCode", lsCategory: nil), .developer)
        XCTAssertEqual(service.categorize(name: "Xcode", bundleId: "com.apple.dt.Xcode", lsCategory: nil), .developer)
        XCTAssertEqual(service.categorize(name: "Terminal", bundleId: "com.apple.Terminal", lsCategory: nil), .developer)
        XCTAssertEqual(service.categorize(name: "iTerm2", bundleId: "com.googlecode.iterm2", lsCategory: nil), .developer)

        // Productivity
        XCTAssertEqual(service.categorize(name: "Notion", bundleId: "notion.id", lsCategory: nil), .productivity)
        XCTAssertEqual(service.categorize(name: "Pages", bundleId: "com.apple.Pages", lsCategory: nil), .productivity)
        XCTAssertEqual(service.categorize(name: "Microsoft Word", bundleId: "com.microsoft.Word", lsCategory: nil), .productivity)

        // Media
        XCTAssertEqual(service.categorize(name: "Spotify", bundleId: "com.spotify.client", lsCategory: nil), .media)
        XCTAssertEqual(service.categorize(name: "Music", bundleId: "com.apple.Music", lsCategory: nil), .media)
        XCTAssertEqual(service.categorize(name: "VLC", bundleId: "org.videolan.vlc", lsCategory: nil), .media)

        // Graphics
        XCTAssertEqual(service.categorize(name: "Figma", bundleId: "com.figma.Desktop", lsCategory: nil), .graphics)
        XCTAssertEqual(service.categorize(name: "Adobe Photoshop 2024", bundleId: "com.adobe.photoshop", lsCategory: nil), .graphics)
        XCTAssertEqual(service.categorize(name: "Blender", bundleId: "org.blenderfoundation.blender", lsCategory: nil), .graphics)

        // Games
        XCTAssertEqual(service.categorize(name: "Steam", bundleId: "com.valvesoftware.steam", lsCategory: nil), .games)
        XCTAssertEqual(service.categorize(name: "Chess", bundleId: "com.apple.Chess", lsCategory: nil), .games)

        // System
        XCTAssertEqual(service.categorize(name: "System Settings", bundleId: "com.apple.systempreferences", lsCategory: nil), .system)
        XCTAssertEqual(service.categorize(name: "App Store", bundleId: "com.apple.AppStore", lsCategory: nil), .system)
    }

    func testAppDiscoveryPopulatesCategories() {
        let service = MacAppDiscoveryService()
        service.discoverInstalledApps()

        XCTAssertFalse(service.allApps.isEmpty, "Should discover installed macOS apps from /Applications or /System/Applications")
        XCTAssertFalse(service.categoriesWithApps.isEmpty, "Should categorize discovered apps into groups")
        
        let internetApps = service.apps(for: .internet)
        XCTAssertNotNil(internetApps)
    }
}
