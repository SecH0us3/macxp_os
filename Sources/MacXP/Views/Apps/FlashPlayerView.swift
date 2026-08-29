import SwiftUI
#if os(macOS)
import AppKit
#endif

public enum FlashGameType: String, CaseIterable, Identifiable {
    case copter = "Copter 2004"
    case spaceBlast = "Space Alien Blast"

    public var id: String { rawValue }
    public var filename: String {
        switch self {
        case .copter: return "copter2004.swf"
        case .spaceBlast: return "space_blast.swf"
        }
    }
}

public struct FlashPlayerView: View {
    @ObservedObject public var windowManager: WindowManager
    public let window: XPWindowInstance

    @State private var selectedGame: FlashGameType = .copter
    @State private var isPlaying: Bool = true
    @State private var isMuted: Bool = false
    @State private var showAboutModal: Bool = false
    @State private var showContextMenu: Bool = false
    @State private var contextMenuPos: CGPoint = .zero

    public init(windowManager: WindowManager, window: XPWindowInstance) {
        self.windowManager = windowManager
        self.window = window
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 1. Classic Windows XP Menu Bar
            menuBar
                .frame(height: 20)
                .background(Color(red: 0.93, green: 0.91, blue: 0.85))

            // 2. Sub-menu / Game Switcher Tabs
            gameTabBar
                .frame(height: 24)
                .background(Color(red: 0.85, green: 0.83, blue: 0.78))

            Divider()

            // 3. The Flash Stage Canvas
            ZStack {
                Color.black

                switch selectedGame {
                case .copter:
                    FlashCopterGameView(isPlaying: isPlaying, isMuted: isMuted)
                case .spaceBlast:
                    FlashSpaceGameView(isPlaying: isPlaying, isMuted: isMuted)
                }

                // Flash Right-Click Context Menu Overlay
                if showContextMenu {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showContextMenu = false
                        }

                    flashContextMenu
                        .position(x: min(max(contextMenuPos.x + 60, 80), 550), y: min(max(contextMenuPos.y + 60, 80), 380))
                }

                // About Modal Dialog
                if showAboutModal {
                    aboutModalView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            #if os(macOS)
            .contextMenu {
                Button("Macromedia Flash Player 8") {}
                    .disabled(true)
                Divider()
                Button("Zoom In") {}
                Button("Zoom Out") {}
                Button("100%") {}
                Button("Quality: High") {}
                Divider()
                Button("Play / Pause") {
                    isPlaying.toggle()
                }
                Button("Rewind") {
                    isPlaying = true
                }
                Divider()
                Button("About Macromedia Flash Player 8...") {
                    showAboutModal = true
                }
            }
            #endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Menu Bar
    private var menuBar: some View {
        HStack(spacing: 12) {
            Menu("File") {
                Button("Copter 2004 (.swf)") {
                    selectedGame = .copter
                }
                Button("Space Alien Blast (.swf)") {
                    selectedGame = .spaceBlast
                }
                Divider()
                Button("Close") {
                    windowManager.closeWindow(id: window.id)
                }
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .font(.system(size: 11))
            .foregroundColor(.black)

            Menu("View") {
                Button("100%") {}
                Button("Show All") {}
                Button("Full Screen") {}
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .font(.system(size: 11))
            .foregroundColor(.black)

            Menu("Control") {
                Button(isPlaying ? "Pause" : "Play") {
                    isPlaying.toggle()
                }
                Button("Rewind") {
                    isPlaying = true
                }
                Button("Loop") {}
                Divider()
                Button(isMuted ? "Unmute Audio" : "Mute Audio") {
                    isMuted.toggle()
                }
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .font(.system(size: 11))
            .foregroundColor(.black)

            Menu("Help") {
                Button("About Macromedia Flash Player 8...") {
                    showAboutModal = true
                }
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .font(.system(size: 11))
            .foregroundColor(.black)

            Spacer()

            // Macromedia Logo pill
            HStack(spacing: 4) {
                #if os(macOS)
                if let icon = XPAssetProvider.loadFlashIcon() {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                }
                #endif
                Text("Macromedia Flash Player 8")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 0.65, green: 0.10, blue: 0.10))
            }
            .padding(.trailing, 8)
        }
        .padding(.horizontal, 6)
    }

    // MARK: - Game Tab Bar
    private var gameTabBar: some View {
        HStack(spacing: 2) {
            ForEach(FlashGameType.allCases) { game in
                Button(action: {
                    selectedGame = game
                    isPlaying = true
                }) {
                    HStack(spacing: 4) {
                        #if os(macOS)
                        if let icon = XPAssetProvider.loadFlashIcon() {
                            Image(nsImage: icon)
                                .resizable()
                                .interpolation(.high)
                                .scaledToFit()
                                .frame(width: 12, height: 12)
                        }
                        #endif
                        Text(game.filename)
                            .font(.system(size: 11, weight: selectedGame == game ? .bold : .regular))
                            .foregroundColor(selectedGame == game ? .black : Color(red: 0.30, green: 0.30, blue: 0.30))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        selectedGame == game ?
                            Color.white :
                            Color(red: 0.80, green: 0.78, blue: 0.73)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }

            Spacer()

            Text("FPS: 30.0")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.gray)
                .padding(.trailing, 8)
        }
        .padding(.horizontal, 6)
    }

    // MARK: - Flash Context Menu
    private var flashContextMenu: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Macromedia Flash Player 8")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.gray)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)

            Divider()

            Button("Zoom In") { showContextMenu = false }
                .buttonStyle(PlainButtonStyle())
                .font(.system(size: 11))
                .padding(.horizontal, 10)
                .padding(.vertical, 3)

            Button("100%") { showContextMenu = false }
                .buttonStyle(PlainButtonStyle())
                .font(.system(size: 11))
                .padding(.horizontal, 10)
                .padding(.vertical, 3)

            Button("Quality: High") { showContextMenu = false }
                .buttonStyle(PlainButtonStyle())
                .font(.system(size: 11))
                .padding(.horizontal, 10)
                .padding(.vertical, 3)

            Divider()

            Button(isPlaying ? "Pause" : "Play") {
                isPlaying.toggle()
                showContextMenu = false
            }
            .buttonStyle(PlainButtonStyle())
            .font(.system(size: 11))
            .padding(.horizontal, 10)
            .padding(.vertical, 3)

            Button("Rewind") {
                isPlaying = true
                showContextMenu = false
            }
            .buttonStyle(PlainButtonStyle())
            .font(.system(size: 11))
            .padding(.horizontal, 10)
            .padding(.vertical, 3)

            Divider()

            Button("About Macromedia Flash Player 8...") {
                showContextMenu = false
                showAboutModal = true
            }
            .buttonStyle(PlainButtonStyle())
            .font(.system(size: 11))
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
        }
        .frame(width: 175)
        .background(Color(red: 0.95, green: 0.95, blue: 0.94))
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color.black.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 4, x: 2, y: 2)
    }

    // MARK: - About Modal
    private var aboutModalView: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    showAboutModal = false
                }

            VStack(spacing: 12) {
                // Header
                HStack {
                    Text("About Macromedia Flash Player 8")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { showAboutModal = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 8)
                .frame(height: 24)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.00, green: 0.33, blue: 0.92), Color(red: 0.11, green: 0.50, blue: 0.93)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Body
                HStack(spacing: 16) {
                    #if os(macOS)
                    if let icon = XPAssetProvider.loadFlashIcon() {
                        Image(nsImage: icon)
                            .resizable()
                            .interpolation(.high)
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                    }
                    #endif

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Macromedia® Flash® Player 8")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                        Text("Version 8.0.22.0")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        Text("Copyright © 1996-2005 Macromedia, Inc.\nAll rights reserved.")
                            .font(.system(size: 10))
                            .foregroundColor(Color.black.opacity(0.7))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Divider()

                Button("OK") {
                    showAboutModal = false
                }
                .font(.system(size: 11))
                .frame(width: 75, height: 22)
                .background(Color(red: 0.92, green: 0.91, blue: 0.87))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .buttonStyle(PlainButtonStyle())
                .padding(.bottom, 10)
            }
            .frame(width: 320)
            .background(Color(red: 0.94, green: 0.93, blue: 0.90))
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color(red: 0.00, green: 0.20, blue: 0.70), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.5), radius: 10)
        }
    }
}

