import SwiftUI
#if os(macOS)
import AppKit
#endif

public class NotepadViewModel: ObservableObject {
    @Published public var text: String = "" {
        didSet {
            if text != oldValue && !isInternalUpdate {
                isDirty = true
                recalculateCursor()
            }
        }
    }
    @Published public var isDirty: Bool = false
    @Published public var fileURL: URL? = nil
    @Published public var isWordWrap: Bool = true
    @Published public var isStatusBarVisible: Bool = true
    @Published public var lineAndColumn: String = "Ln 1, Col 1"
    
    private var isInternalUpdate: Bool = false
    
    public init(fileURL: URL? = nil) {
        if let url = fileURL {
            _ = load(from: url)
        }
    }
    
    public func newDocument() {
        isInternalUpdate = true
        text = ""
        fileURL = nil
        isDirty = false
        lineAndColumn = "Ln 1, Col 1"
        isInternalUpdate = false
    }
    
    public func load(from url: URL) -> Bool {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            isInternalUpdate = true
            text = content
            fileURL = url
            isDirty = false
            lineAndColumn = "Ln 1, Col 1"
            isInternalUpdate = false
            return true
        } catch {
            return false
        }
    }
    
    public func save(to url: URL) -> Bool {
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            fileURL = url
            isDirty = false
            return true
        } catch {
            return false
        }
    }
    
    public func updateCursorPosition(charIndex: Int) {
        let safeIndex = max(0, min(charIndex, text.count))
        let prefix = text.prefix(safeIndex)
        let lines = prefix.split(separator: "\n", omittingEmptySubsequences: false)
        let lineNum = lines.count
        let colNum = (lines.last?.count ?? 0) + 1
        lineAndColumn = "Ln \(lineNum), Col \(colNum)"
    }
    
    public func insertDateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a M/d/yyyy"
        let dateString = formatter.string(from: Date())
        
        if text.isEmpty {
            text = dateString
        } else {
            text += " " + dateString
        }
        isDirty = true
    }
    
    private func recalculateCursor() {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        let lineNum = lines.count
        let colNum = (lines.last?.count ?? 0) + 1
        lineAndColumn = "Ln \(lineNum), Col \(colNum)"
    }
}

public struct NotepadView: View {
    @ObservedObject public var windowManager: WindowManager
    public var window: XPWindowInstance
    
    @StateObject private var viewModel: NotepadViewModel
    @State private var openMenu: String? = nil
    @State private var showAboutModal: Bool = false
    
