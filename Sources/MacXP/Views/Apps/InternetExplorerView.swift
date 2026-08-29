import SwiftUI
import WebKit
#if os(macOS)
import AppKit
#endif

public class InternetExplorerViewModel: ObservableObject {
    @Published public var currentURLString: String
    @Published public var addressBarText: String
    @Published public var pageTitle: String = "Internet Explorer"
    @Published public var isLoading: Bool = false
    @Published public var loadProgress: Double = 0.0
    @Published public var canGoBack: Bool = false
    @Published public var canGoForward: Bool = false
    @Published public var isSecure: Bool = true
    @Published public var history: [String] = []
    @Published public var historyIndex: Int = 0

    // Web action triggers
    @Published public var webAction: WebAction = .none

    public enum WebAction: Equatable {
        case none
        case load(URL)
        case goBack
        case goForward
        case reload
        case stop
    }

    public init(initialURL: String = "https://www.google.com") {
        let normalized = initialURL.isEmpty ? "https://www.google.com" : initialURL
        self.currentURLString = normalized
        self.addressBarText = normalized
        self.history = [normalized]
        self.historyIndex = 0
    }

    public func normalizeInputURL(_ input: String) -> URL {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return URL(string: "https://www.google.com")!
        }

        // Already has scheme
        if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") || trimmed.lowercased().hasPrefix("file://") {
            if let url = URL(string: trimmed) {
                return url
            }
        }

        // Domain with dot and no spaces (e.g. "youtube.com", "apple.com/mac")
        if trimmed.contains(".") && !trimmed.contains(" ") {
            if let url = URL(string: "https://" + trimmed) {
                return url
            }
        }

        // Search Query (e.g. "macxp windows xp theme")
        let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
        return URL(string: "https://www.google.com/search?q=" + encoded) ?? URL(string: "https://www.google.com")!
    }

    public func navigateTo(input: String) {
        let url = normalizeInputURL(input)
        loadURL(url.absoluteString)
    }

    public func loadURL(_ urlString: String) {
        currentURLString = urlString
        addressBarText = urlString
        isSecure = urlString.lowercased().hasPrefix("https://")
        
        if historyIndex < history.count - 1 {
            history.removeSubrange((historyIndex + 1)..<history.count)
        }
        if history.last != urlString {
            history.append(urlString)
            historyIndex = history.count - 1
        }
        updateHistoryState()

        if let url = URL(string: urlString) {
            webAction = .load(url)
            SoundManager.shared.play(.navigation)
        }
    }

    public func goBack() {
        guard canGoBack else { return }
        historyIndex -= 1
        currentURLString = history[historyIndex]
        addressBarText = currentURLString
        isSecure = currentURLString.lowercased().hasPrefix("https://")
        updateHistoryState()
        webAction = .goBack
        SoundManager.shared.play(.navigation)
    }

    public func goForward() {
        guard canGoForward else { return }
        historyIndex += 1
        currentURLString = history[historyIndex]
        addressBarText = currentURLString
        isSecure = currentURLString.lowercased().hasPrefix("https://")
        updateHistoryState()
        webAction = .goForward
        SoundManager.shared.play(.navigation)
    }

    public func reload() {
        webAction = .reload
        SoundManager.shared.play(.navigation)
    }

    public func stop() {
        webAction = .stop
        isLoading = false
    }

    public func goHome() {
        loadURL("https://www.google.com")
    }

    private func updateHistoryState() {
        canGoBack = historyIndex > 0
        canGoForward = historyIndex < history.count - 1
    }
}

#if os(macOS)
public struct XPWebViewRepresentable: NSViewRepresentable {
    @ObservedObject public var viewModel: InternetExplorerViewModel

    public func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsAirPlayForMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView

        if let url = URL(string: viewModel.currentURLString) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    public func updateNSView(_ webView: WKWebView, context: Context) {
        switch viewModel.webAction {
        case .load(let url):
            webView.load(URLRequest(url: url))
            DispatchQueue.main.async {
                self.viewModel.webAction = .none
            }
        case .goBack:
            if webView.canGoBack {
                webView.goBack()
            }
            DispatchQueue.main.async {
                self.viewModel.webAction = .none
            }
        case .goForward:
            if webView.canGoForward {
                webView.goForward()
            }
            DispatchQueue.main.async {
                self.viewModel.webAction = .none
            }
        case .reload:
            webView.reload()
            DispatchQueue.main.async {
                self.viewModel.webAction = .none
            }
        case .stop:
            webView.stopLoading()
            DispatchQueue.main.async {
                self.viewModel.webAction = .none
            }
        case .none:
            break
        }
    }

    public class Coordinator: NSObject, WKNavigationDelegate {
        var viewModel: InternetExplorerViewModel
        weak var webView: WKWebView?
        private var progressObservation: NSKeyValueObservation?

