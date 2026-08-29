import SwiftUI
import AVFoundation
#if os(macOS)
import AppKit
#endif

public enum VisualizerMode: String, CaseIterable, Identifiable {
    case barsAndWaves = "Bars and Waves"
    case oscilloscope = "Oscilloscope"
    case neonAmbience = "Ambience : Neon Tunnel"
    case fireSpikes = "Spikes : Fire"

    public var id: String { rawValue }
}

public enum WMPPlaybackState: Equatable {
    case stopped
    case playing
    case paused
}

public struct MediaPlayerTrack: Identifiable, Equatable {
    public let id: UUID
    public var title: String
    public var artist: String
    public var duration: TimeInterval
    public var url: URL?
    public var isSample: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        artist: String = "Windows XP Media",
        duration: TimeInterval = 180,
        url: URL? = nil,
        isSample: Bool = false
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.duration = duration
        self.url = url
        self.isSample = isSample
    }
}

public class MediaPlayerViewModel: ObservableObject {
    @Published public var playlist: [MediaPlayerTrack] = []
    @Published public var currentTrackIndex: Int = 0
    @Published public var playbackState: WMPPlaybackState = .stopped
    @Published public var currentTime: TimeInterval = 0
    @Published public var duration: TimeInterval = 180
    @Published public var volume: Float = 0.8
    @Published public var isMuted: Bool = false
    @Published public var visualizerMode: VisualizerMode = .barsAndWaves
    @Published public var isPlaylistOpen: Bool = true
    @Published public var isRepeatOn: Bool = false
    @Published public var isShuffleOn: Bool = false

    private var avPlayer: AVPlayer?
    private var timer: Timer?

    public var currentTrack: MediaPlayerTrack? {
        guard currentTrackIndex >= 0 && currentTrackIndex < playlist.count else { return nil }
        return playlist[currentTrackIndex]
    }

    public init(initialFileURL: URL? = nil) {
        setupDefaultPlaylist()
        if let fileURL = initialFileURL {
            addTrack(url: fileURL, title: fileURL.deletingPathExtension().lastPathComponent)
            currentTrackIndex = playlist.count - 1
            play()
        }
    }

    private func setupDefaultPlaylist() {
        playlist = [
            MediaPlayerTrack(
                title: "Like Humans Do",
                artist: "David Byrne",
                duration: 213,
                isSample: true
            ),
            MediaPlayerTrack(
                title: "Windows XP Tour (Title)",
                artist: "Microsoft Sound Team",
                duration: 144,
                isSample: true
            ),
            MediaPlayerTrack(
                title: "Symphony No. 9 in D minor",
                artist: "Ludwig van Beethoven",
                duration: 320,
                isSample: true
            )
        ]
        currentTrackIndex = 0
        if let first = playlist.first {
            duration = first.duration
        }
    }

    public func selectTrack(at index: Int) {
        guard index >= 0 && index < playlist.count else { return }
        currentTrackIndex = index
        currentTime = 0
        if let track = currentTrack {
            duration = track.duration
        }
        play()
    }

    public func play() {
        guard let track = currentTrack else { return }
        playbackState = .playing

        if let fileURL = track.url {
            let item = AVPlayerItem(url: fileURL)
            avPlayer = AVPlayer(playerItem: item)
            avPlayer?.volume = isMuted ? 0 : volume
            avPlayer?.play()
        } else {
            // Sample synthesized audio track
            SoundManager.shared.play(.navigation)
        }

        startTimer()
    }

    public func pause() {
        playbackState = .paused
        avPlayer?.pause()
        stopTimer()
    }

    public func stop() {
        playbackState = .stopped
        currentTime = 0
        avPlayer?.pause()
        avPlayer?.seek(to: .zero)
        stopTimer()
    }

    public func nextTrack() {
        guard !playlist.isEmpty else { return }
        if isShuffleOn {
            currentTrackIndex = Int.random(in: 0..<playlist.count)
        } else {
            currentTrackIndex = (currentTrackIndex + 1) % playlist.count
        }
        currentTime = 0
        if let track = currentTrack {
            duration = track.duration
        }
        play()
    }

    public func previousTrack() {
        guard !playlist.isEmpty else { return }
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        currentTrackIndex = (currentTrackIndex - 1 + playlist.count) % playlist.count
        currentTime = 0
        if let track = currentTrack {
            duration = track.duration
        }
        play()
    }

    public func seek(to time: TimeInterval) {
        currentTime = max(0, min(time, duration))
        if let player = avPlayer {
            let cmTime = CMTime(seconds: currentTime, preferredTimescale: 600)
            player.seek(to: cmTime)
        }
    }

