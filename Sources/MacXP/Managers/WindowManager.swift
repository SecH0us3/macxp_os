import SwiftUI

public class WindowManager: ObservableObject {
    @Published public var windows: [XPWindowInstance] = []
    private var cascadeCounter: Int = 0
    
    public init() {}
    
    public var activeWindow: XPWindowInstance? {
        windows.first(where: { $0.isFocused && $0.state != .minimized })
    }
    
    @discardableResult
    public func openWindow(
        appType: XPAppType,
        title: String? = nil,
        icon: String? = nil,
        rect: CGRect? = nil,
        minSize: CGSize = CGSize(width: 200, height: 150)
    ) -> UUID {
        var targetRect = rect
        if targetRect == nil {
            let size = appType.defaultSize
            let offset = CGFloat((cascadeCounter % 8) * 26)
            cascadeCounter += 1
            targetRect = CGRect(x: 80 + offset, y: 60 + offset, width: size.width, height: size.height)
        }
        
        let highestZ = (windows.map(\.zIndex).max() ?? 0) + 1
        
        // Defocus all other windows
        for i in 0..<windows.count {
            windows[i].isFocused = false
        }
        
        let newWindow = XPWindowInstance(
            appType: appType,
            title: title,
            icon: icon,
            rect: targetRect,
            state: .normal,
            zIndex: highestZ,
            isFocused: true,
            minSize: minSize
        )
        
        windows.append(newWindow)
        return newWindow.id
    }
    
    public func closeWindow(id: UUID) {
        let wasFocused = windows.first(where: { $0.id == id })?.isFocused ?? false
        windows.removeAll { $0.id == id }
        
        // If closed window was focused, transfer focus to top-most visible window
        if wasFocused {
            focusTopMostWindow()
        }
    }
    
    public func focusWindow(id: UUID) {
        guard windows.contains(where: { $0.id == id }) else { return }
        
        let highestZ = (windows.map(\.zIndex).max() ?? 0) + 1
        
        for i in 0..<windows.count {
            if windows[i].id == id {
                // If it was minimized, restore it
                if windows[i].state == .minimized {
                    windows[i].state = .normal
                }
                windows[i].isFocused = true
                windows[i].zIndex = highestZ
            } else {
                windows[i].isFocused = false
            }
        }
    }
    
    public func bringToFront(id: UUID) {
        focusWindow(id: id)
    }
    
    public func minimizeWindow(id: UUID) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        
        let wasFocused = windows[index].isFocused
        windows[index].state = .minimized
        windows[index].isFocused = false
        
        if wasFocused {
            focusTopMostWindow()
        }
    }
    
    public func toggleMaximize(id: UUID, desktopBounds: CGRect = CGRect(x: 0, y: 0, width: 1024, height: 768)) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        
        if windows[index].state == .maximized {
            // Restore
            if let restoreRect = windows[index].restoreRect {
                windows[index].rect = restoreRect
            }
            windows[index].state = .normal
        } else {
            // Maximize
            windows[index].restoreRect = windows[index].rect
            windows[index].rect = desktopBounds
            windows[index].state = .maximized
        }
        
        focusWindow(id: id)
    }
    
    public func minimizeAll() {
        for i in 0..<windows.count {
            windows[i].state = .minimized
            windows[i].isFocused = false
        }
    }
    
    public func restoreAll() {
        for i in 0..<windows.count {
            if windows[i].state == .minimized {
                windows[i].state = .normal
            }
        }
        focusTopMostWindow()
    }
    
    public func toggleShowDesktop(desktopBounds: CGRect = CGRect(x: 0, y: 0, width: 1024, height: 768)) {
        let hasUnminimized = windows.contains { $0.state != .minimized }
        if hasUnminimized {
            minimizeAll()
        } else {
            restoreAll()
        }
    }
    
    public func updateWindowRect(id: UUID, rect: CGRect) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[index].rect = rect
    }
    
    public func updateWindowTitle(id: UUID, title: String) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        windows[index].title = title
    }
    
    public func window(for id: UUID) -> XPWindowInstance? {
        windows.first(where: { $0.id == id })
    }
    
    private func focusTopMostWindow() {
        // Find unminimized window with highest zIndex
        guard let topWindow = windows
            .filter({ $0.state != .minimized })
            .max(by: { $0.zIndex < $1.zIndex }) else {
            return
        }
        
        focusWindow(id: topWindow.id)
    }
}