        init(viewModel: InternetExplorerViewModel) {
            self.viewModel = viewModel
            super.init()
        }

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.viewModel.isLoading = true
                if let url = webView.url?.absoluteString {
                    self.viewModel.currentURLString = url
                    self.viewModel.addressBarText = url
                    self.viewModel.isSecure = url.lowercased().hasPrefix("https://")
                }
            }
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.viewModel.isLoading = false
                if let title = webView.title, !title.isEmpty {
                    self.viewModel.pageTitle = "\(title) - Microsoft Internet Explorer"
                } else {
                    self.viewModel.pageTitle = "Microsoft Internet Explorer"
                }
                if let url = webView.url?.absoluteString {
                    self.viewModel.currentURLString = url
                    self.viewModel.addressBarText = url
                    self.viewModel.isSecure = url.lowercased().hasPrefix("https://")
                }
            }
        }

        public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.viewModel.isLoading = false
            }
        }
    }
}
#endif

public struct InternetExplorerView: View {
    @ObservedObject public var windowManager: WindowManager
    public var window: XPWindowInstance?
    @StateObject public var viewModel: InternetExplorerViewModel

    public init(
        initialURL: String = "https://www.google.com",
        windowManager: WindowManager,
        window: XPWindowInstance? = nil
    ) {
        self.windowManager = windowManager
        self.window = window
        _viewModel = StateObject(wrappedValue: InternetExplorerViewModel(initialURL: initialURL))
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 1. Classic IE6 Menu Bar (File, Edit, View, Favorites, Tools, Help)
            ieMenuBar

            // 2. Standard Toolbar (Back, Forward, Stop, Refresh, Home, Search, Favorites, History) + Windows Flag Throbber
            ieToolbar

            // 3. Address Bar
            ieAddressBar

            // 4. Main Web Content
            #if os(macOS)
            XPWebViewRepresentable(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            #else
            Color.white
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            #endif

            // 5. Classic Status Bar
            ieStatusBar
        }
        .background(Color(red: 0.94, green: 0.94, blue: 0.94))
        .onChange(of: viewModel.pageTitle) { newTitle in
            if let win = window {
                windowManager.updateWindowTitle(id: win.id, title: newTitle)
            }
        }
    }