    public func nextVisualizerMode() {
        let all = VisualizerMode.allCases
        if let idx = all.firstIndex(of: visualizerMode) {
            let next = (idx + 1) % all.count
            visualizerMode = all[next]
        }
    }

    public func previousVisualizerMode() {
        let all = VisualizerMode.allCases
        if let idx = all.firstIndex(of: visualizerMode) {
            let prev = (idx - 1 + all.count) % all.count
            visualizerMode = all[prev]
        }
    }

    public func addTrack(url: URL, title: String) {
        let track = MediaPlayerTrack(
            title: title,
            artist: "Local Media",
            duration: 240,
            url: url,
            isSample: false
        )
        playlist.append(track)
    }

    public func openFileDialog() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.audio, .movie, .mp3, .mpeg4Movie, .quickTimeMovie]

        if panel.runModal() == .OK {
            for url in panel.urls {
                let name = url.deletingPathExtension().lastPathComponent
                addTrack(url: url, title: name)
            }
            if !panel.urls.isEmpty {
                currentTrackIndex = playlist.count - panel.urls.count
                play()
            }
        }
        #endif
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self = self, self.playbackState == .playing else { return }
            if self.currentTime < self.duration {
                self.currentTime += 0.25
            } else {
                if self.isRepeatOn {
                    self.seek(to: 0)
                } else {
                    self.nextTrack()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        stopTimer()
        avPlayer?.pause()
    }
}

public struct WindowsMediaPlayerView: View {
    @ObservedObject public var windowManager: WindowManager
    public var window: XPWindowInstance?
    @StateObject public var viewModel: MediaPlayerViewModel

    public init(
        fileURL: URL? = nil,
        windowManager: WindowManager,
        window: XPWindowInstance? = nil
    ) {
        self.windowManager = windowManager
        self.window = window
        _viewModel = StateObject(wrappedValue: MediaPlayerViewModel(initialFileURL: fileURL))
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 1. Classic WMP 9 Menu Bar
            menuBar

            // 2. Main Stage (Visualizer + Playlist Drawer)
            HStack(spacing: 0) {
                // Visualizer & Video Canvas
                visualizerStage
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)

                // Playlist Sidebar Drawer
                if viewModel.isPlaylistOpen {
                    playlistSidebar
                        .frame(width: 220)
                        .background(Color(red: 0.12, green: 0.14, blue: 0.20))
                }
            }