// MARK: - Game 1: Copter 2004 (Legendary Flash Helicopter Game)

public struct FlashCopterGameView: View {
    public let isPlaying: Bool
    public let isMuted: Bool

    @State private var helicopterY: CGFloat = 160
    @State private var velocityY: CGFloat = 0
    @State private var isHoldingThrust: Bool = false
    @State private var isGameOver: Bool = false
    @State private var score: Int = 0
    @State private var bestScore: Int = 0
    @State private var distanceX: CGFloat = 0
    @State private var obstacles: [CGRect] = []
    @State private var particles: [CGPoint] = []

    private let gravity: CGFloat = 0.45
    private let thrust: CGFloat = -0.55
    private let maxVelocity: CGFloat = 7.0

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background Cave (Classic Flash Green Cavern)
                Color(red: 0.05, green: 0.12, blue: 0.06)
                    .ignoresSafeArea()

                // Top & Bottom Cavern Walls
                VStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.15, green: 0.45, blue: 0.18), Color(red: 0.08, green: 0.28, blue: 0.10)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 45)
                    Spacer()
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.08, green: 0.28, blue: 0.10), Color(red: 0.15, green: 0.45, blue: 0.18)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 45)
                }

                // Obstacle Pillars
                ForEach(0..<obstacles.count, id: \.self) { i in
                    let r = obstacles[i]
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.25, green: 0.65, blue: 0.28), Color(red: 0.12, green: 0.40, blue: 0.15)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color(red: 0.35, green: 0.85, blue: 0.40), lineWidth: 1)
                        )
                        .frame(width: r.width, height: r.height)
                        .position(x: r.midX, y: r.midY)
                }

                // Particle Smoke Trail
                ForEach(0..<particles.count, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 4, height: 4)
                        .position(particles[i])
                }

                // The Helicopter
                if !isGameOver {
                    helicopterBody
                        .position(x: 100, y: helicopterY)
                }

                // HUD Score Bar
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DISTANCE: \(score) m")
                                .font(.system(size: 13, weight: .black, design: .monospaced))
                                .foregroundColor(Color(red: 0.40, green: 1.00, blue: 0.40))
                            Text("BEST: \(bestScore) m")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(.top, 50)
                        .padding(.leading, 12)

                        Spacer()

                        Text("HOLD CLICK TO FLY UP")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.yellow.opacity(0.85))
                            .padding(.top, 50)
                            .padding(.trailing, 12)
                    }
                    Spacer()
                }

                // Game Over Screen
                if isGameOver {
                    VStack(spacing: 12) {
                        Text("GAME OVER")
                            .font(.system(size: 26, weight: .black, design: .default))
                            .foregroundColor(Color(red: 1.0, green: 0.25, blue: 0.25))
                            .shadow(color: Color.red.opacity(0.6), radius: 6)

                        Text("DISTANCE: \(score) m")
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)

                        Button(action: {
                            restartGame(stageHeight: geo.size.height)
                        }) {
                            Text("CLICK TO PLAY AGAIN")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(red: 0.40, green: 1.00, blue: 0.40))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(24)
                    .background(Color.black.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(red: 0.40, green: 1.00, blue: 0.40), lineWidth: 1.5)
                    )
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isGameOver {
                            isHoldingThrust = true
                        }
                    }
                    .onEnded { _ in
                        if isGameOver {
                            restartGame(stageHeight: geo.size.height)
                        } else {
                            isHoldingThrust = false
                        }
                    }
            )
            .onAppear {
                restartGame(stageHeight: geo.size.height > 0 ? geo.size.height : 360)
            }
            .onReceive(Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()) { _ in
                guard isPlaying && !isGameOver else { return }
                updateGame(stageWidth: geo.size.width, stageHeight: geo.size.height)
            }
        }
    }

    private var helicopterBody: some View {
        ZStack {
            // Main Green Oval Body
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.50, green: 0.95, blue: 0.50), Color(red: 0.15, green: 0.65, blue: 0.20)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 26, height: 16)

            // Cockpit glass
            Ellipse()
                .fill(Color.cyan.opacity(0.8))
                .frame(width: 8, height: 8)
                .offset(x: 6, y: -2)

            // Tail rotor boom
            Rectangle()
                .fill(Color(red: 0.20, green: 0.70, blue: 0.25))
                .frame(width: 14, height: 3)
                .offset(x: -14, y: 0)

            // Tail fin & rotor
            Rectangle()
                .fill(Color(red: 0.15, green: 0.55, blue: 0.20))
                .frame(width: 2, height: 10)
                .offset(x: -20, y: -2)

            // Top Rotor Blade
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 28, height: 2)
                .offset(y: -10)
        }
        .rotationEffect(.degrees(Double(velocityY * 2.5)))
    }

    private func restartGame(stageHeight: CGFloat) {
        helicopterY = stageHeight / 2.0
        velocityY = 0
        isHoldingThrust = false
        isGameOver = false
        score = 0
        distanceX = 0
        particles.removeAll()

        // Generate initial pillars
        obstacles = [
            CGRect(x: 400, y: 120, width: 28, height: 110),
            CGRect(x: 620, y: 180, width: 28, height: 120),
            CGRect(x: 840, y: 90, width: 28, height: 100)
        ]
    }

    private func updateGame(stageWidth: CGFloat, stageHeight: CGFloat) {
        if isHoldingThrust {
            velocityY = max(velocityY + thrust, -maxVelocity)
        } else {
            velocityY = min(velocityY + gravity, maxVelocity)
        }

        helicopterY += velocityY
        score += 1
        if score > bestScore {
            bestScore = score
        }

        // Add smoke particle
        if score % 3 == 0 {
            particles.append(CGPoint(x: 85, y: helicopterY + CGFloat.random(in: -2...2)))
            if particles.count > 25 {
                particles.removeFirst()
            }
        }
        for i in 0..<particles.count {
            particles[i].x -= 3.5
        }

        // Move obstacles
        let speed: CGFloat = 3.5 + min(CGFloat(score) / 500.0, 3.5)
        for i in 0..<obstacles.count {
            obstacles[i].origin.x -= speed
        }

        // Recycle obstacles
        if let first = obstacles.first, first.maxX < 0 {
            obstacles.removeFirst()
            let lastX = obstacles.last?.origin.x ?? stageWidth
            let nextX = lastX + CGFloat.random(in: 200...260)
            let nextY = CGFloat.random(in: 80...(stageHeight - 140))
            let nextH = CGFloat.random(in: 80...130)
            obstacles.append(CGRect(x: nextX, y: nextY, width: 28, height: nextH))
        }

        // Collision detection
        let playerRect = CGRect(x: 88, y: helicopterY - 8, width: 24, height: 16)
        if helicopterY <= 48 || helicopterY >= (stageHeight - 48) {
            triggerGameOver()
            return
        }

        for ob in obstacles {
            if playerRect.intersects(ob) {
                triggerGameOver()
                return
            }
        }
    }

    private func triggerGameOver() {
        isGameOver = true
        if !isMuted {
            SoundManager.shared.play(.exclamation)
        }
    }
}

