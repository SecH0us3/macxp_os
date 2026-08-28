import SwiftUI
#if os(macOS)
import AppKit
#endif

public enum HotkeyAction: Equatable {
    case toggleStartMenu
    case openExplorer
    case showDesktop
    case openRunDialog
    case closeActiveWindow
    case taskSwitcherNext
    case taskSwitcherPrevious
    case taskSwitcherConfirm
    case taskSwitcherCancel
    case toggleFullscreen
    case calculatorInput(String)
}

public class HotkeyManager: ObservableObject {
    public static let shared = HotkeyManager()

    @Published public var isTaskSwitcherVisible: Bool = false
    @Published public var taskSwitcherIndex: Int = 0

    #if os(macOS)
    private var localKeyDownMonitor: Any? = nil
    private var localFlagsMonitor: Any? = nil
    #endif

    public init() {}

    deinit {
        stopMonitoring()
    }

    // MARK: - Key Parsing

    #if os(macOS)
    public func parseKey(
        keyCode: UInt16,
        characters: String?,
        modifierFlags: NSEvent.ModifierFlags
    ) -> HotkeyAction? {
        let cleanFlags = modifierFlags.intersection([.command, .option, .control, .shift])
        let isCmd = cleanFlags.contains(.command)
        let isOpt = cleanFlags.contains(.option)
        let isCtrl = cleanFlags.contains(.control)
        let isShift = cleanFlags.contains(.shift)

        // 1. Task Switcher active navigation
        if isTaskSwitcherVisible {
            if keyCode == 53 { // Escape
                return .taskSwitcherCancel
            }
            if keyCode == 36 || keyCode == 49 { // Return or Space
                return .taskSwitcherConfirm
            }
            if keyCode == 48 { // Tab
                return isShift ? .taskSwitcherPrevious : .taskSwitcherNext
            }
        }

        // 2. Tab cycling (Alt+Tab or Cmd+Tab)
        if keyCode == 48 { // Tab
            if isOpt || isCmd {
                return isShift ? .taskSwitcherPrevious : .taskSwitcherNext
            }
        }

        // 3. Escape combinations
        if keyCode == 53 { // Escape
            if isCtrl {
                return .toggleStartMenu
            }
        }

        // 4. Function keys
        if keyCode == 103 { // F11
            return .toggleFullscreen
        }
        if keyCode == 118 && isOpt { // Alt+F4
            return .closeActiveWindow
        }

        // 5. Letter key shortcuts
        // 'e' (14): Explorer
        if keyCode == 14 && (isCmd || isCtrl) {
            return .openExplorer
        }
        // 'd' (2): Show Desktop
        if keyCode == 2 && (isCmd || isCtrl) {
            return .showDesktop
        }
        // 'r' (15): Run Dialog
        if keyCode == 15 && (isCmd || isCtrl) {
            return .openRunDialog
        }
        // 'w' (13): Close Window
        if keyCode == 13 && isCmd {
            return .closeActiveWindow
        }
        // 'f' (3): Fullscreen (Cmd+Ctrl+F)
        if keyCode == 3 && isCmd && isCtrl {
            return .toggleFullscreen
        }

        return nil
    }
    #endif

    // MARK: - Task Switcher State Management

    public func startTaskSwitching(windowCount: Int) {
        guard windowCount > 0 else { return }
        isTaskSwitcherVisible = true
        // Default to second window in MRU order if available, else 0
        taskSwitcherIndex = windowCount > 1 ? 1 : 0
    }

    public func cycleTaskSwitcher(forward: Bool, windowCount: Int) {
        guard windowCount > 0 else { return }
        if !isTaskSwitcherVisible {
            startTaskSwitching(windowCount: windowCount)
            return
        }
        if forward {
            taskSwitcherIndex = (taskSwitcherIndex + 1) % windowCount
        } else {
            taskSwitcherIndex = (taskSwitcherIndex - 1 + windowCount) % windowCount
        }
    }

    public func confirmTaskSwitcher(windowManager: WindowManager) {
        guard isTaskSwitcherVisible else { return }
        let visibleWindows = windowManager.windows.filter { $0.state != .minimized }
        let targetWindows = visibleWindows.isEmpty ? windowManager.windows : visibleWindows
        if taskSwitcherIndex >= 0 && taskSwitcherIndex < targetWindows.count {
            let targetWindow = targetWindows[taskSwitcherIndex]
            windowManager.focusWindow(id: targetWindow.id)
        }
        isTaskSwitcherVisible = false
        taskSwitcherIndex = 0
    }

    public func cancelTaskSwitcher() {
        isTaskSwitcherVisible = false
        taskSwitcherIndex = 0
    }

    // MARK: - Event Monitoring

    public func startMonitoring(
        windowManager: WindowManager,
        onToggleStartMenu: (() -> Void)? = nil,
        onToggleShowDesktop: (() -> Void)? = nil,
        onToggleFullscreen: (() -> Void)? = nil
    ) {
        #if os(macOS)
        stopMonitoring()

        localKeyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }

            if let action = self.parseKey(
                keyCode: event.keyCode,
                characters: event.characters,
                modifierFlags: event.modifierFlags
            ) {
                switch action {
                case .toggleStartMenu:
                    onToggleStartMenu?()
                    return nil
                case .openExplorer:
                    windowManager.openWindow(appType: .explorer(path: "/"))
                    return nil
                case .showDesktop:
                    if let onToggleShowDesktop = onToggleShowDesktop {
                        onToggleShowDesktop()
                    } else {
                        windowManager.toggleShowDesktop()
                    }
                    return nil
                case .openRunDialog:
                    windowManager.openWindow(appType: .runDialog)
                    return nil
                case .closeActiveWindow:
                    if let active = windowManager.activeWindow {
                        windowManager.closeWindow(id: active.id)
                    }
                    return nil
                case .taskSwitcherNext:
                    self.cycleTaskSwitcher(forward: true, windowCount: windowManager.windows.count)
                    return nil
                case .taskSwitcherPrevious:
                    self.cycleTaskSwitcher(forward: false, windowCount: windowManager.windows.count)
                    return nil
                case .taskSwitcherConfirm:
                    self.confirmTaskSwitcher(windowManager: windowManager)
                    return nil
                case .taskSwitcherCancel:
                    self.cancelTaskSwitcher()
                    return nil
                case .toggleFullscreen:
                    onToggleFullscreen?()
                    return nil
                case .calculatorInput:
                    return event
                }
            }

            return event
        }

        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self = self else { return event }
            // If Alt or Cmd released while Task Switcher is open, confirm selection
            let cleanFlags = event.modifierFlags.intersection([.command, .option])
            if self.isTaskSwitcherVisible && cleanFlags.isEmpty {
                self.confirmTaskSwitcher(windowManager: windowManager)
            }
            return event
        }
        #endif
    }

    public func stopMonitoring() {
        #if os(macOS)
        if let monitor = localKeyDownMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyDownMonitor = nil
        }
        if let monitor = localFlagsMonitor {
            NSEvent.removeMonitor(monitor)
            localFlagsMonitor = nil
        }
        #endif
    }
}
