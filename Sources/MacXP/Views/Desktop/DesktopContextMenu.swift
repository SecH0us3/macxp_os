import SwiftUI

public struct DesktopContextMenuModifier: ViewModifier {
    @ObservedObject public var desktopManager: DesktopManager
    public var onArrange: (ArrangeOption) -> Void
    public var onRefresh: () -> Void
    public var onNewFolder: () -> Void
    public var onNewTextDocument: () -> Void
    public var onProperties: () -> Void

    public init(
        desktopManager: DesktopManager,
        onArrange: @escaping (ArrangeOption) -> Void,
        onRefresh: @escaping () -> Void,
        onNewFolder: @escaping () -> Void,
        onNewTextDocument: @escaping () -> Void,
        onProperties: @escaping () -> Void
    ) {
        self.desktopManager = desktopManager
        self.onArrange = onArrange
        self.onRefresh = onRefresh
        self.onNewFolder = onNewFolder
        self.onNewTextDocument = onNewTextDocument
        self.onProperties = onProperties
    }

    public func body(content: Content) -> some View {
        content
            .contextMenu {
                Menu("Arrange Icons By") {
                    Button("Name") { onArrange(.name) }
                    Button("Size") { onArrange(.size) }
                    Button("Type") { onArrange(.type) }
                    Button("Modified") { onArrange(.modified) }
                }

                Button("Refresh") {
                    onRefresh()
                }

                Divider()

                Menu("New") {
                    Button("Folder") {
                        onNewFolder()
                    }
                    Button("Text Document") {
                        onNewTextDocument()
                    }
                }

                Divider()

                Button("Properties") {
                    onProperties()
                }
            }
    }
}

extension View {
    public func desktopContextMenu(
        desktopManager: DesktopManager,
        onArrange: @escaping (ArrangeOption) -> Void,
        onRefresh: @escaping () -> Void,
        onNewFolder: @escaping () -> Void,
        onNewTextDocument: @escaping () -> Void,
        onProperties: @escaping () -> Void
    ) -> some View {
        self.modifier(
            DesktopContextMenuModifier(
                desktopManager: desktopManager,
                onArrange: onArrange,
                onRefresh: onRefresh,
                onNewFolder: onNewFolder,
                onNewTextDocument: onNewTextDocument,
                onProperties: onProperties
            )
        )
    }
}
