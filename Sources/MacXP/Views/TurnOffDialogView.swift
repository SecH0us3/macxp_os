import SwiftUI
#if os(macOS)
import AppKit
#endif

public class TurnOffDialogModel: ObservableObject {
    public var onStandBy: (() -> Void)?
    public var onTurnOff: (() -> Void)?
    public var onRestart: (() -> Void)?

    public init(
        onStandBy: (() -> Void)? = nil,
        onTurnOff: (() -> Void)? = nil,
        onRestart: (() -> Void)? = nil
    ) {
        self.onStandBy = onStandBy
        self.onTurnOff = onTurnOff
        self.onRestart = onRestart
    }

    public func standBy() {
        onStandBy?()
    }

    public func turnOff() {
        SoundManager.shared.play(.shutdown)
        onTurnOff?()
    }

    public func restart(windowManager: WindowManager? = nil) {
        SoundManager.shared.play(.shutdown)
        if let windowManager = windowManager {
            for win in windowManager.windows {
                windowManager.closeWindow(id: win.id)
            }
        }
        onRestart?()
    }
}

public struct TurnOffDialogView: View {
    @ObservedObject public var windowManager: WindowManager
    @StateObject public var model: TurnOffDialogModel
    public var onDismiss: () -> Void

    public init(
        windowManager: WindowManager,
        onStandBy: (() -> Void)? = nil,
        onTurnOff: (() -> Void)? = nil,
        onRestart: (() -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.windowManager = windowManager
        self.onDismiss = onDismiss
        _model = StateObject(
            wrappedValue: TurnOffDialogModel(
                onStandBy: onStandBy,
                onTurnOff: onTurnOff,
                onRestart: onRestart
            )
        )
    }

    public var body: some View {
        ZStack {
            // Authentic XP Dim / Grayscale Backdrop
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 0.98, green: 0.70, blue: 0.15))
                        Text("Turn off computer")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.6), radius: 1, x: 1, y: 1)
                    }
                    .padding(.leading, 12)

                    Spacer()
                }
                .frame(height: 38)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.00, green: 0.33, blue: 0.92),
                            Color(red: 0.05, green: 0.20, blue: 0.65)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Main Buttons Row
                HStack(spacing: 32) {
                    // 1. Stand By
                    actionButton(
                        title: "Stand By",
                        iconName: "moon.fill",
                        iconColor: Color(red: 0.98, green: 0.75, blue: 0.15),
                        buttonBg: LinearGradient(
                            colors: [Color(red: 0.98, green: 0.85, blue: 0.35), Color(red: 0.85, green: 0.60, blue: 0.10)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    ) {
                        model.standBy()
                        onDismiss()
                    }

                    // 2. Turn Off
                    actionButton(
                        title: "Turn Off",
                        iconName: "power",
                        iconColor: .white,
                        buttonBg: LinearGradient(
                            colors: [Color(red: 0.95, green: 0.35, blue: 0.25), Color(red: 0.78, green: 0.15, blue: 0.10)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    ) {
                        model.turnOff()
                        onDismiss()
                        #if os(macOS)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            NSApplication.shared.terminate(nil)
                        }
                        #endif
                    }

                    // 3. Restart
                    actionButton(
                        title: "Restart",
                        iconName: "arrow.clockwise",
                        iconColor: .white,
                        buttonBg: LinearGradient(
                            colors: [Color(red: 0.30, green: 0.75, blue: 0.25), Color(red: 0.15, green: 0.55, blue: 0.10)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    ) {
                        model.restart(windowManager: windowManager)
                        onDismiss()
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.25, blue: 0.65),
                            Color(red: 0.05, green: 0.12, blue: 0.40)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Footer (Cancel Button)
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Text("Cancel")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.black)
                            .frame(width: 72, height: 22)
                            .background(
                                LinearGradient(
                                    colors: [Color.white, Color(red: 0.88, green: 0.88, blue: 0.88)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(Color(red: 0.0, green: 0.2, blue: 0.6), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 14)
                }
                .frame(height: 36)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.00, green: 0.22, blue: 0.65),
                            Color(red: 0.00, green: 0.15, blue: 0.48)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .frame(width: 320)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color(red: 0.00, green: 0.33, blue: 0.92), lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.6), radius: 16, x: 2, y: 6)
        }
    }

    private func actionButton(
        title: String,
        iconName: String,
        iconColor: Color,
        buttonBg: LinearGradient,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(buttonBg)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.6), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 3, x: 1, y: 2)

                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(iconColor)
                }

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.8), radius: 1, x: 0.5, y: 0.5)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
