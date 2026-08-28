import Foundation

public enum HistoryDirection {
    case previous
    case next
}

public enum TerminalLineType: Equatable {
    case banner
    case prompt
    case output
    case error
}

public struct TerminalLine: Identifiable, Equatable {
    public let id: UUID
    public var text: String
    public var type: TerminalLineType
    
    public init(id: UUID = UUID(), text: String, type: TerminalLineType) {
        self.id = id
        self.text = text
        self.type = type
    }
}

public class ShellService: ObservableObject {
    @Published public var currentUnixDirectory: String
    @Published public var commandHistory: [String] = []
    @Published public var historyIndex: Int = -1
    @Published public var terminalLines: [TerminalLine] = []
    
    public var onExit: (() -> Void)?
    
    public init(initialDirectory: String? = nil) {
        let initialDir = initialDirectory ?? NSHomeDirectory()
        self.currentUnixDirectory = initialDir
    }
    
    public var dosPrompt: String {
        let dosPath = convertToDosPath(unixPath: currentUnixDirectory)
        return "\(dosPath)>"
    }
    
    public func convertToDosPath(unixPath: String) -> String {
        var clean = unixPath
        if clean.isEmpty { clean = "/" }
        
        let home = NSHomeDirectory()
        if clean == home {
            let user = NSUserName()
            return "C:\\Documents and Settings\\\(user)"
        }
        
        if clean.hasPrefix(home) {
            let user = NSUserName()
            let sub = String(clean.dropFirst(home.count))
            let dosSub = sub.replacingOccurrences(of: "/", with: "\\")
            return "C:\\Documents and Settings\\\(user)\(dosSub)"
        }
        
        if clean == "/" {
            return "C:\\"
        }
        
        let dos = clean.replacingOccurrences(of: "/", with: "\\")
        return "C:\(dos)"
    }
    
    public func convertToUnixPath(dosPath: String) -> String {
        var clean = dosPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("C:") || clean.hasPrefix("c:") {
            clean = String(clean.dropFirst(2))
        }
        
        clean = clean.replacingOccurrences(of: "\\", with: "/")
        if clean.isEmpty {
            return "/"
        }
        
        let user = NSUserName()
        let home = NSHomeDirectory()
        let docSettingsPrefix = "/Documents and Settings/\(user)"
        if clean == docSettingsPrefix {
            return home
        }
        if clean.hasPrefix(docSettingsPrefix + "/") {
            let sub = String(clean.dropFirst(docSettingsPrefix.count))
            return (home as NSString).appendingPathComponent(sub)
        }
        
        return clean
    }
    
    public func recordCommand(_ cmd: String) {
        let trimmed = cmd.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        commandHistory.append(trimmed)
        historyIndex = commandHistory.count
    }
    
    public func navigateHistory(direction: HistoryDirection) -> String? {
        guard !commandHistory.isEmpty else { return nil }
        
        switch direction {
        case .previous:
            if historyIndex > 0 {
                historyIndex -= 1
                return commandHistory[historyIndex]
            } else if historyIndex == 0 {
                return commandHistory[0]
            }
        case .next:
            if historyIndex < commandHistory.count - 1 {
                historyIndex += 1
                return commandHistory[historyIndex]
            } else {
                historyIndex = commandHistory.count
                return ""
            }
        }
        return nil
    }
    
    public func executeDosCommand(_ rawCommand: String) -> String? {
        let trimmed = rawCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        
        let parts = trimmed.split(separator: " ", maxSplits: 1).map(String.init)
        let command = parts[0].lowercased()
        let argument = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespacesAndNewlines) : ""
        