// MARK: - Game 2: Space Alien Blast

public struct FlashSpaceGameView: View {
    public let isPlaying: Bool
    public let isMuted: Bool

    @State private var playerX: CGFloat = 200
    @State private var lasers: [CGPoint] = []
    @State private var aliens: [CGPoint] = []
    @State private var alienDirection: CGFloat = 1.0
    @State private var score: Int = 0
    @State private var lives: Int = 3
    @State private var isGameOver: Bool = false

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Space Background with Stars
                Color(red: 0.02, green: 0.02, blue: 0.08)
                    .ignoresSafeArea()

                // Starfield dots
                ForEach(0..<20, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 2, height: 2)
                        .position(x: CGFloat((i * 47) % Int(geo.size.width > 0 ? geo.size.width : 400)),
                                  y: CGFloat((i * 83) % Int(geo.size.height > 0 ? geo.size.height : 300)))
                }

                // Alien Invaders
                ForEach(0..<aliens.count, id: \.self) { i in
                    let pos = aliens[i]
                    ZStack {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.30, blue: 0.60))
                            .frame(width: 20, height: 16)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 4, height: 4)
                            .offset(x: -4, y: -2)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 4, height: 4)
                            .offset(x: 4, y: -2)
                    }
                    .position(pos)
                }

                // Lasers
                ForEach(0..<lasers.count, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.yellow)
                        .frame(width: 3, height: 10)
                        .shadow(color: .yellow, radius: 3)
                        .position(lasers[i])
                }

                // Player Spaceship
                ZStack {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: -12))
                        path.addLine(to: CGPoint(x: 12, y: 12))
                        path.addLine(to: CGPoint(x: -12, y: 12))
                        path.closeSubpath()
                    }
                    .fill(Color.cyan)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 5, height: 5)
                        .offset(y: -2)
                }
                .position(x: playerX, y: max(geo.size.height - 35, 40))

                // Score & Lives HUD
                VStack {
                    HStack {
                        Text("SCORE: \(score)")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundColor(.cyan)

                        Spacer()

                        HStack(spacing: 4) {
                            ForEach(0..<lives, id: \.self) { _ in
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.6))

                    Spacer()
                }

                // Game Over Overlay
                if isGameOver {
                    VStack(spacing: 12) {
                        Text(aliens.isEmpty ? "VICTORY!" : "GAME OVER")
                            .font(.system(size: 24, weight: .black))
                            .foregroundColor(aliens.isEmpty ? .green : .red)

                        Text("FINAL SCORE: \(score)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)

                        Button("PLAY AGAIN") {
                            resetSpaceGame(stageWidth: geo.size.width, stageHeight: geo.size.height)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.cyan)
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        playerX = min(max(value.location.x, 20), geo.size.width - 20)
                    }
                    .onEnded { _ in
                        if isGameOver {
                            resetSpaceGame(stageWidth: geo.size.width, stageHeight: geo.size.height)
                        } else {
                            shootLaser(geoHeight: geo.size.height)
                        }
                    }
            )
            .onAppear {
                resetSpaceGame(stageWidth: geo.size.width > 0 ? geo.size.width : 400, stageHeight: geo.size.height > 0 ? geo.size.height : 360)
            }
            .onReceive(Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()) { _ in
                guard isPlaying && !isGameOver else { return }
                updateSpaceGame(stageWidth: geo.size.width, stageHeight: geo.size.height)
            }
        }
    }

    private func shootLaser(geoHeight: CGFloat) {
        lasers.append(CGPoint(x: playerX, y: geoHeight - 45))
        if !isMuted {
            SoundManager.shared.play(.navigation)
        }
    }

    private func resetSpaceGame(stageWidth: CGFloat, stageHeight: CGFloat) {
        playerX = stageWidth / 2.0
        lasers.removeAll()
        aliens.removeAll()
        score = 0
        lives = 3
        isGameOver = false

        // Generate 3 rows of aliens
        let cols = 6
        let startX = max((stageWidth - CGFloat(cols * 40)) / 2.0, 30)
        for r in 0..<3 {
            for c in 0..<cols {
                aliens.append(CGPoint(x: startX + CGFloat(c * 40), y: CGFloat(50 + r * 30)))
            }
        }
    }

    private func updateSpaceGame(stageWidth: CGFloat, stageHeight: CGFloat) {
        // Move lasers
        for i in (0..<lasers.count).reversed() {
            lasers[i].y -= 6.0
            if lasers[i].y < 0 {
                lasers.remove(at: i)
            }
        }

        // Move aliens horizontally
        var changeDir = false
        for i in 0..<aliens.count {
            aliens[i].x += alienDirection * 1.2
            if aliens[i].x < 20 || aliens[i].x > (stageWidth - 20) {
                changeDir = true
            }
        }
        if changeDir {
            alienDirection *= -1.0
            for i in 0..<aliens.count {
                aliens[i].y += 10
            }
        }

        // Laser & Alien collision
        for li in (0..<lasers.count).reversed() {
            let lp = lasers[li]
            for ai in (0..<aliens.count).reversed() {
                let ap = aliens[ai]
                let dist = hypot(lp.x - ap.x, lp.y - ap.y)
                if dist < 16 {
                    lasers.remove(at: li)
                    aliens.remove(at: ai)
                    score += 100
                    break
                }
            }
        }

        // Victory condition
        if aliens.isEmpty {
            isGameOver = true
        }

        // Alien reaches player
        for ap in aliens {
            if ap.y >= (stageHeight - 50) {
                isGameOver = true
                break
            }
        }
    }
}
