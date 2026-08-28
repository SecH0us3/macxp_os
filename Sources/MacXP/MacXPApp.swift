import SwiftUI

@main
struct MacXPApp: App {
    @StateObject private var windowManager = WindowManager()

    var body: some Scene {
        WindowGroup {
            DesktopView(windowManager: windowManager)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
