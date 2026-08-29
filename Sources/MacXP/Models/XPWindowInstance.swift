import Foundation
import CoreGraphics

public enum XPAppType: Equatable, Hashable {
    case explorer(path: String)
    case notepad(fileURL: URL? = nil)
    case cmd
    case calculator
    case minesweeper
    case paint
    case controlPanel
    case systemProperties
    case displayProperties
    case internetExplorer(url: String = "https://www.google.com")
    case runDialog
    
    public var defaultTitle: String {
        switch self {
        case .explorer(let path):
            if path.isEmpty || path == "/" {
                return "My Computer"
            }
            let name = URL(fileURLWithPath: path).lastPathComponent
            return name.isEmpty ? "My Computer" : name
        case .notepad(let url):
            if let url = url {
                return "\(url.lastPathComponent) - Notepad"
            }
            return "Untitled - Notepad"
        case .cmd:
            return "Command Prompt"
        case .calculator:
            return "Calculator"
        case .minesweeper:
            return "Minesweeper"
        case .paint:
            return "untitled - Paint"
        case .controlPanel:
            return "Control Panel"
        case .systemProperties:
            return "System Properties"
        case .displayProperties:
            return "Display Properties"
        case .internetExplorer:
            return "Internet Explorer"
        case .runDialog:
            return "Run"
        }
    }
    
    public var defaultIcon: String {
        switch self {
        case .explorer:
            return "folder"
        case .notepad:
            return "doc.text"
        case .cmd:
            return "terminal"
        case .calculator:
            return "plus.forwardslash.minus"
        case .minesweeper:
            return "flag"
        case .paint:
            return "paintbrush"
        case .controlPanel:
            return "gearshape"
        case .systemProperties:
            return "desktopcomputer"
        case .displayProperties:
            return "display"
        case .internetExplorer:
            return "globe"
        case .runDialog:
            return "play.circle"
        }
    }
    
    public var defaultSize: CGSize {
        switch self {
        case .explorer:
            return CGSize(width: 700, height: 480)
        case .notepad:
            return CGSize(width: 550, height: 400)
        case .cmd:
            return CGSize(width: 600, height: 350)
        case .calculator:
            return CGSize(width: 260, height: 320)
        case .minesweeper:
            return CGSize(width: 280, height: 360)
        case .paint:
            return CGSize(width: 680, height: 480)
        case .controlPanel:
            return CGSize(width: 640, height: 440)
        case .systemProperties:
            return CGSize(width: 440, height: 480)
        case .displayProperties:
            return CGSize(width: 440, height: 490)
        case .internetExplorer:
            return CGSize(width: 800, height: 560)
        case .runDialog:
            return CGSize(width: 400, height: 180)
        }
    }
}

public enum WindowDisplayState: Equatable, Hashable {
    case normal
    case minimized
    case maximized
}

public struct XPWindowInstance: Identifiable, Equatable {
    public let id: UUID
    public var appType: XPAppType
    public var title: String
    public var icon: String
    public var rect: CGRect
    public var restoreRect: CGRect?
    public var state: WindowDisplayState
    public var zIndex: Double
    public var isFocused: Bool
    public var minSize: CGSize
    
    public init(
        id: UUID = UUID(),
        appType: XPAppType,
        title: String? = nil,
        icon: String? = nil,
        rect: CGRect? = nil,
        restoreRect: CGRect? = nil,
        state: WindowDisplayState = .normal,
        zIndex: Double = 0,
        isFocused: Bool = false,
        minSize: CGSize = CGSize(width: 200, height: 150)
    ) {
        self.id = id
        self.appType = appType
        self.title = title ?? appType.defaultTitle
        self.icon = icon ?? appType.defaultIcon
        if let rect = rect {
            self.rect = rect
        } else {
            let size = appType.defaultSize
            self.rect = CGRect(x: 100, y: 100, width: size.width, height: size.height)
        }
        self.restoreRect = restoreRect
        self.state = state
        self.zIndex = zIndex
        self.isFocused = isFocused
        self.minSize = minSize
    }
}
