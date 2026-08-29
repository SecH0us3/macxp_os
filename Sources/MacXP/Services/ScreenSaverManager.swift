import SwiftUI
import Combine
import AppKit

public class ScreenSaverManager: ObservableObject {
    public static let shared = ScreenSaverManager()

    @Published public var selectedType: ScreenSaverType = .pipes3D
    @Published public var waitMinutes: Int = 5
    @Published public var isFullScreenActive: Bool = false
    @Published public var isSettingsModalOpen: Bool = false
    @Published public var previewTargetType: ScreenSaverType? = nil

    @Published public var starfieldSettings = StarfieldSettings()
    @Published public var pipesSettings = Pipes3DSettings()
    @Published public var mystifySettings = MystifySettings()
    @Published public var xp3DLogoSettings = XP3DLogoSettings()

    private var lastActivityTime: Date = Date()
    private var timer: AnyCancellable?
    private var eventMonitor: Any?

    public init() {
        setupIdleTimer()
        setupEventMonitor()
    }

    private func setupIdleTimer() {
        timer = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkIdle()
            }
    }

    private func setupEventMonitor() {
        #if os(macOS)
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
            self?.recordActivity()
            return event
        }
        #endif
    }

    public func recordActivity() {
        lastActivityTime = Date()
        if isFullScreenActive {
            dismissScreenSaver()
        }
    }

    private func checkIdle() {
        guard selectedType != .none, !isFullScreenActive else { return }
        let idleSeconds = Date().timeIntervalSince(lastActivityTime)
        let threshold = Double(waitMinutes) * 60.0
        if idleSeconds >= threshold {
            isFullScreenActive = true
        }
    }

    public func triggerFullScreenPreview(type: ScreenSaverType? = nil) {
        if let type = type {
            self.previewTargetType = type
        }
        self.isFullScreenActive = true
    }

    public func dismissScreenSaver() {
        self.isFullScreenActive = false
        self.previewTargetType = nil
        self.lastActivityTime = Date()
    }

    public var effectiveType: ScreenSaverType {
        previewTargetType ?? selectedType
    }
}