    public init(fileURL: URL? = nil, windowManager: WindowManager, window: XPWindowInstance) {
        self.windowManager = windowManager
        self.window = window
        _viewModel = StateObject(wrappedValue: NotepadViewModel(fileURL: fileURL))
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 1. Classic XP Menu Bar
                menuBar
                
                Divider()
                
                // 2. Editor Body
                TextEditor(text: $viewModel.text)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(4)
                    .background(Color.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // 3. Status Bar
                if viewModel.isStatusBarVisible {
                    statusBar
                }
            }
            .background(Color(red: 0.94, green: 0.94, blue: 0.94))
            
            // Dropdown Menus Overlay
            if let activeMenu = openMenu {
                dropdownMenuView(for: activeMenu)
            }
            
            // About Modal
            if showAboutModal {
                aboutModalView
            }
        }
        .onAppear {
            if let url = viewModel.fileURL {
                windowManager.updateWindowTitle(id: window.id, title: "\(url.lastPathComponent) - Notepad")
            }
        }
    }
    
    // MARK: - Menu Bar
    private var menuBar: some View {
        HStack(spacing: 0) {
            menuBarButton(title: "File")
            menuBarButton(title: "Edit")
            menuBarButton(title: "Format")
            menuBarButton(title: "View")
            menuBarButton(title: "Help")
            Spacer()
        }
        .frame(height: 22)
        .background(Color(red: 0.94, green: 0.94, blue: 0.94))
    }
    
    private func menuBarButton(title: String) -> some View {
        let isOpen = (openMenu == title)
        return Button(action: {
            if openMenu == title {
                openMenu = nil
            } else {
                openMenu = title
            }
        }) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.black)
                .padding(.horizontal, 6)
                .frame(height: 20)
                .background(isOpen ? Color(red: 0.19, green: 0.42, blue: 0.77).opacity(0.2) : Color.clear)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Dropdown Menus
    @ViewBuilder
    private func dropdownMenuView(for menu: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            switch menu {
            case "File":
                menuItem(title: "New", shortcut: "Ctrl+N") {
                    viewModel.newDocument()
                    windowManager.updateWindowTitle(id: window.id, title: "Untitled - Notepad")
                }
                menuItem(title: "Open...", shortcut: "Ctrl+O") {
                    handleOpenFile()
                }
                menuItem(title: "Save", shortcut: "Ctrl+S") {
                    handleSaveFile()
                }
                menuItem(title: "Save As...") {
                    handleSaveAsFile()
                }
                menuDivider
                menuItem(title: "Exit") {
                    windowManager.closeWindow(id: window.id)
                }
                
            case "Edit":
                menuItem(title: "Select All", shortcut: "Ctrl+A") {}
                menuItem(title: "Time/Date", shortcut: "F5") {
                    viewModel.insertDateTime()
                }
                
            case "Format":
                menuItemWithCheck(title: "Word Wrap", isChecked: viewModel.isWordWrap) {
                    viewModel.isWordWrap.toggle()
                }
                
            case "View":
                menuItemWithCheck(title: "Status Bar", isChecked: viewModel.isStatusBarVisible) {
                    viewModel.isStatusBarVisible.toggle()
                }
                
            case "Help":
                menuItem(title: "About Notepad") {
                    showAboutModal = true
                }
                
            default:
                EmptyView()
            }
        }
        .frame(width: 160)
        .padding(.vertical, 2)
        .background(Color(red: 0.96, green: 0.96, blue: 0.96))
        .border(Color(red: 0.55, green: 0.55, blue: 0.55), width: 1)
        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 2, y: 2)
        .offset(x: menuOffset(for: menu), y: 22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    private func menuOffset(for menu: String) -> CGFloat {
        switch menu {
        case "File": return 4
        case "Edit": return 32
        case "Format": return 64
        case "View": return 112
        case "Help": return 148
        default: return 0
        }
    }
    
    private func menuItem(title: String, shortcut: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: {
            openMenu = nil
            action()
        }) {
            HStack {
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.black)
                Spacer()
                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(XPMenuItemButtonStyle())
    }
    
    private func menuItemWithCheck(title: String, isChecked: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            openMenu = nil
            action()
        }) {
            HStack(spacing: 4) {
                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 14)
                } else {
                    Spacer().frame(width: 14)
                }
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(.black)
                Spacer()
            }
            .padding(.horizontal, 6)
            .frame(height: 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(XPMenuItemButtonStyle())
    }
    
    private var menuDivider: some View {
        Divider()
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
    }
    
    // MARK: - Status Bar
    private var statusBar: some View {
        HStack(spacing: 0) {
            Spacer()
            
            // Ln/Col Panel
            Text(viewModel.lineAndColumn)
                .font(.system(size: 11))
                .foregroundColor(.black)
                .frame(width: 110, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .overlay(
                    Rectangle()
                        .strokeBorder(Color(red: 0.65, green: 0.65, blue: 0.65), lineWidth: 1)
                )
            
            // Encoding Panel
            Text("UTF-8")
                .font(.system(size: 11))
                .foregroundColor(.black)
                .frame(width: 90, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .overlay(
                    Rectangle()
                        .strokeBorder(Color(red: 0.65, green: 0.65, blue: 0.65), lineWidth: 1)
                )
        }
        .frame(height: 22)
        .padding(.horizontal, 4)
        .background(Color(red: 0.94, green: 0.94, blue: 0.94))
        .border(Color(red: 0.80, green: 0.80, blue: 0.80), width: 1)
    }
    
    // MARK: - About Modal
    private var aboutModalView: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .foregroundColor(Color(red: 0.15, green: 0.45, blue: 0.85))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Microsoft Windows XP")
                            .font(.system(size: 14, weight: .bold))
                        Text("Notepad")
                            .font(.system(size: 12, weight: .medium))
                        Text("Version 5.1 (Build 2600.xpsp_sp3_gdr)")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        Text("Copyright © 1985-2001 Microsoft Corporation")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                    }
                }
                
                Divider()
                
                Text("This product is licensed under the Windows XP terms to:\nRegistered MacXP User")
                    .font(.system(size: 11))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: {
                    showAboutModal = false
                }) {
                    Text("OK")
                        .font(.system(size: 11))
                        .frame(width: 70, height: 22)
                        .background(Color(red: 0.94, green: 0.94, blue: 0.94))
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .strokeBorder(Color(red: 0.0, green: 0.2, blue: 0.6), lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(16)
            .frame(width: 320)
            .background(Color(red: 0.96, green: 0.96, blue: 0.96))
            .border(Color(red: 0.0, green: 0.33, blue: 0.92), width: 2)
            .shadow(radius: 8)
        }
    }
    
    // MARK: - File Operations
    private func handleOpenFile() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            if viewModel.load(from: url) {
                windowManager.updateWindowTitle(id: window.id, title: "\(url.lastPathComponent) - Notepad")
            }
        }
        #endif
    }
    
    private func handleSaveFile() {
        if let url = viewModel.fileURL {
            _ = viewModel.save(to: url)
        } else {
            handleSaveAsFile()
        }
    }
    
    private func handleSaveAsFile() {
        #if os(macOS)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "Untitled.txt"
        if panel.runModal() == .OK, let url = panel.url {
            if viewModel.save(to: url) {
                windowManager.updateWindowTitle(id: window.id, title: "\(url.lastPathComponent) - Notepad")
            }
        }
        #endif
    }
}

private struct XPMenuItemButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color(red: 0.19, green: 0.42, blue: 0.77) : Color.clear)
            .foregroundColor(configuration.isPressed ? .white : .black)
    }
}
