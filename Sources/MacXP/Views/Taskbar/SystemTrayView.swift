import SwiftUI
import Combine

#if os(macOS)
import IOKit.ps
#endif

public class SystemTrayModel: ObservableObject {
    @Published public var volumeLevel: Float = 0.8
    @Published public var isMuted: Bool = false
    @Published public var batteryPercentage: Int = 100
    @Published public var isCharging: Bool = false
    @Published public var hasBattery: Bool = true
    @Published public var currentDate: Date = Date()

    private var cancellables = Set<AnyCancellable>()

    public init() {
        updateBatteryStatus()

        // Update clock every second
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] newDate in
                self?.currentDate = newDate
            }
            .store(in: &cancellables)

        // Update battery status every 30 seconds
        Timer.publish(every: 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateBatteryStatus()
            }
            .store(in: &cancellables)
    }

    public func setVolume(_ value: Float) {
        self.volumeLevel = max(0.0, min(1.0, value))
        if volumeLevel > 0 && isMuted {
            isMuted = false
        }
    }

    public func toggleMute() {
        self.isMuted.toggle()
    }

    public static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    public static func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func updateBatteryStatus() {
        #if os(macOS)
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              !sources.isEmpty else {
            self.hasBattery = false
            return
        }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
                continue
            }

            if let current = description[kIOPSCurrentCapacityKey as String] as? Int,
               let max = description[kIOPSMaxCapacityKey as String] as? Int,
               max > 0 {
                self.batteryPercentage = Int((Double(current) / Double(max)) * 100.0)
                self.hasBattery = true
            }

            if let state = description[kIOPSPowerSourceStateKey as String] as? String {
                self.isCharging = (state == (kIOPSACPowerValue as String))
            }
        }
        #else
        self.hasBattery = true
        self.batteryPercentage = 100
        self.isCharging = true
        #endif
    }
}

public struct XPVolumePopup: View {
    @ObservedObject public var model: SystemTrayModel
    public var onClose: () -> Void

    public init(model: SystemTrayModel, onClose: @escaping () -> Void) {
        self.model = model
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Mini Title Bar
            HStack {
                Text("Volume")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.leading, 6)

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 14, height: 14)
                        .background(Color(red: 0.85, green: 0.25, blue: 0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 4)
            }
            .frame(height: 20)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.00, green: 0.33, blue: 0.92),
                        Color(red: 0.04, green: 0.39, blue: 0.86)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // Slider & Mute Body
            VStack(spacing: 8) {
                Text("Master")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.black)

                // Vertical Slider
                GeometryReader { geo in
                    ZStack(alignment: .bottom) {
                        // Slider Track
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(red: 0.82, green: 0.82, blue: 0.82))
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                            .frame(width: 6, height: 90)

                        // Slider Thumb
                        let thumbY = (1.0 - CGFloat(model.volumeLevel)) * 74
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white, Color(red: 0.85, green: 0.85, blue: 0.85)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 22, height: 16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 1)
                            .offset(y: -90 + thumbY + 16)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let normalized = 1.0 - Float(value.location.y / 90.0)
                                        model.setVolume(max(0.0, min(1.0, normalized)))
                                    }
                            )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: 50, height: 90)

                // Mute Checkbox
                Button(action: {
                    model.toggleMute()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: model.isMuted ? "checkmark.square.fill" : "square")
                            .font(.system(size: 12))
                            .foregroundColor(model.isMuted ? Color(red: 0.05, green: 0.35, blue: 0.85) : Color.gray)

                        Text("Mute")
                            .font(.system(size: 10))
                            .foregroundColor(.black)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Color(red: 0.93, green: 0.93, blue: 0.93))
        }
        .frame(width: 90, height: 170)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color(red: 0.00, green: 0.33, blue: 0.92), lineWidth: 1.5)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 8, x: 2, y: 2)
    }
}

public struct SystemTrayView: View {
    @ObservedObject public var model: SystemTrayModel
    public var onToggleVolume: () -> Void
    public var onClockClick: (() -> Void)?

    @State private var isTrayHovered: Bool = false

    public init(
        model: SystemTrayModel,
        onToggleVolume: @escaping () -> Void,
        onClockClick: (() -> Void)? = nil
    ) {
        self.model = model
        self.onToggleVolume = onToggleVolume
        self.onClockClick = onClockClick
    }

    public var body: some View {
        HStack(spacing: 6) {
            // Expand Chevron
            Image(systemName: "chevron.left.circle.fill")
                .font(.system(size: 11))
                .foregroundColor(Color(red: 0.25, green: 0.65, blue: 0.95))

            // Battery Icon (if available)
            if model.hasBattery {
                HStack(spacing: 2) {
                    Image(systemName: batteryIconName)
                        .font(.system(size: 11))
                        .foregroundColor(.white)

                    Text("\(model.batteryPercentage)%")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
                .help("Battery: \(model.batteryPercentage)% \(model.isCharging ? "(Charging)" : "")")
            }

            // Volume Speaker Icon
            Button(action: onToggleVolume) {
                Image(systemName: volumeIconName)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(PlainButtonStyle())
            .help(model.isMuted ? "Volume: Muted" : "Volume: \(Int(model.volumeLevel * 100))%")

            // Digital Live Clock
            Button(action: {
                onClockClick?()
            }) {
                Text(SystemTrayModel.formatTime(model.currentDate))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.4), radius: 0.5, x: 0.5, y: 0.5)
            }
            .buttonStyle(PlainButtonStyle())
            .help(SystemTrayModel.formatFullDate(model.currentDate))
        }
        .padding(.horizontal, 8)
        .frame(height: 30)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.36, blue: 0.83), // Inset Luna tray dark
                    Color(red: 0.08, green: 0.44, blue: 0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color(red: 0.04, green: 0.26, blue: 0.65)),
            alignment: .leading
        )
    }

    private var volumeIconName: String {
        if model.isMuted || model.volumeLevel == 0 {
            return "speaker.slash.fill"
        } else if model.volumeLevel < 0.33 {
            return "speaker.wave.1.fill"
        } else if model.volumeLevel < 0.66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }

    private var batteryIconName: String {
        if model.isCharging {
            return "battery.100.bolt"
        } else if model.batteryPercentage > 75 {
            return "battery.100"
        } else if model.batteryPercentage > 50 {
            return "battery.75"
        } else if model.batteryPercentage > 25 {
            return "battery.50"
        } else {
            return "battery.25"
        }
    }
}