            // 3. WMP 9 Authentic Bottom Playback Bezel
            bottomPlaybackDock
        }
        .background(Color(red: 0.08, green: 0.12, blue: 0.20))
    }

    // MARK: - Menu Bar
    private var menuBar: some View {
        HStack(spacing: 0) {
            menuBtn("File") {
                viewModel.openFileDialog()
            }
            menuBtn("View") {
                viewModel.nextVisualizerMode()
            }
            menuBtn("Play") {
                if viewModel.playbackState == .playing {
                    viewModel.pause()
                } else {
                    viewModel.play()
                }
            }
            menuBtn("Tools") {}
            menuBtn("Help") {}
            Spacer()

            // Playlist Toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    viewModel.isPlaylistOpen.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 10))
                    Text(viewModel.isPlaylistOpen ? "Hide Playlist" : "Show Playlist")
                        .font(.system(size: 10))
                }
                .foregroundColor(Color(red: 0.70, green: 0.85, blue: 1.0))
                .padding(.horizontal, 6)
                .frame(height: 18)
                .background(Color.white.opacity(0.1))
                .cornerRadius(2)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 6)
        }
        .frame(height: 22)
        .background(
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.22, blue: 0.35), Color(red: 0.08, green: 0.12, blue: 0.22)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(red: 0.25, green: 0.35, blue: 0.50)), alignment: .bottom)
    }

    private func menuBtn(_ title: String, action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.white)
                .padding(.horizontal, 7)
                .frame(height: 20)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Visualizer Stage
    private var visualizerStage: some View {
        ZStack {
            // Background Glow
            RadialGradient(
                gradient: Gradient(colors: [Color(red: 0.05, green: 0.15, blue: 0.35), Color.black]),
                center: .center,
                startRadius: 10,
                endRadius: 280
            )

            // Animated Visualizer Graphics
            TimelineView(.animation(minimumInterval: 0.05)) { timeline in
                let time = timeline.date.timeIntervalSince1970
                let isPlaying = (viewModel.playbackState == .playing)

                switch viewModel.visualizerMode {
                case .barsAndWaves:
                    barsVisualizer(time: time, isPlaying: isPlaying)
                case .oscilloscope:
                    oscilloscopeVisualizer(time: time, isPlaying: isPlaying)
                case .neonAmbience:
                    neonAmbienceVisualizer(time: time, isPlaying: isPlaying)
                case .fireSpikes:
                    fireSpikesVisualizer(time: time, isPlaying: isPlaying)
                }
            }

            // Track Header Overlay (Top)
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.currentTrack?.title ?? "No Track Selected")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2)

                        Text(viewModel.currentTrack?.artist ?? "")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.60, green: 0.80, blue: 1.0))
                            .shadow(color: .black, radius: 2)
                    }
                    Spacer()

                    // Visualizer Mode Switcher (Top Right)
                    HStack(spacing: 6) {
                        Button(action: { viewModel.previousVisualizerMode() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 16, height: 16)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())

                        Text(viewModel.visualizerMode.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 0.85, green: 0.90, blue: 1.0))
                            .shadow(color: .black, radius: 1)

                        Button(action: { viewModel.nextVisualizerMode() }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 16, height: 16)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(4)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(12)
                }
                .padding(10)
                Spacer()
            }
        }
    }

    // Visualizer Mode 1: Frequency Bars
    private func barsVisualizer(time: Double, isPlaying: Bool) -> some View {
        HStack(alignment: .bottom, spacing: 5) {
            ForEach(0..<24, id: \.self) { i in
                let basePhase = Double(i) * 0.45 + time * 3.5
                let heightFactor = isPlaying ? (sin(basePhase) * 0.4 + cos(basePhase * 0.7) * 0.3 + 0.35) : 0.05
                let h = max(6, heightFactor * 140)

                VStack(spacing: 1) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.20, blue: 0.20),
                                    Color(red: 1.0, green: 0.85, blue: 0.10),
                                    Color(red: 0.20, green: 0.85, blue: 0.30)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 8, height: CGFloat(h))
                }
            }
        }
        .frame(height: 150)
    }

    // Visualizer Mode 2: Oscilloscope Wave
    private func oscilloscopeVisualizer(time: Double, isPlaying: Bool) -> some View {
        GeometryReader { geo in
            Path { path in
                let width = geo.size.width
                let midY = geo.size.height / 2
                let step = 4.0

                path.move(to: CGPoint(x: 0, y: midY))

                for x in stride(from: 0.0, through: width, by: step) {
                    let freq = x / 30.0
                    let wave = isPlaying ? (sin(freq + time * 6.0) * 35.0 + sin(freq * 2.2 - time * 4.0) * 15.0) : 0.0
                    path.addLine(to: CGPoint(x: x, y: midY + wave))
                }
            }
            .stroke(
                Color(red: 0.20, green: 0.95, blue: 0.40),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )
            .shadow(color: Color(red: 0.20, green: 0.95, blue: 0.40).opacity(0.8), radius: 6)
        }
        .frame(height: 120)
        .padding(.horizontal, 20)
    }

    // Visualizer Mode 3: Neon Ambience Ripples
    private func neonAmbienceVisualizer(time: Double, isPlaying: Bool) -> some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                let phase = (time * 1.5 + Double(i) * 0.4).truncatingRemainder(dividingBy: 2.0)
                let scale = isPlaying ? (0.3 + phase * 0.6) : 0.4
                let opacity = isPlaying ? max(0, 1.0 - phase * 0.5) : 0.2

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.cyan, Color.purple, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .frame(width: 200, height: 200)
            }
        }
    }

    // Visualizer Mode 4: Fire Spikes
    private func fireSpikesVisualizer(time: Double, isPlaying: Bool) -> some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(0..<32, id: \.self) { i in
                let phase = Double(i) * 0.6 + time * 5.0
                let h = isPlaying ? (abs(sin(phase)) * 120.0 + Double.random(in: 0...20)) : 8.0

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange, Color.red],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 6, height: CGFloat(h))
            }
        }
        .frame(height: 150)
    }

    // MARK: - Playlist Sidebar
    private var playlistSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Now Playing")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(viewModel.playlist.count) tracks")
                    .font(.system(size: 10))
                    .foregroundColor(Color.gray)
            }
            .padding(.horizontal, 8)
            .frame(height: 26)
            .background(Color(red: 0.18, green: 0.22, blue: 0.32))

            // Playlist Items
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 1) {
                    ForEach(Array(viewModel.playlist.enumerated()), id: \.element.id) { index, track in
                        let isCurrent = (index == viewModel.currentTrackIndex)

                        Button(action: {
                            viewModel.selectTrack(at: index)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: isCurrent && viewModel.playbackState == .playing ? "speaker.wave.2.fill" : "music.note")
                                    .font(.system(size: 10))
                                    .foregroundColor(isCurrent ? Color(red: 0.30, green: 0.85, blue: 1.0) : Color.gray)
                                    .frame(width: 14)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(track.title)
                                        .font(.system(size: 11, weight: isCurrent ? .bold : .regular))
                                        .foregroundColor(isCurrent ? .white : Color(red: 0.85, green: 0.88, blue: 0.95))
                                        .lineLimit(1)

                                    Text(track.artist)
                                        .font(.system(size: 9))
                                        .foregroundColor(Color.gray)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Text(formatTime(track.duration))
                                    .font(.system(size: 10))
                                    .foregroundColor(isCurrent ? Color(red: 0.60, green: 0.80, blue: 1.0) : Color.gray)
                            }
                            .padding(.horizontal, 8)
                            .frame(height: 32)
                            .background(isCurrent ? Color(red: 0.20, green: 0.38, blue: 0.65) : Color.clear)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }

            // Bottom Add Music Button
            Button(action: {
                viewModel.openFileDialog()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 11))
                    Text("Add Media...")
                        .font(.system(size: 11))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 24)
                .background(Color(red: 0.20, green: 0.35, blue: 0.55))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Bottom Playback Dock
    private var bottomPlaybackDock: some View {
        VStack(spacing: 4) {
            // Seek Scrubber Bar
            HStack(spacing: 8) {
                Text(formatTime(viewModel.currentTime))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color(red: 0.60, green: 0.80, blue: 1.0))
                    .frame(width: 38, alignment: .trailing)

                Slider(
                    value: Binding(
                        get: { viewModel.currentTime },
                        set: { viewModel.seek(to: $0) }
                    ),
                    in: 0...max(1, viewModel.duration)
                )
                .accentColor(Color(red: 0.20, green: 0.65, blue: 1.0))

                Text(formatTime(viewModel.duration))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color(red: 0.60, green: 0.80, blue: 1.0))
                    .frame(width: 38, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)

            // Controls Row (Play, Pause, Stop, Prev, Next, Volume)
            HStack(spacing: 12) {
                // Previous
                controlBtn(icon: "backward.fill", size: 12) {
                    viewModel.previousTrack()
                }

                // Play / Pause (Large center metallic button)
                Button(action: {
                    if viewModel.playbackState == .playing {
                        viewModel.pause()
                    } else {
                        viewModel.play()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.40, green: 0.70, blue: 1.0),
                                        Color(red: 0.10, green: 0.40, blue: 0.80),
                                        Color(red: 0.05, green: 0.25, blue: 0.60)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 36, height: 36)
                            .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1.5))
                            .shadow(color: Color.black.opacity(0.5), radius: 2, x: 1, y: 1)

                        Image(systemName: viewModel.playbackState == .playing ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                // Stop
                controlBtn(icon: "stop.fill", size: 12) {
                    viewModel.stop()
                }

                // Next
                controlBtn(icon: "forward.fill", size: 12) {
                    viewModel.nextTrack()
                }

                Spacer()

                // Shuffle & Repeat
                Button(action: { viewModel.isShuffleOn.toggle() }) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 11))
                        .foregroundColor(viewModel.isShuffleOn ? Color(red: 0.30, green: 0.85, blue: 1.0) : Color.gray)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: { viewModel.isRepeatOn.toggle() }) {
                    Image(systemName: "repeat")
                        .font(.system(size: 11))
                        .foregroundColor(viewModel.isRepeatOn ? Color(red: 0.30, green: 0.85, blue: 1.0) : Color.gray)
                }
                .buttonStyle(PlainButtonStyle())

                // Volume
                HStack(spacing: 4) {
                    Button(action: { viewModel.isMuted.toggle() }) {
                        Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.70, green: 0.85, blue: 1.0))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Slider(value: $viewModel.volume, in: 0...1)
                        .frame(width: 70)
                        .accentColor(Color(red: 0.20, green: 0.65, blue: 1.0))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)
        }
        .frame(height: 70)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.26, blue: 0.40),
                    Color(red: 0.10, green: 0.16, blue: 0.28),
                    Color(red: 0.05, green: 0.09, blue: 0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(red: 0.30, green: 0.45, blue: 0.65)), alignment: .top)
    }

    private func controlBtn(icon: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.30, green: 0.40, blue: 0.55), Color(red: 0.15, green: 0.22, blue: 0.35)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 26, height: 26)
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))

                Image(systemName: icon)
                    .font(.system(size: size))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
