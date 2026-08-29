import SwiftUI
#if os(macOS)
import AppKit
#endif

public enum RunCommandResult: Equatable {
    case openApp(XPAppType)
    case openURL(URL)
    case openPath(String)
    case notFound(String)
}

public class RunDialogEngine: ObservableObject {
    @Published public var history: [String]
    @Published public var errorMessage: String? = nil
    
    public init(history: [String] = ["notepad", "cmd", "calc", "paint", "winmine", "control", "explorer"]) {
        self.history = history
    }
    
    public func addToHistory(_ cmd: String) {
        let trimmed = cmd.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        history.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        history.insert(trimmed, at: 0)
    }
    
    public func resolveCommand(_ rawCommand: String) -> RunCommandResult {
        let trimmed = rawCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .notFound("") }
        
        let lower = trimmed.lowercased()
        
        switch lower {
        case "notepad", "notepad.exe":
            return .openApp(.notepad(fileURL: nil))
        case "cmd", "cmd.exe", "command":
            return .openApp(.cmd)
        case "calc", "calc.exe", "calculator":
            return .openApp(.calculator)
        case "paint", "mspaint", "mspaint.exe", "pbrush":
            return .openApp(.paint)
        case "winmine", "winmine.exe", "minesweeper":
            return .openApp(.minesweeper)
        case "control", "control panel", "control.exe":
            return .openApp(.controlPanel)
        case "sysdm.cpl", "sysproperties", "system":
            return .openApp(.systemProperties)
        case "desk.cpl", "display", "screensaver":
            return .openApp(.displayProperties)
        case "explorer", "explorer.exe":
            return .openApp(.explorer(path: "/"))
        default:
            break
        }
        
        // URL detection
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") {
            if let url = URL(string: trimmed) {
                return .openURL(url)
            }
        } else if lower.hasPrefix("www.") {
            if let url = URL(string: "https://\(trimmed)") {
                return .openURL(url)
            }
        }
        
        // Path detection
        if trimmed.hasPrefix("/") || trimmed.hasPrefix("~") || trimmed.hasPrefix("C:\\") || trimmed.hasPrefix("c:\\") {
            var path = trimmed
            if path.hasPrefix("~") {
                path = (NSHomeDirectory() as NSString).appendingPathComponent(String(path.dropFirst(2)))
            } else if path.hasPrefix("C:\\") || path.hasPrefix("c:\\") {
                path = "/" + String(path.dropFirst(3)).replacingOccurrences(of: "\\", with: "/")
            }
            if FileManager.default.fileExists(atPath: path) {
                return .openPath(path)
            }
        }
        
        return .notFound(trimmed)
    }
}

public struct RunDialogView: View {
    @ObservedObject public var windowManager: WindowManager
    public var window: XPWindowInstance
    
    @StateObject private var engine = RunDialogEngine()
    @State private var inputText: String = "notepad"
    @State private var showErrorAlert: Bool = false
    @FocusState private var isInputFocused: Bool
    
    public init(windowManager: WindowManager, window: XPWindowInstance) {
        self.windowManager = windowManager
        self.window = window
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 12) {
                // Top Prompt Header
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(Color(red: 0.15, green: 0.45, blue: 0.85))
                    
                    Text("Type the name of a program, folder, document, or Internet resource, and Windows will open it for you.")
                        .font(.system(size: 11))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                
                // Open Input Row
                HStack(spacing: 8) {
                    Text("Open:")
                        .font(.system(size: 11))
                        .foregroundColor(.black)
                        .frame(width: 40, alignment: .leading)
                    
                    TextField("", text: $inputText)
                        .font(.system(size: 12))
                        .textFieldStyle(.plain)
                        .padding(4)
                        .background(Color.white)
                        .overlay(Rectangle().strokeBorder(Color.gray, lineWidth: 1))
                        .focused($isInputFocused)
                        .onSubmit {
                            handleRun()
                        }
                }
                .padding(.horizontal, 12)
                
                Spacer()
                
                // Bottom Buttons
                HStack(spacing: 8) {
                    Spacer()
                    
                    dialogButton(title: "OK") {
                        handleRun()
                    }
                    
                    dialogButton(title: "Cancel") {
                        windowManager.closeWindow(id: window.id)
                    }
                    
                    dialogButton(title: "Browse...") {
                        handleBrowse()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .background(Color(red: 0.94, green: 0.94, blue: 0.94))
            
            // Error Dialog Alert
            if showErrorAlert {
                errorAlertModal
            }
        }
        .onAppear {
            isInputFocused = true
        }
    }
    
    private func handleRun() {
        let result = engine.resolveCommand(inputText)
        switch result {
        case .openApp(let appType):
            engine.addToHistory(inputText)
            windowManager.closeWindow(id: window.id)
            windowManager.openWindow(appType: appType)
            
        case .openURL(let url):
            engine.addToHistory(inputText)
            windowManager.closeWindow(id: window.id)
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #endif
            
        case .openPath(let path):
            engine.addToHistory(inputText)
            windowManager.closeWindow(id: window.id)
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue {
                windowManager.openWindow(appType: .explorer(path: path))
            } else {
                #if os(macOS)
                NSWorkspace.shared.open(URL(fileURLWithPath: path))
                #endif
            }
            
        case .notFound:
            SoundManager.shared.play(.error)
            showErrorAlert = true
        }
    }
    
    private func handleBrowse() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            inputText = url.path
        }
        #endif
    }
    
    private var errorAlertModal: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "xmark.octagon.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Windows cannot find '\(inputText)'.")
                            .font(.system(size: 11, weight: .bold))
                        Text("Make sure you typed the name correctly, and then try again.")
                            .font(.system(size: 11))
                    }
                }
                
                Button(action: {
                    showErrorAlert = false
                    isInputFocused = true
                }) {
                    Text("OK")
                        .font(.system(size: 11))
                        .frame(width: 70, height: 22)
                        .background(Color(red: 0.94, green: 0.94, blue: 0.94))
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .strokeBorder(Color(red: 0.0, green: 0.2, blue: 0.6), lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(14)
            .frame(width: 320)
            .background(Color(red: 0.96, green: 0.96, blue: 0.96))
            .border(Color(red: 0.0, green: 0.33, blue: 0.92), width: 2)
            .shadow(radius: 8)
        }
    }
    
    private func dialogButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.black)
                .frame(width: 70, height: 22)
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
    }
}
