import SwiftUI

@main
struct MacXPApp: App {
    var body: some Scene {
        WindowGroup {
            Text("MacXP Initialized")
                .frame(width: 800, height: 600)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