        switch command {
        case "ver":
            return "Microsoft Windows XP [Version 5.1.2600]\n(C) Copyright 1985-2001 Microsoft Corp."
            
        case "echo":
            if argument.isEmpty {
                return "ECHO is on."
            }
            return argument
            
        case "cls":
            return "__CLS__"
            
        case "exit":
            onExit?()
            return ""
            
        case "help":
            return """
            For more information on a specific command, type HELP command-name
            CD             Displays the name of or changes the current directory.
            CLS            Clears the screen.
            DIR            Displays a list of files and subdirectories in a directory.
            ECHO           Displays messages, or turns command echoing on or off.
            EXIT           Quits the CMD.EXE program (command interpreter).
            HELP           Provides Help information for Windows commands.
            TYPE           Displays the contents of a text file.
            VER            Displays the Windows version.
            """
            
        case "cd", "chdir":
            if argument.isEmpty {
                return convertToDosPath(unixPath: currentUnixDirectory)
            }
            return changeDirectory(argument)
            
        case "dir":
            return listDirectory(argument)
            
        case "type":
            if argument.isEmpty {
                return "The syntax of the command is incorrect."
            }
            return typeFile(argument)
            
        default:
            return nil
        }
    }
    
    private func changeDirectory(_ target: String) -> String {
        var path = target
        if path == "~" {
            path = NSHomeDirectory()
        } else if path == "\\" || path == "/" {
            path = "/"
        } else if path.hasPrefix("C:\\") || path.hasPrefix("c:\\") || path.hasPrefix("C:/") || path.hasPrefix("c:/") {
            path = convertToUnixPath(dosPath: path)
        } else if !path.hasPrefix("/") {
            path = (currentUnixDirectory as NSString).appendingPathComponent(path)
        }
        
        path = (path as NSString).standardizingPath
        
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue {
            currentUnixDirectory = path
            return ""
        } else {
            return "The system cannot find the path specified."
        }
    }
    
    private func listDirectory(_ target: String) -> String {
        var dirPath = currentUnixDirectory
        if !target.isEmpty && !target.hasPrefix("/") && !target.hasPrefix("-") {
            if target.hasPrefix("C:\\") || target.hasPrefix("c:\\") {
                dirPath = convertToUnixPath(dosPath: target)
            } else {
                dirPath = (currentUnixDirectory as NSString).appendingPathComponent(target)
            }
            dirPath = (dirPath as NSString).standardizingPath
        }
        
        guard let items = try? FileManager.default.contentsOfDirectory(atPath: dirPath) else {
            return "File Not Found"
        }
        
        let dosPath = convertToDosPath(unixPath: dirPath)
        var lines: [String] = []
        lines.append(" Volume in drive C has no label.")
        lines.append(" Volume Serial Number is 1337-BEEF")
        lines.append("")
        lines.append(" Directory of \(dosPath)")
        lines.append("")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy  hh:mm a"
        
        var fileCount = 0
        var dirCount = 2 // . and ..
        var totalBytes: Int64 = 0
        
        let nowStr = dateFormatter.string(from: Date())
        lines.append("\(nowStr)    <DIR>          .")
        lines.append("\(nowStr)    <DIR>          ..")
        
        let sorted = items.sorted()
        for item in sorted {
            let fullPath = (dirPath as NSString).appendingPathComponent(item)
            let attrs = try? FileManager.default.attributesOfItem(atPath: fullPath)
            let modDate = attrs?[.modificationDate] as? Date ?? Date()
            let dateStr = dateFormatter.string(from: modDate)
            let isDirectory = (attrs?[.type] as? FileAttributeType) == .typeDirectory
            
            if isDirectory {
                dirCount += 1
                lines.append("\(dateStr)    <DIR>          \(item)")
            } else {
                fileCount += 1
                let size = (attrs?[.size] as? NSNumber)?.int64Value ?? 0
                totalBytes += size
                let formattedSize = NumberFormatter.localizedString(from: NSNumber(value: size), number: .decimal)
                let paddedSize = formattedSize.leftPadding(toLength: 14)
                lines.append("\(dateStr)    \(paddedSize) \(item)")
            }
        }
        
        let totalFilesStr = NumberFormatter.localizedString(from: NSNumber(value: fileCount), number: .decimal)
        let totalBytesStr = NumberFormatter.localizedString(from: NSNumber(value: totalBytes), number: .decimal)
        let totalDirsStr = NumberFormatter.localizedString(from: NSNumber(value: dirCount), number: .decimal)
        
        let freeBytes: Int64 = {
            if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: dirPath),
               let free = attrs[.systemFreeSize] as? NSNumber {
                return free.int64Value
            }
            return 120_000_000_000
        }()
        let freeBytesStr = NumberFormatter.localizedString(from: NSNumber(value: freeBytes), number: .decimal)
        
        lines.append("              \(totalFilesStr.leftPadding(toLength: 4)) File(s) \(totalBytesStr.leftPadding(toLength: 14)) bytes")
        lines.append("              \(totalDirsStr.leftPadding(toLength: 4)) Dir(s)  \(freeBytesStr.leftPadding(toLength: 14)) bytes free")
        
        return lines.joined(separator: "\n")
    }
    
    private func typeFile(_ target: String) -> String {
        var filePath = target
        if !filePath.hasPrefix("/") {
            filePath = (currentUnixDirectory as NSString).appendingPathComponent(filePath)
        }
        filePath = (filePath as NSString).standardizingPath
        
        guard let data = FileManager.default.contents(atPath: filePath),
              let content = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            return "The system cannot find the file specified."
        }
        return content
    }
    
    public func executeCommand(_ rawInput: String, completion: @escaping (String, Bool) -> Void) {
        let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion("", false)
            return
        }
        
        recordCommand(trimmed)
        
        if let dosResult = executeDosCommand(trimmed) {
            completion(dosResult, false)
            return
        }
        
        // Execute in macOS zsh sub-process
        DispatchQueue.global(qos: .userInitiated).async { [currentUnixDirectory] in
            let process = Process()
            let zshPath = FileManager.default.fileExists(atPath: "/bin/zsh") ? "/bin/zsh" : "/bin/sh"
            process.executableURL = URL(fileURLWithPath: zshPath)
            process.arguments = ["-c", trimmed]
            process.currentDirectoryURL = URL(fileURLWithPath: currentUnixDirectory)
            
            let pipeOut = Pipe()
            let pipeErr = Pipe()
            process.standardOutput = pipeOut
            process.standardError = pipeErr
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let dataOut = pipeOut.fileHandleForReading.readDataToEndOfFile()
                let dataErr = pipeErr.fileHandleForReading.readDataToEndOfFile()
                
                let outStr = String(data: dataOut, encoding: .utf8) ?? ""
                let errStr = String(data: dataErr, encoding: .utf8) ?? ""
                
                let combined = !errStr.isEmpty ? (outStr.isEmpty ? errStr : "\(outStr)\n\(errStr)") : outStr
                let isError = process.terminationStatus != 0
                
                DispatchQueue.main.async {
                    completion(combined.trimmingCharacters(in: .whitespacesAndNewlines), isError)
                }
            } catch {
                DispatchQueue.main.async {
                    completion("Command execution failed: \(error.localizedDescription)", true)
                }
            }
        }
    }
}

private extension String {
    func leftPadding(toLength: Int, withPad pad: String = " ") -> String {
        guard count < toLength else { return self }
        return String(repeating: pad, count: toLength - count) + self
    }
}
