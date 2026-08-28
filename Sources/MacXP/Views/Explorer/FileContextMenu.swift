import SwiftUI

public struct FileContextMenuModifier: ViewModifier {
    public let item: FileItem
    public var onOpen: () -> Void
    public var onExplore: () -> Void
    public var onOpenWithNotepad: () -> Void
    public var onOpenWithDefaultApp: () -> Void
    public var onDelete: () -> Void
    public var onRename: () -> Void
    public var onProperties: () -> Void

    public func body(content: Content) -> some View {
        content.contextMenu {
            Button(action: onOpen) {
                HStack {
                    Text("Open")
                        .fontWeight(.bold)
                    Image(systemName: "arrow.up.right.square")
                }
            }

            if item.isDirectory {
                Button(action: onExplore) {
                    HStack {
                        Text("Explore")
                        Image(systemName: "folder")
                    }
                }
            }

            Menu("Open With") {
                Button(action: onOpenWithNotepad) {
                    HStack {
                        Text("Notepad")
                        Image(systemName: "doc.text")
                    }
                }
                Button(action: onOpenWithDefaultApp) {
                    HStack {
                        Text("Default Application")
                        Image(systemName: "arrow.up.forward.app")
                    }
                }
            }

            Divider()

            Button(action: onDelete) {
                HStack {
                    Text("Delete")
                    Image(systemName: "trash")
                }
            }

            Button(action: onRename) {
                HStack {
                    Text("Rename")
                    Image(systemName: "pencil")
                }
            }

            Divider()

            Button(action: onProperties) {
                HStack {
                    Text("Properties")
                    Image(systemName: "info.circle")
                }
            }
        }
    }
}

public struct ExplorerBackgroundContextMenuModifier: ViewModifier {
    public var currentViewMode: ExplorerViewMode
    public var onSelectViewMode: (ExplorerViewMode) -> Void
    public var onArrange: (ExplorerSortColumn) -> Void
    public var onRefresh: () -> Void
    public var onNewFolder: () -> Void
    public var onNewTextDocument: () -> Void
    public var onProperties: () -> Void

    public func body(content: Content) -> some View {
        content.contextMenu {
            Menu("View") {
                ForEach(ExplorerViewMode.allCases) { mode in
                    Button(action: {
                        onSelectViewMode(mode)
                    }) {
                        HStack {
                            if currentViewMode == mode {
                                Image(systemName: "checkmark")
                            }
                            Text(mode.rawValue)
                        }
                    }
                }
            }

            Menu("Arrange Icons By") {
                Button("Name") { onArrange(.name) }
                Button("Size") { onArrange(.size) }
                Button("Type") { onArrange(.type) }
                Button("Modified") { onArrange(.dateModified) }
            }

            Button(action: onRefresh) {
                HStack {
                    Text("Refresh")
                    Image(systemName: "arrow.clockwise")
                }
            }

            Divider()

            Menu("New") {
                Button(action: onNewFolder) {
                    HStack {
                        Text("Folder")
                        Image(systemName: "folder.badge.plus")
                    }
                }
                Button(action: onNewTextDocument) {
                    HStack {
                        Text("Text Document")
                        Image(systemName: "doc.text")
                    }
                }
            }

            Divider()

            Button(action: onProperties) {
                HStack {
                    Text("Properties")
                    Image(systemName: "info.circle")
                }
            }
        }
    }
}

extension View {
    public func fileContextMenu(
        item: FileItem,
        onOpen: @escaping () -> Void,
        onExplore: @escaping () -> Void,
        onOpenWithNotepad: @escaping () -> Void,
        onOpenWithDefaultApp: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onRename: @escaping () -> Void,
        onProperties: @escaping () -> Void
    ) -> some View {
        self.modifier(
            FileContextMenuModifier(
                item: item,
                onOpen: onOpen,
                onExplore: onExplore,
                onOpenWithNotepad: onOpenWithNotepad,
                onOpenWithDefaultApp: onOpenWithDefaultApp,
                onDelete: onDelete,
                onRename: onRename,
                onProperties: onProperties
            )
        )
    }

    public func explorerBackgroundContextMenu(
        currentViewMode: ExplorerViewMode,
        onSelectViewMode: @escaping (ExplorerViewMode) -> Void,
        onArrange: @escaping (ExplorerSortColumn) -> Void,
        onRefresh: @escaping () -> Void,
        onNewFolder: @escaping () -> Void,
        onNewTextDocument: @escaping () -> Void,
        onProperties: @escaping () -> Void
    ) -> some View {
        self.modifier(
            ExplorerBackgroundContextMenuModifier(
                currentViewMode: currentViewMode,
                onSelectViewMode: onSelectViewMode,
                onArrange: onArrange,
                onRefresh: onRefresh,
                onNewFolder: onNewFolder,
                onNewTextDocument: onNewTextDocument,
                onProperties: onProperties
            )
        )
    }
}