    // MARK: - IE6 Menu Bar
    private var ieMenuBar: some View {
        HStack(spacing: 0) {
            menuBarBtn("File")
            menuBarBtn("Edit")
            menuBarBtn("View")
            menuBarBtn("Favorites")
            menuBarBtn("Tools")
            menuBarBtn("Help")
            Spacer()
        }
        .frame(height: 20)
        .background(
            LinearGradient(
                colors: [Color(red: 0.96, green: 0.95, blue: 0.93), Color(red: 0.90, green: 0.89, blue: 0.86)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(red: 0.82, green: 0.80, blue: 0.78)), alignment: .bottom)
    }

    private func menuBarBtn(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11))
            .foregroundColor(.black)
            .padding(.horizontal, 7)
            .frame(height: 18)
    }

    // MARK: - IE6 Toolbar
    private var ieToolbar: some View {
        HStack(spacing: 2) {
            // Back
            XPToolbarButton(
                title: "Back",
                iconName: "arrow.left.circle.fill",
                iconColor: viewModel.canGoBack ? Color(red: 0.18, green: 0.68, blue: 0.28) : Color.gray.opacity(0.4),
                isEnabled: viewModel.canGoBack
            ) {
                viewModel.goBack()
            }

            // Forward
            XPToolbarButton(
                title: "",
                iconName: "arrow.right.circle.fill",
                iconColor: viewModel.canGoForward ? Color(red: 0.18, green: 0.68, blue: 0.28) : Color.gray.opacity(0.4),
                isEnabled: viewModel.canGoForward
            ) {
                viewModel.goForward()
            }

            // Stop
            XPToolbarButton(
                title: "Stop",
                iconName: "xmark.circle.fill",
                iconColor: viewModel.isLoading ? Color(red: 0.85, green: 0.25, blue: 0.20) : Color.gray.opacity(0.4),
                isEnabled: viewModel.isLoading
            ) {
                viewModel.stop()
            }

            // Refresh
            XPToolbarButton(
                title: "Refresh",
                iconName: "arrow.clockwise.circle.fill",
                iconColor: Color(red: 0.20, green: 0.50, blue: 0.85),
                isEnabled: true
            ) {
                viewModel.reload()
            }

            // Home
            XPToolbarButton(
                title: "Home",
                iconName: "house.fill",
                iconColor: Color(red: 0.88, green: 0.60, blue: 0.20),
                isEnabled: true
            ) {
                viewModel.goHome()
            }

            toolbarDivider

            // Search
            XPToolbarButton(
                title: "Search",
                iconName: "magnifyingglass",
                iconColor: Color(red: 0.88, green: 0.60, blue: 0.20),
                isEnabled: true
            ) {
                viewModel.loadURL("https://www.google.com")
            }

            // Favorites
            XPToolbarButton(
                title: "Favorites",
                iconName: "star.fill",
                iconColor: Color(red: 0.95, green: 0.80, blue: 0.10),
                isEnabled: true
            ) {}

            // History
            XPToolbarButton(
                title: "History",
                iconName: "clock.arrow.circlepath",
                iconColor: Color(red: 0.20, green: 0.50, blue: 0.85),
                isEnabled: true
            ) {}

            Spacer()

            // Classic Windows XP Flag / Globe Throbber
            windowsXPFlagThrobber
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .frame(height: 38)
        .background(
            LinearGradient(
                colors: [Color(red: 0.98, green: 0.98, blue: 0.99), Color(red: 0.92, green: 0.91, blue: 0.89)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(red: 0.82, green: 0.80, blue: 0.78)), alignment: .bottom)
    }

    private var windowsXPFlagThrobber: some View {
        TimelineView(.animation(minimumInterval: 0.1)) { timeline in
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(red: 0.90, green: 0.90, blue: 0.92))
                    .frame(width: 32, height: 32)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.gray.opacity(0.4), lineWidth: 1))

                // XP 4-color flag
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        Rectangle().fill(Color(red: 0.90, green: 0.25, blue: 0.20)).frame(width: 8, height: 8)
                        Rectangle().fill(Color(red: 0.25, green: 0.70, blue: 0.25)).frame(width: 8, height: 8)
                    }
                    HStack(spacing: 2) {
                        Rectangle().fill(Color(red: 0.15, green: 0.45, blue: 0.90)).frame(width: 8, height: 8)
                        Rectangle().fill(Color(red: 0.95, green: 0.75, blue: 0.15)).frame(width: 8, height: 8)
                    }
                }
                .rotationEffect(viewModel.isLoading ? .degrees(Double(timeline.date.timeIntervalSince1970.truncatingRemainder(dividingBy: 2)) * 180.0) : .degrees(0))
            }
            .padding(.trailing, 4)
        }
    }

    // MARK: - Address Bar
    private var ieAddressBar: some View {
        HStack(spacing: 6) {
            Text("Address")
                .font(.system(size: 11))
                .foregroundColor(Color.gray)
                .padding(.leading, 6)

            HStack(spacing: 4) {
                if viewModel.isSecure {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.2, green: 0.6, blue: 0.2))
                        .frame(width: 14)
                } else {
                    IEIconView(size: 13)
                        .frame(width: 14)
                }

                TextField("", text: $viewModel.addressBarText, onCommit: {
                    viewModel.navigateTo(input: viewModel.addressBarText)
                })
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 11))
                .foregroundColor(.black)
            }
            .padding(3)
            .background(Color.white)
            .overlay(Rectangle().stroke(Color(red: 0.45, green: 0.60, blue: 0.85), lineWidth: 1))

            // Green Go Button
            Button(action: {
                viewModel.navigateTo(input: viewModel.addressBarText)
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .bold))
                    Text("Go")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(Color(red: 0.10, green: 0.45, blue: 0.10))
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.95, green: 0.98, blue: 0.94), Color(red: 0.82, green: 0.92, blue: 0.80)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color(red: 0.45, green: 0.70, blue: 0.45), lineWidth: 1))
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, 6)
        }
        .frame(height: 28)
        .background(Color(red: 0.95, green: 0.95, blue: 0.94))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(red: 0.82, green: 0.80, blue: 0.78)), alignment: .bottom)
    }

    // MARK: - Status Bar
    private var ieStatusBar: some View {
        HStack(spacing: 2) {
            // Status text
            Text(viewModel.isLoading ? "Opening page \(viewModel.currentURLString)..." : "Done")
                .font(.system(size: 11))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 6)

            // Padlock
            if viewModel.isSecure {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color.gray)
                    .frame(width: 20)
            }

            // Zone indicator
            HStack(spacing: 4) {
                Image(systemName: "globe")
                    .font(.system(size: 10))
                    .foregroundColor(.blue)
                Text("Internet")
                    .font(.system(size: 10))
                    .foregroundColor(.black)
            }
            .frame(width: 100, alignment: .leading)
            .padding(.horizontal, 4)
        }
        .frame(height: 22)
        .background(
            LinearGradient(
                colors: [Color(red: 0.93, green: 0.92, blue: 0.90), Color(red: 0.88, green: 0.87, blue: 0.84)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var toolbarDivider: some View {
        Rectangle()
            .frame(width: 1, height: 24)
            .foregroundColor(Color.gray.opacity(0.35))
            .padding(.horizontal, 4)
    }
}
