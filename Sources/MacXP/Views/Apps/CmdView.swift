import SwiftUI

public struct CmdView: View {
    @ObservedObject public var windowManager: WindowManager
    public var window: XPWindowInstance
    
    @StateObject private var shellService = ShellService()
    @State private var currentInput: String = ""
    @State private var isExecuting: Bool = false
    @FocusState private var isInputFocused: Bool
    
    public init(windowManager: WindowManager, window: XPWindowInstance) {
        self.windowManager = windowManager
        self.window = window
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        // Banner
                        Text("Microsoft Windows XP [Version 5.1.2600]\n(C) Copyright 1985-2001 Microsoft Corp.\n")
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.85))
                        
                        // Output lines
                        ForEach(shellService.terminalLines) { line in
                            Text(line.text)
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundColor(colorForLineType(line.type))
                                .textSelection(.enabled)
                        }
                        
                        // Active prompt line
                        HStack(spacing: 0) {
                            Text(shellService.dosPrompt + " ")
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundColor(Color(red: 0.85, green: 0.85, blue: 0.85))
                            
                            TextField("", text: $currentInput)
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundColor(Color(red: 0.95, green: 0.95, blue: 0.95))
                                .textFieldStyle(.plain)
                                .focused($isInputFocused)
                                .onSubmit {
                                    submitCommand()
                                }
                                #if os(macOS)
                                .onExitCommand {
                                    currentInput = ""
                                }
                                #endif
                        }
                        .id("bottom-anchor")
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.black)
                .onTapGesture {
                    isInputFocused = true
                }
                .onChange(of: shellService.terminalLines.count) { _ in
                    proxy.scrollTo("bottom-anchor", anchor: .bottom)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
            isInputFocused = true
            shellService.onExit = {
                windowManager.closeWindow(id: window.id)
            }
        }
    }
    
    private func colorForLineType(_ type: TerminalLineType) -> Color {
        switch type {
        case .banner:
            return Color(red: 0.85, green: 0.85, blue: 0.85)
        case .prompt:
            return Color(red: 0.90, green: 0.90, blue: 0.90)
        case .output:
            return Color(red: 0.80, green: 0.80, blue: 0.80)
        case .error:
            return Color(red: 1.0, green: 0.4, blue: 0.4)
        }
    }
    
    private func submitCommand() {
        let input = currentInput
        currentInput = ""
        
        let promptText = shellService.dosPrompt + " " + input
        shellService.terminalLines.append(TerminalLine(text: promptText, type: .prompt))
        
        guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isExecuting = true
        shellService.executeCommand(input) { output, isError in
            isExecuting = false
            if output == "__CLS__" {
                shellService.terminalLines.removeAll()
            } else if !output.isEmpty {
                shellService.terminalLines.append(TerminalLine(text: output, type: isError ? .error : .output))
            }
        }
    }
}
