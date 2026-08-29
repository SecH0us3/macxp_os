import SwiftUI
#if os(macOS)
import AppKit
#endif

public struct BootScreenView: View {
    public var onComplete: () -> Void

    @State private var startTime: Date = Date()
    @State private var isFinished: Bool = false
    private let autoDismissDelay: TimeInterval = 3.0

    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Pitch black background
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Windows XP Logo & Brand
                    VStack(spacing: 8) {
                        // Microsoft subtitle
                        HStack {
                            Text("Microsoft")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.85))
                                .padding(.leading, 4)
                            Spacer()
                        }
                        .frame(width: 260)

                        // Main Windows XP header
                        HStack(alignment: .center, spacing: 10) {
                            // 4-Color Windows Flag
                            #if os(macOS)
                            if let flag = XPAssetProvider.loadFlagImage() {
                                Image(nsImage: flag)
                                    .resizable()
                                    .interpolation(.high)
                                    .scaledToFit()
                                    .frame(width: 52, height: 52)
                                    .shadow(color: Color.blue.opacity(0.4), radius: 6, x: 0, y: 0)
                            } else {
                                fallbackFlag
                            }
                            #else
                            fallbackFlag
                            #endif

                            // Windows xp Title
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("Windows")
                                    .font(.system(size: 36, weight: .bold, design: .default))
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.8), radius: 2, x: 1, y: 1)

                                Text("xp")
                                    .font(.system(size: 38, weight: .black, design: .default))
                                    .italic()
                                    .foregroundColor(Color(red: 0.98, green: 0.38, blue: 0.08))
                                    .shadow(color: Color(red: 0.98, green: 0.38, blue: 0.08).opacity(0.5), radius: 4, x: 0, y: 0)
                            }
                        }
                        .frame(width: 280)

                        // "Professional" Edition line
                        HStack(spacing: 6) {
                            Spacer()
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.clear, Color(red: 0.18, green: 0.52, blue: 0.92)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 1)

                            Text("Professional")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(red: 0.28, green: 0.62, blue: 1.0))
                                .tracking(1.5)
                        }
                        .frame(width: 270)
                    }

                    Spacer().frame(height: 60)

                    // The Famous Running Blue Cubes Progress Bar
                    BootProgressBar(startTime: startTime)
                        .frame(width: 190, height: 14)

                    Spacer()

                    // Bottom Copyright
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("For support, visit: www.microsoft.com")
                                .font(.system(size: 9))
                                .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.60))
                            Text("Copyright © Microsoft Corporation")
                                .font(.system(size: 9))
                                .foregroundColor(Color(red: 0.55, green: 0.55, blue: 0.60))
                        }

                        Spacer()

                        Text("Microsoft")
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .italic()
                            .foregroundColor(Color(red: 0.70, green: 0.70, blue: 0.75))
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                finishBoot()
            }
            .onAppear {
                startTime = Date()
                DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
                    finishBoot()
                }
            }
        }
    }

    private func finishBoot() {
        guard !isFinished else { return }
        isFinished = true
        onComplete()
    }

    private var fallbackFlag: some View {
        ZStack {
            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(red: 0.90, green: 0.25, blue: 0.20))
                        .frame(width: 20, height: 20)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(red: 0.25, green: 0.70, blue: 0.25))
                        .frame(width: 20, height: 20)
                }
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(red: 0.15, green: 0.45, blue: 0.90))
                        .frame(width: 20, height: 20)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(red: 0.95, green: 0.75, blue: 0.15))
                        .frame(width: 20, height: 20)
                }
            }
            .rotationEffect(.degrees(-8))
        }
        .frame(width: 52, height: 52)
    }
}

// MARK: - Boot Progress Bar (Running Blue Cubes)

public struct BootProgressBar: View {
    public let startTime: Date

    private let trackWidth: CGFloat = 190
    private let trackHeight: CGFloat = 14
    private let cubeWidth: CGFloat = 8
    private let cubeHeight: CGFloat = 10
    private let cubeSpacing: CGFloat = 3
    private let speed: Double = 120.0 // Points per second

    public init(startTime: Date = Date()) {
        self.startTime = startTime
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startTime)
            let totalBlockWidth = (cubeWidth * 3) + (cubeSpacing * 2)
            let travelDistance = trackWidth + totalBlockWidth + 20
            let loopTime = Double(travelDistance) / speed
            let cycle = elapsed.truncatingRemainder(dividingBy: loopTime)
            let currentX = CGFloat(cycle * speed) - totalBlockWidth - 10

            ZStack(alignment: .leading) {
                // Track Background
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(red: 0.02, green: 0.04, blue: 0.08))
                    .frame(width: trackWidth, height: trackHeight)

                // Track Inner Shadow & Bevel
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(red: 0.25, green: 0.40, blue: 0.65),
                                Color(red: 0.10, green: 0.18, blue: 0.35)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: trackWidth, height: trackHeight)

                // 3 Running Glowing Blue Cubes
                HStack(spacing: cubeSpacing) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.70, green: 0.88, blue: 1.00), // Top specular highlight
                                        Color(red: 0.22, green: 0.58, blue: 0.98), // Body royal blue
                                        Color(red: 0.08, green: 0.32, blue: 0.80)  // Bottom deep blue
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: cubeWidth, height: cubeHeight)
                            .overlay(
                                RoundedRectangle(cornerRadius: 1.5)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 0.5)
                            )
                            .shadow(color: Color(red: 0.25, green: 0.65, blue: 1.00).opacity(0.8), radius: 3, x: 0, y: 0)
                    }
                }
                .offset(x: currentX)
            }
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .frame(width: trackWidth, height: trackHeight)
        }
    }
}
