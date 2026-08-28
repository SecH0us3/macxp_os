import SwiftUI

public struct TaskSwitcherHUDView: View {
    @ObservedObject public var windowManager: WindowManager
    @ObservedObject public var hotkeyManager: HotkeyManager

    public init(windowManager: WindowManager, hotkeyManager: HotkeyManager) {
        self.windowManager = windowManager
        self.hotkeyManager = hotkeyManager
    }

    private var activeWindows: [XPWindowInstance] {
        let visible = windowManager.windows.filter { $0.state != .minimized }
        return visible.isEmpty ? windowManager.windows : visible
    }

    private var selectedWindow: XPWindowInstance? {
        let windows = activeWindows
        guard !windows.isEmpty,
              hotkeyManager.taskSwitcherIndex >= 0,
              hotkeyManager.taskSwitcherIndex < windows.count else {
            return nil
        }
        return windows[hotkeyManager.taskSwitcherIndex]
    }

    public var body: some View {
        ZStack {
            // Invisible dismiss area
            Color.clear
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    hotkeyManager.confirmTaskSwitcher(windowManager: windowManager)
                }

            // HUD Box
            VStack(spacing: 12) {
                // Icons Row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(activeWindows.enumerated()), id: \.element.id) { index, win in
                            let isSelected = (index == hotkeyManager.taskSwitcherIndex)

                            Button(action: {
                                hotkeyManager.taskSwitcherIndex = index
                                hotkeyManager.confirmTaskSwitcher(windowManager: windowManager)
                            }) {
                                ZStack {
                                    if isSelected {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(Color(red: 0.19, green: 0.42, blue: 0.77).opacity(0.35))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 3)
                                                    .strokeBorder(Color(red: 0.00, green: 0.33, blue: 0.92), lineWidth: 2)
                                            )
                                    }

                                    Image(systemName: win.icon.isEmpty ? "macwindow" : win.icon)
                                        .font(.system(size: 26))
                                        .foregroundColor(Color(red: 0.10, green: 0.35, blue: 0.75))
                                }
                                .frame(width: 44, height: 44)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(maxWidth: 420)

                // Selected Window Title
                if let selected = selectedWindow {
                    Text(selected.title)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.black)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .frame(maxWidth: 380)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.95, green: 0.95, blue: 0.93), Color(red: 0.88, green: 0.88, blue: 0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color(red: 0.00, green: 0.33, blue: 0.92), Color(red: 0.05, green: 0.20, blue: 0.65)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: Color.black.opacity(0.45), radius: 14, x: 2, y: 5)
        }
    }
}
